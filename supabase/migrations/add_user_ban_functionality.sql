-- Migration: Add user ban functionality
-- Run this in Supabase SQL Editor

-- 1. Add is_banned column to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false;

-- 2. Add ban metadata columns
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ;

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS ban_reason TEXT;

-- 3. Create index for efficient banned user queries
CREATE INDEX IF NOT EXISTS idx_profiles_is_banned ON profiles(is_banned) WHERE is_banned = true;

-- 4. Create a function to check if a user is banned (for use in RLS policies)
CREATE OR REPLACE FUNCTION is_user_banned(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = user_id AND is_banned = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create a view for banned users (useful for admin queries)
CREATE OR REPLACE VIEW banned_users AS
SELECT
  p.id,
  p.first_name,
  p.last_name,
  p.email,
  p.is_banned,
  p.banned_at,
  p.ban_reason,
  p.created_at
FROM profiles p
WHERE p.is_banned = true
ORDER BY p.banned_at DESC;

-- 6. Grant access to the view
GRANT SELECT ON banned_users TO authenticated;
GRANT SELECT ON banned_users TO service_role;

-- 7. Create admin audit log table for tracking ban actions
CREATE TABLE IF NOT EXISTS admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID,
  action TEXT NOT NULL,
  target_user_id UUID REFERENCES profiles(id),
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. Create index on audit log
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_target ON admin_audit_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_action ON admin_audit_log(action);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created ON admin_audit_log(created_at DESC);

-- 9. Grant access to audit log
GRANT SELECT, INSERT ON admin_audit_log TO service_role;

-- 10. Add comment for documentation
COMMENT ON COLUMN profiles.is_banned IS 'Whether the user is banned from the platform';
COMMENT ON COLUMN profiles.banned_at IS 'When the user was banned';
COMMENT ON COLUMN profiles.ban_reason IS 'Reason for the ban (admin notes)';
COMMENT ON TABLE admin_audit_log IS 'Audit trail for admin actions like banning users';
