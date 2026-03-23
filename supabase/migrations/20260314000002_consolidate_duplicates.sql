-- =============================================================================
-- Consolidate duplicate function definitions
-- =============================================================================
-- This migration supersedes duplicate function definitions that appeared in:
--   - add_match_sessions.sql (get_discoverable_sessions v1)
--   - fix_discoverable_sessions_rpc.sql (get_discoverable_sessions v2)
--   - auto_end_expired_sessions.sql (auto_end_expired_sessions + get_discoverable_sessions v3)
--   - 20260311000003_consolidate_session_rpcs.sql (canonical session RPCs)
--   - add_session_video_slots.sql (non-timestamped duplicate)
--   - 20260313000001_add_session_video_slots.sql (canonical video slot RPCs)
--
-- All functions below use CREATE OR REPLACE to ensure a single canonical version.
-- =============================================================================

-- 1. auto_end_expired_sessions (from 20260311000003_consolidate_session_rpcs.sql)
CREATE OR REPLACE FUNCTION auto_end_expired_sessions()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE sessions
    SET status = 'ended',
        ended_at = NOW()
    WHERE status = 'live'
      AND started_at IS NOT NULL
      AND started_at + (max_duration_minutes * INTERVAL '1 minute') < NOW();
END;
$$;

-- 2. get_discoverable_sessions (from 20260311000003_consolidate_session_rpcs.sql)
CREATE OR REPLACE FUNCTION get_discoverable_sessions(p_user_id UUID)
RETURNS SETOF sessions AS $$
BEGIN
    -- Clean up expired sessions before returning results
    PERFORM auto_end_expired_sessions();

    RETURN QUERY
    SELECT DISTINCT s.*
    FROM sessions s
    WHERE s.status IN ('scheduled', 'live')
    AND (
        -- User is the host
        s.host_id = p_user_id
        -- User has a direct mutual match with the host
        OR EXISTS (
            SELECT 1 FROM matches m
            WHERE m.is_mutual = true
            AND (
                (m.user1_id = p_user_id AND m.user2_id = s.host_id)
                OR (m.user1_id = s.host_id AND m.user2_id = p_user_id)
            )
        )
        -- Session is open and user shares the language pair
        OR (
            s.is_open = true
            AND EXISTS (
                SELECT 1 FROM profiles p
                WHERE p.id = p_user_id
                AND (
                    p.native_language = s.language_pair->>'native'
                    OR p.native_language = s.language_pair->>'learning'
                    OR s.language_pair->>'native' = ANY(p.learning_languages)
                    OR s.language_pair->>'learning' = ANY(p.learning_languages)
                )
            )
        )
        -- User is already a participant
        OR EXISTS (
            SELECT 1 FROM session_participants sp
            WHERE sp.session_id = s.id
            AND sp.user_id = p_user_id
            AND sp.is_active = true
        )
        -- User has an invite
        OR EXISTS (
            SELECT 1 FROM session_invites si
            WHERE si.session_id = s.id
            AND si.invitee_id = p_user_id
            AND si.status = 'pending'
        )
    )
    ORDER BY
        CASE s.status
            WHEN 'live' THEN 0
            WHEN 'scheduled' THEN 1
        END,
        s.scheduled_at ASC NULLS LAST,
        s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Video slot functions (from 20260313000001_add_session_video_slots.sql)

CREATE OR REPLACE FUNCTION reserve_video_slot(p_session_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_max_viewers INT;
    v_current_count INT;
    v_next_position INT;
    v_existing_status TEXT;
    v_result JSONB;
BEGIN
    SELECT status INTO v_existing_status
    FROM session_video_slots
    WHERE session_id = p_session_id AND user_id = v_user_id;

    IF v_existing_status IS NOT NULL THEN
        RETURN jsonb_build_object('status', v_existing_status, 'position', NULL);
    END IF;

    SELECT COALESCE(max_video_viewers, 5) INTO v_max_viewers
    FROM sessions WHERE id = p_session_id;

    SELECT COUNT(*) INTO v_current_count
    FROM session_video_slots
    WHERE session_id = p_session_id AND status IN ('confirmed', 'active');

    IF v_current_count < v_max_viewers THEN
        INSERT INTO session_video_slots (session_id, user_id, status)
        VALUES (p_session_id, v_user_id, 'confirmed');
        v_result := jsonb_build_object('status', 'confirmed', 'position', NULL);
    ELSE
        SELECT COALESCE(MAX(position), 0) + 1 INTO v_next_position
        FROM session_video_slots
        WHERE session_id = p_session_id AND status = 'waitlisted';

        INSERT INTO session_video_slots (session_id, user_id, status, position)
        VALUES (p_session_id, v_user_id, 'waitlisted', v_next_position);
        v_result := jsonb_build_object('status', 'waitlisted', 'position', v_next_position);
    END IF;

    RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION activate_video_slot(p_session_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    UPDATE session_video_slots
    SET status = 'active', activated_at = NOW(), position = NULL
    WHERE session_id = p_session_id
      AND user_id = v_user_id
      AND status = 'confirmed';
END;
$$;

CREATE OR REPLACE FUNCTION release_video_slot(p_session_id UUID, p_user_id UUID DEFAULT NULL)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_promoted_user_id UUID;
BEGIN
    UPDATE session_video_slots
    SET status = 'expired'
    WHERE session_id = p_session_id
      AND user_id = v_user_id
      AND status IN ('confirmed', 'active');

    SELECT user_id INTO v_promoted_user_id
    FROM session_video_slots
    WHERE session_id = p_session_id
      AND status = 'waitlisted'
    ORDER BY position ASC
    LIMIT 1;

    IF v_promoted_user_id IS NOT NULL THEN
        UPDATE session_video_slots
        SET status = 'active', activated_at = NOW(), position = NULL
        WHERE session_id = p_session_id
          AND user_id = v_promoted_user_id
          AND status = 'waitlisted';
    END IF;

    RETURN v_promoted_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION expire_no_show_slots(p_session_id UUID, p_grace_minutes INT DEFAULT 2)
RETURNS SETOF UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_started_at TIMESTAMPTZ;
    v_expired_slot RECORD;
    v_promoted_user_id UUID;
BEGIN
    SELECT started_at INTO v_session_started_at
    FROM sessions WHERE id = p_session_id AND status = 'live';

    IF v_session_started_at IS NULL THEN
        RETURN;
    END IF;

    FOR v_expired_slot IN
        SELECT id, user_id FROM session_video_slots
        WHERE session_id = p_session_id
          AND status = 'confirmed'
          AND reserved_at < (v_session_started_at + (p_grace_minutes || ' minutes')::interval)
          AND activated_at IS NULL
    LOOP
        UPDATE session_video_slots
        SET status = 'expired'
        WHERE id = v_expired_slot.id;

        SELECT user_id INTO v_promoted_user_id
        FROM session_video_slots
        WHERE session_id = p_session_id
          AND status = 'waitlisted'
        ORDER BY position ASC
        LIMIT 1;

        IF v_promoted_user_id IS NOT NULL THEN
            UPDATE session_video_slots
            SET status = 'active', activated_at = NOW(), position = NULL
            WHERE session_id = p_session_id
              AND user_id = v_promoted_user_id
              AND status = 'waitlisted';

            RETURN NEXT v_promoted_user_id;
        END IF;
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION get_video_slot_status(p_session_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_total_active INT;
    v_max_slots INT;
    v_my_status TEXT;
    v_my_position INT;
BEGIN
    SELECT COALESCE(max_video_viewers, 5) INTO v_max_slots
    FROM sessions WHERE id = p_session_id;

    SELECT COUNT(*) INTO v_total_active
    FROM session_video_slots
    WHERE session_id = p_session_id AND status IN ('confirmed', 'active');

    SELECT status, position INTO v_my_status, v_my_position
    FROM session_video_slots
    WHERE session_id = p_session_id AND user_id = v_user_id;

    RETURN jsonb_build_object(
        'total_active', v_total_active,
        'max_slots', v_max_slots,
        'my_status', v_my_status,
        'my_position', v_my_position
    );
END;
$$;
