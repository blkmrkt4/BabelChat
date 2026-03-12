-- Rename co_speaker role to co_host across session tables
-- This aligns DB values with the product spec naming convention

BEGIN;

-- Update existing participant roles
UPDATE session_participants SET role = 'co_host' WHERE role = 'co_speaker';

-- Update existing invite roles
UPDATE session_invites SET role = 'co_host' WHERE role = 'co_speaker';

-- Drop and recreate the CHECK constraint on session_participants
ALTER TABLE session_participants DROP CONSTRAINT IF EXISTS session_participants_role_check;
ALTER TABLE session_participants
    ADD CONSTRAINT session_participants_role_check
    CHECK (role IN ('host', 'co_host', 'rotating_speaker', 'listener'));

-- Update default on session_invites if it was co_speaker
ALTER TABLE session_invites ALTER COLUMN role SET DEFAULT 'co_host';

-- Update the RLS policy that references co_speaker
DROP POLICY IF EXISTS "Participants can update own record or host/co-host can update" ON session_participants;
CREATE POLICY "Participants can update own record or host/co-host can update" ON session_participants
    FOR UPDATE USING (
        auth.uid() = user_id
        OR auth.uid() IN (SELECT host_id FROM sessions WHERE id = session_id)
        OR auth.uid() IN (
            SELECT sp.user_id FROM session_participants sp
            WHERE sp.session_id = session_participants.session_id
            AND sp.role = 'co_host'
            AND sp.is_active = true
        )
    );

COMMIT;
