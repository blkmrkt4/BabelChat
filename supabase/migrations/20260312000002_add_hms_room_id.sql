-- Add hms_room_id column to store the 100ms room identifier
-- The room_id is returned when creating a room via the 100ms Management API
-- and is required for minting auth tokens.

ALTER TABLE sessions ADD COLUMN IF NOT EXISTS hms_room_id TEXT;
