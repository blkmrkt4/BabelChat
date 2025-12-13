-- Add per-photo blur settings column
-- This array stores blur state for each photo (indices 0-5 for grid, 6 for profile photo)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS photo_blur_settings BOOLEAN[] DEFAULT '{}';

-- Add comment for documentation
COMMENT ON COLUMN profiles.photo_blur_settings IS 'Array of boolean values indicating which photos should be blurred until match. Index 0-5 for grid photos, index 6 for profile photo.';
