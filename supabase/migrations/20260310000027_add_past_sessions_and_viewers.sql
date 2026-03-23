-- Migration: Add viewer count column and RPC functions for sessions
-- Also update session_messages RLS to allow reading chat history from ended sessions

-- 1. Add viewer_count column to sessions
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS viewer_count INTEGER DEFAULT 0;

-- 2. Increment viewer count RPC
CREATE OR REPLACE FUNCTION increment_viewer_count(p_session_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE sessions
    SET viewer_count = viewer_count + 1
    WHERE id = p_session_id;
END;
$$;

-- 3. Decrement viewer count RPC (floor at 0)
CREATE OR REPLACE FUNCTION decrement_viewer_count(p_session_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE sessions
    SET viewer_count = GREATEST(viewer_count - 1, 0)
    WHERE id = p_session_id;
END;
$$;

-- 4. Update session_messages SELECT RLS policy to allow reading chat history
--    from ended sessions (for past sessions feature)
--    Drop the old policy and create a new one that doesn't require is_active
DROP POLICY IF EXISTS "Users can read messages in sessions they participate in" ON session_messages;

CREATE POLICY "Users can read messages in sessions they participate in"
ON session_messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM session_participants
        WHERE session_participants.session_id = session_messages.session_id
        AND session_participants.user_id = auth.uid()
    )
);
