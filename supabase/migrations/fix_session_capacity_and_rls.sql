-- Fix session capacity enforcement and co-speaker RLS
-- Addresses audit items #5 (max participants) and #8 (co-host promote RLS)

-- #5: Enforce max 4 active participants per session via trigger
CREATE OR REPLACE FUNCTION enforce_session_capacity()
RETURNS TRIGGER AS $$
DECLARE
    active_count INTEGER;
BEGIN
    -- Only check on INSERT or when re-activating a participant
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.is_active = true AND OLD.is_active = false) THEN
        SELECT COUNT(*) INTO active_count
        FROM session_participants
        WHERE session_id = NEW.session_id
        AND is_active = true;

        IF active_count >= 4 THEN
            RAISE EXCEPTION 'Session is full (max 4 active participants)';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_enforce_session_capacity
    BEFORE INSERT OR UPDATE ON session_participants
    FOR EACH ROW EXECUTE FUNCTION enforce_session_capacity();

-- #8: Update RLS policy so co-speakers can also promote/demote participants
-- Drop the existing policy and recreate with co-speaker support
DROP POLICY IF EXISTS "Users can update own participation or host can update" ON session_participants;

CREATE POLICY "Users can update own participation, host or co-speaker can update"
    ON session_participants FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = user_id
        OR auth.uid() IN (SELECT host_id FROM sessions WHERE id = session_id)
        OR auth.uid() IN (
            SELECT sp.user_id FROM session_participants sp
            WHERE sp.session_id = session_participants.session_id
            AND sp.role = 'co_speaker'
            AND sp.is_active = true
        )
    );

-- Also add a goal column that was referenced in code but may be missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sessions' AND column_name = 'goal'
    ) THEN
        ALTER TABLE sessions ADD COLUMN goal TEXT;
    END IF;
END $$;
