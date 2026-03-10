-- Session Video Slots: manages video viewer slot reservations and waitlist
-- Part of the Session Tiers & Video Slot Queue feature

-- Add max_video_viewers and max_participants columns to sessions
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS max_video_viewers INT DEFAULT 5;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS max_participants INT DEFAULT 4;

-- Video slots table
CREATE TABLE IF NOT EXISTS session_video_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id),
    status TEXT NOT NULL CHECK (status IN ('confirmed', 'waitlisted', 'active', 'expired')),
    position INT,  -- waitlist order (NULL for confirmed/active)
    reserved_at TIMESTAMPTZ DEFAULT NOW(),
    activated_at TIMESTAMPTZ,
    UNIQUE(session_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_video_slots_session ON session_video_slots(session_id);
CREATE INDEX IF NOT EXISTS idx_video_slots_user ON session_video_slots(user_id);
CREATE INDEX IF NOT EXISTS idx_video_slots_status ON session_video_slots(session_id, status);

ALTER TABLE session_video_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_video_slots REPLICA IDENTITY FULL;

-- RLS Policies

-- All authenticated users can see slot status (for UI: "3/5 spots available")
CREATE POLICY "video_slots_select" ON session_video_slots
    FOR SELECT TO authenticated USING (true);

-- Users can reserve their own slot
CREATE POLICY "video_slots_insert" ON session_video_slots
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Users can update their own slot (for activation)
CREATE POLICY "video_slots_update_own" ON session_video_slots
    FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- SECURITY DEFINER functions handle system-level updates (promotion, expiry)

-- ============================================================
-- RPC: reserve_video_slot
-- Called when a premium+ user wants to reserve a video spot
-- ============================================================
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
    -- Check if user already has a slot
    SELECT status INTO v_existing_status
    FROM session_video_slots
    WHERE session_id = p_session_id AND user_id = v_user_id;

    IF v_existing_status IS NOT NULL THEN
        RETURN jsonb_build_object('status', v_existing_status, 'position', NULL);
    END IF;

    -- Get max video viewers for this session
    SELECT COALESCE(max_video_viewers, 5) INTO v_max_viewers
    FROM sessions WHERE id = p_session_id;

    -- Count current confirmed/active slots
    SELECT COUNT(*) INTO v_current_count
    FROM session_video_slots
    WHERE session_id = p_session_id AND status IN ('confirmed', 'active');

    IF v_current_count < v_max_viewers THEN
        -- Slot available: confirm immediately
        INSERT INTO session_video_slots (session_id, user_id, status)
        VALUES (p_session_id, v_user_id, 'confirmed');

        v_result := jsonb_build_object('status', 'confirmed', 'position', NULL);
    ELSE
        -- No slots available: add to waitlist
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

-- ============================================================
-- RPC: activate_video_slot
-- Called when session goes live and user joins
-- ============================================================
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

-- ============================================================
-- RPC: release_video_slot
-- Called when a video viewer leaves mid-session
-- ============================================================
CREATE OR REPLACE FUNCTION release_video_slot(p_session_id UUID, p_user_id UUID DEFAULT NULL)
RETURNS UUID  -- returns promoted user_id or NULL
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_promoted_user_id UUID;
BEGIN
    -- Expire the leaving user's slot
    UPDATE session_video_slots
    SET status = 'expired'
    WHERE session_id = p_session_id
      AND user_id = v_user_id
      AND status IN ('confirmed', 'active');

    -- Promote next waitlisted user
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

-- ============================================================
-- RPC: expire_no_show_slots
-- Called to reclaim slots from confirmed users who didn't join
-- ============================================================
CREATE OR REPLACE FUNCTION expire_no_show_slots(p_session_id UUID, p_grace_minutes INT DEFAULT 2)
RETURNS SETOF UUID  -- returns promoted user_ids
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_started_at TIMESTAMPTZ;
    v_expired_slot RECORD;
    v_promoted_user_id UUID;
BEGIN
    -- Get session start time
    SELECT started_at INTO v_session_started_at
    FROM sessions WHERE id = p_session_id AND status = 'live';

    IF v_session_started_at IS NULL THEN
        RETURN;
    END IF;

    -- Find and expire no-show confirmed slots
    FOR v_expired_slot IN
        SELECT id, user_id FROM session_video_slots
        WHERE session_id = p_session_id
          AND status = 'confirmed'
          AND reserved_at < (v_session_started_at + (p_grace_minutes || ' minutes')::interval)
          AND activated_at IS NULL
    LOOP
        -- Expire the no-show
        UPDATE session_video_slots
        SET status = 'expired'
        WHERE id = v_expired_slot.id;

        -- Promote next waitlisted
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

-- ============================================================
-- RPC: get_video_slot_status
-- Returns slot availability info for a session
-- ============================================================
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
