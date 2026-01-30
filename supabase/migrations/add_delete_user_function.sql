-- Function to delete a user's auth record from auth.users
-- Must be called AFTER all app data has been deleted from public tables
-- Requires: the calling user must be deleting their own account (auth.uid() check)

CREATE OR REPLACE FUNCTION delete_auth_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- Runs with the function owner's privileges (superuser/service role)
SET search_path = auth, public
AS $$
BEGIN
  -- Verify the caller is deleting their own account
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Delete the user from auth.users
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

-- Only authenticated users can call this function
GRANT EXECUTE ON FUNCTION delete_auth_user() TO authenticated;
-- Revoke from anon/public for safety
REVOKE EXECUTE ON FUNCTION delete_auth_user() FROM anon;
REVOKE EXECUTE ON FUNCTION delete_auth_user() FROM public;
