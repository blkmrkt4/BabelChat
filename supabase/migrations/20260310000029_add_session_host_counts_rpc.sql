-- RPC function to get session host counts for a set of user IDs
-- Returns the number of completed (ended) sessions each user has hosted

CREATE OR REPLACE FUNCTION get_session_host_counts(p_user_ids UUID[])
RETURNS TABLE (host_id UUID, count BIGINT)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT s.host_id, COUNT(*) AS count
    FROM sessions s
    WHERE s.host_id = ANY(p_user_ids)
      AND s.status = 'ended'
    GROUP BY s.host_id;
$$;
