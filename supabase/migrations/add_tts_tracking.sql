-- Migration: Add TTS usage tracking columns to profiles
-- Run this in Supabase SQL Editor

-- Add TTS tracking columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS tts_plays_used_this_month INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS tts_billing_cycle_start TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add subscription_tier column if not exists (should already be there, but just in case)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS subscription_tier VARCHAR(20) DEFAULT 'free';

-- Create index for faster TTS usage queries
CREATE INDEX IF NOT EXISTS idx_profiles_tts_billing_cycle ON profiles(tts_billing_cycle_start);

-- Create an RPC function for atomic increment of TTS usage
CREATE OR REPLACE FUNCTION increment_tts_usage(user_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE profiles
    SET tts_plays_used_this_month = COALESCE(tts_plays_used_this_month, 0) + 1
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION increment_tts_usage(UUID) TO authenticated;

-- Add comment explaining the columns
COMMENT ON COLUMN profiles.tts_plays_used_this_month IS 'Number of TTS plays used in current billing cycle';
COMMENT ON COLUMN profiles.tts_billing_cycle_start IS 'Start date of current TTS billing cycle';
COMMENT ON COLUMN profiles.subscription_tier IS 'User subscription tier: free, premium, or pro';
