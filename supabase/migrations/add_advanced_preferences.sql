-- Migration: Add advanced matching preference fields
-- Implements concepts #4 (non-native matching) and #5 (proficiency filters)

-- Add non_native_preferences column (JSONB)
-- Structure: { "French": { "allow_non_natives": true }, "English": { "allow_non_natives": false } }
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS non_native_preferences JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN profiles.non_native_preferences IS 'Preferences for matching with non-native speakers. For each language in open_to_languages, specifies if user is willing to match with learners. Example: {"French": {"allow_non_natives": false}, "English": {"allow_non_natives": true}}';

-- Add proficiency_preferences column (JSONB)
-- Structure: { "French": { "minimum_level": "intermediate", "allow_same_level": true }, ... }
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS proficiency_preferences JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN profiles.proficiency_preferences IS 'For languages where allow_non_natives is true, specifies minimum proficiency level acceptable for matching. Example: {"English": {"minimum_level": "intermediate", "allow_same_level": true}}';

-- Create GIN indexes for JSONB fields for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_non_native_prefs
ON profiles USING GIN (non_native_preferences);

CREATE INDEX IF NOT EXISTS idx_profiles_proficiency_prefs
ON profiles USING GIN (proficiency_preferences);

-- Set defaults for existing users
-- Default: Only match with natives (conservative approach)
UPDATE profiles
SET non_native_preferences = (
  SELECT jsonb_object_agg(
    lang,
    jsonb_build_object('allow_non_natives', false)
  )
  FROM unnest(open_to_languages) AS lang
)
WHERE non_native_preferences = '{}'::jsonb
  AND open_to_languages IS NOT NULL
  AND array_length(open_to_languages, 1) > 0;

-- For proficiency_preferences, default is empty since it only applies when allow_non_natives is true
-- Users will need to explicitly set these when they enable non-native matching

COMMENT ON TABLE profiles IS 'User profile data including language preferences and matching settings. Supports 5 core matching concepts: (1) native_language, (2) learning_languages with proficiency_levels, (3) open_to_languages, (4) non_native_preferences, (5) proficiency_preferences.';
