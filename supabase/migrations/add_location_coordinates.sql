-- Add location coordinate columns to profiles table
-- These enable distance-based matching between users

-- Add city column (extracted from full location for display)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS city TEXT;

-- Add country column (extracted from full location for filtering)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS country TEXT;

-- Add latitude column (for distance calculations)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;

-- Add longitude column (for distance calculations)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Create index on coordinates for efficient distance queries
CREATE INDEX IF NOT EXISTS idx_profiles_coordinates ON profiles (latitude, longitude)
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Create index on country for country-based filtering
CREATE INDEX IF NOT EXISTS idx_profiles_country ON profiles (country)
WHERE country IS NOT NULL;

-- Function to calculate distance between two points (in kilometers)
-- Uses Haversine formula
CREATE OR REPLACE FUNCTION calculate_distance_km(
    lat1 DOUBLE PRECISION,
    lon1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION,
    lon2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
DECLARE
    R CONSTANT DOUBLE PRECISION := 6371; -- Earth's radius in km
    dlat DOUBLE PRECISION;
    dlon DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    -- Convert degrees to radians
    dlat := radians(lat2 - lat1);
    dlon := radians(lon2 - lon1);
    lat1 := radians(lat1);
    lat2 := radians(lat2);

    -- Haversine formula
    a := sin(dlat/2) * sin(dlat/2) + cos(lat1) * cos(lat2) * sin(dlon/2) * sin(dlon/2);
    c := 2 * asin(sqrt(a));

    RETURN R * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to find users within a certain distance
CREATE OR REPLACE FUNCTION find_users_within_distance(
    user_lat DOUBLE PRECISION,
    user_lon DOUBLE PRECISION,
    max_distance_km DOUBLE PRECISION
) RETURNS TABLE(
    profile_id UUID,
    distance_km DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        calculate_distance_km(user_lat, user_lon, p.latitude, p.longitude) as dist
    FROM profiles p
    WHERE p.latitude IS NOT NULL
      AND p.longitude IS NOT NULL
      AND calculate_distance_km(user_lat, user_lon, p.latitude, p.longitude) <= max_distance_km
    ORDER BY dist;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON COLUMN profiles.latitude IS 'GPS latitude for distance-based matching';
COMMENT ON COLUMN profiles.longitude IS 'GPS longitude for distance-based matching';
COMMENT ON COLUMN profiles.city IS 'City name extracted from location (e.g., Toronto)';
COMMENT ON COLUMN profiles.country IS 'Country name extracted from location (e.g., Canada)';
