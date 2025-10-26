-- Add matching preference columns to profiles table
-- Run this in your Supabase SQL Editor

-- Gender and gender preference
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gender_preference TEXT DEFAULT 'all';

-- Age preferences
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS min_age INT DEFAULT 18;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS max_age INT DEFAULT 99;

-- Location preferences
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location_preference TEXT DEFAULT 'anywhere';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS latitude FLOAT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS longitude FLOAT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS preferred_countries TEXT[];

-- Relationship and learning preferences
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS relationship_intents TEXT[];
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS learning_contexts TEXT[];

-- Travel and regional preferences
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS travel_destination JSONB;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS regional_language_preferences JSONB[];

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_profiles_gender ON profiles(gender);
CREATE INDEX IF NOT EXISTS idx_profiles_location ON profiles(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_profiles_age ON profiles(birth_year);

-- Add comments for documentation
COMMENT ON COLUMN profiles.gender IS 'User gender: male, female, non_binary';
COMMENT ON COLUMN profiles.gender_preference IS 'Preferred gender to match with: male, female, non_binary, all';
COMMENT ON COLUMN profiles.min_age IS 'Minimum age for potential matches';
COMMENT ON COLUMN profiles.max_age IS 'Maximum age for potential matches';
COMMENT ON COLUMN profiles.location_preference IS 'Location filter: local_25km, regional_100km, anywhere';
COMMENT ON COLUMN profiles.relationship_intents IS 'Array: friendship, language_practice_only, open_to_dating';
COMMENT ON COLUMN profiles.learning_contexts IS 'Array: work, travel, academic, fun, cultural';
COMMENT ON COLUMN profiles.travel_destination IS 'JSON with country and months_planning fields';
COMMENT ON COLUMN profiles.regional_language_preferences IS 'Array of JSON with language and regional_variant fields';
