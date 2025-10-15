-- Add matching preference fields to profiles table

-- First, create an enum for proficiency levels if it doesn't exist
DO $$ BEGIN
    CREATE TYPE proficiency_level AS ENUM ('beginner', 'intermediate', 'advanced');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Add columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS allow_non_native_matches BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS min_proficiency_level proficiency_level DEFAULT 'beginner',
ADD COLUMN IF NOT EXISTS max_proficiency_level proficiency_level DEFAULT 'advanced';

-- Add comments to document the columns
COMMENT ON COLUMN profiles.allow_non_native_matches IS 'Whether user is willing to match with non-native speakers of their learning language';
COMMENT ON COLUMN profiles.min_proficiency_level IS 'Minimum proficiency level required for non-native speaker matches';
COMMENT ON COLUMN profiles.max_proficiency_level IS 'Maximum proficiency level accepted for non-native speaker matches';

-- Update existing rows to have default values
UPDATE profiles
SET
    allow_non_native_matches = false,
    min_proficiency_level = 'beginner',
    max_proficiency_level = 'advanced'
WHERE
    allow_non_native_matches IS NULL
    OR min_proficiency_level IS NULL
    OR max_proficiency_level IS NULL;

-- Add a check constraint to ensure min_proficiency <= max_proficiency
-- Using ordinal values: beginner=1, intermediate=2, advanced=3
ALTER TABLE profiles
ADD CONSTRAINT valid_proficiency_range CHECK (
    CASE min_proficiency_level
        WHEN 'beginner' THEN 1
        WHEN 'intermediate' THEN 2
        WHEN 'advanced' THEN 3
    END <=
    CASE max_proficiency_level
        WHEN 'beginner' THEN 1
        WHEN 'intermediate' THEN 2
        WHEN 'advanced' THEN 3
    END
);

-- Add validation to prevent native language from being in learning languages
-- This uses a custom check constraint with jsonb operations
ALTER TABLE profiles
ADD CONSTRAINT native_not_in_learning CHECK (
    native_language IS NULL
    OR learning_languages IS NULL
    OR NOT (learning_languages::jsonb ? native_language)
);
