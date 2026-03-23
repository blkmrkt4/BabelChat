-- Migration: Add user-to-user blocking functions
-- This allows users to block other users, which:
-- 1. Adds them to the blocked_users array in user_preferences
-- 2. Removes any existing matches between them
-- 3. Prevents future matching

-- 1. Create function to block a user
CREATE OR REPLACE FUNCTION block_user(blocker_id UUID, blocked_id UUID)
RETURNS void AS $$
BEGIN
  -- Ensure user_preferences row exists for blocker
  INSERT INTO user_preferences (user_id, blocked_users)
  VALUES (blocker_id, ARRAY[blocked_id]::UUID[])
  ON CONFLICT (user_id) DO UPDATE
  SET blocked_users = COALESCE(user_preferences.blocked_users, ARRAY[]::UUID[]) ||
    CASE
      WHEN blocked_id = ANY(COALESCE(user_preferences.blocked_users, ARRAY[]::UUID[]))
      THEN ARRAY[]::UUID[]
      ELSE ARRAY[blocked_id]::UUID[]
    END,
  updated_at = NOW();

  -- Delete any matches between these users
  DELETE FROM matches
  WHERE (user1_id = blocker_id AND user2_id = blocked_id)
     OR (user1_id = blocked_id AND user2_id = blocker_id);

  -- Delete any pending swipes between these users
  DELETE FROM swipes
  WHERE (swiper_id = blocker_id AND swiped_id = blocked_id)
     OR (swiper_id = blocked_id AND swiped_id = blocker_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create function to unblock a user
CREATE OR REPLACE FUNCTION unblock_user(unblocker_id UUID, unblocked_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE user_preferences
  SET blocked_users = array_remove(COALESCE(blocked_users, ARRAY[]::UUID[]), unblocked_id),
      updated_at = NOW()
  WHERE user_id = unblocker_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create function to check if a user is blocked
CREATE OR REPLACE FUNCTION is_blocked_by(blocker_id UUID, blocked_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_preferences
    WHERE user_id = blocker_id
    AND blocked_id = ANY(COALESCE(blocked_users, ARRAY[]::UUID[]))
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Update the matching query to exclude blocked users
-- (This is already handled in the app, but adding for completeness)
COMMENT ON FUNCTION block_user IS 'Block a user: adds to blocked_users array, deletes matches and swipes';
COMMENT ON FUNCTION unblock_user IS 'Unblock a user: removes from blocked_users array';
COMMENT ON FUNCTION is_blocked_by IS 'Check if blocker_id has blocked blocked_id';

-- 5. Grant execute permissions
GRANT EXECUTE ON FUNCTION block_user TO authenticated;
GRANT EXECUTE ON FUNCTION unblock_user TO authenticated;
GRANT EXECUTE ON FUNCTION is_blocked_by TO authenticated;
