-- Auto-end sessions whose max duration has been exceeded
-- This handles cases where the host's app crashes and the session is never properly ended

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

-- Redefine get_discoverable_sessions to call auto_end_expired_sessions first,
-- preserving the existing p_user_id parameter signature that the client expects.
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
