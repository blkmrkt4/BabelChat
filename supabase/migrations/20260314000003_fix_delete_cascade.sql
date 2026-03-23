-- =============================================================================
-- Fix delete_user_cascade:
--   1. Fix device_tokens WHERE clause (user_id is UUID, not text)
--   2. Add Language Lab tables to cascade (partner_streaks, user_daily_activity, chat_sessions)
--   3. Add session_video_slots to cascade
-- =============================================================================

CREATE OR REPLACE FUNCTION delete_user_cascade(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify the caller is deleting their own account
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Cannot delete another user''s account';
  END IF;

  -- Delete in order respecting foreign key constraints
  -- All within a single transaction (implicit in plpgsql)

  DELETE FROM messages
    WHERE sender_id = p_user_id OR receiver_id = p_user_id;

  DELETE FROM conversations
    WHERE user1_id = p_user_id OR user2_id = p_user_id;

  DELETE FROM reported_users
    WHERE reporter_id = p_user_id OR reported_user_id = p_user_id;

  DELETE FROM muse_interactions
    WHERE user_id = p_user_id;

  DELETE FROM feedback
    WHERE user_id = p_user_id;

  DELETE FROM matches
    WHERE user1_id = p_user_id OR user2_id = p_user_id;

  DELETE FROM swipes
    WHERE swiper_id = p_user_id OR swiped_id = p_user_id;

  DELETE FROM user_languages
    WHERE user_id = p_user_id;

  DELETE FROM user_preferences
    WHERE user_id = p_user_id;

  DELETE FROM invites
    WHERE inviter_id = p_user_id;

  DELETE FROM consent_records
    WHERE user_id = p_user_id;

  -- Fixed: user_id is UUID, not text
  DELETE FROM device_tokens
    WHERE user_id = p_user_id;

  DELETE FROM session_video_slots
    WHERE user_id = p_user_id;

  DELETE FROM session_participants
    WHERE user_id = p_user_id;

  DELETE FROM sessions
    WHERE host_id = p_user_id;

  -- Language Lab tables (have ON DELETE CASCADE, but delete explicitly for ordering)
  DELETE FROM partner_streaks
    WHERE user_id = p_user_id OR partner_id = p_user_id;

  DELETE FROM user_daily_activity
    WHERE user_id = p_user_id;

  DELETE FROM chat_sessions
    WHERE user_id = p_user_id;

  DELETE FROM profiles
    WHERE id = p_user_id;
END;
$$;
