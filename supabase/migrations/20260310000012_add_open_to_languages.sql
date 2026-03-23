-- Migration: Add open_to_languages column to profiles table
-- This field stores which languages a user is willing to match in

-- Add the column (TEXT array)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS open_to_languages TEXT[];

-- Add comment explaining the field
COMMENT ON COLUMN profiles.open_to_languages IS 'Array of language codes the user is willing to match in (e.g., [''French'', ''English'']). User can choose their native language, learning languages, or any combination.';

-- Create index for faster matching queries
CREATE INDEX IF NOT EXISTS idx_profiles_open_to_languages
ON profiles USING GIN (open_to_languages);

-- Set default for existing users (native language only as conservative default)
UPDATE profiles
SET open_to_languages = ARRAY[native_language]
WHERE open_to_languages IS NULL;

-- Example data:
-- French native learning English might choose: ['French', 'English']
-- Spanish native beginner in English might choose: ['Spanish']
-- Advanced English learner might choose: ['English'] (even if not native)
