-- Migration: Add strictly_platonic and blur_photos_until_match columns
-- These features differentiate the app from dating apps

-- Add strictly_platonic column
-- When true, user only wants platonic language exchange (no dating)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS strictly_platonic BOOLEAN DEFAULT false;

-- Add blur_photos_until_match column
-- When true, photos are blurred in discovery until users match
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS blur_photos_until_match BOOLEAN DEFAULT false;

-- Add index for efficient filtering by platonic preference
CREATE INDEX IF NOT EXISTS idx_profiles_strictly_platonic
ON profiles(strictly_platonic)
WHERE strictly_platonic = true;

-- Comment on columns for documentation
COMMENT ON COLUMN profiles.strictly_platonic IS 'When true, user only wants platonic language exchange - will only be matched with other platonic users';
COMMENT ON COLUMN profiles.blur_photos_until_match IS 'When true, profile photos are blurred in discovery until users match';
