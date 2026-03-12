-- Atomic account deletion: wraps all user data deletes in a single transaction.
-- Called from the client via: rpc("delete_user_cascade", params: { p_user_id: "..." })
-- Storage and auth.users deletion remain client-side (not accessible from SQL).

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

  DELETE FROM device_tokens
    WHERE user_id = p_user_id::text;

  DELETE FROM session_participants
    WHERE user_id = p_user_id;

  DELETE FROM sessions
    WHERE host_id = p_user_id;

  DELETE FROM profiles
    WHERE id = p_user_id;
END;
$$;

-- Only authenticated users can call this function
GRANT EXECUTE ON FUNCTION delete_user_cascade(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION delete_user_cascade(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION delete_user_cascade(UUID) FROM public;
