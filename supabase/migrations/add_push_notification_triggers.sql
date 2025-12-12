-- Database triggers to send push notifications automatically

-- Function to send push notification for new messages
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
    receiver_name TEXT;
    sender_name TEXT;
    notification_body TEXT;
BEGIN
    -- Get sender's name
    SELECT first_name INTO sender_name
    FROM profiles
    WHERE id = NEW.sender_id;

    -- Get receiver's name (for logging)
    SELECT first_name INTO receiver_name
    FROM profiles
    WHERE id = NEW.receiver_id;

    -- Build notification body
    notification_body := sender_name || ' sent you a message';

    -- Insert notification log (will trigger Edge Function via webhook or can be polled)
    INSERT INTO notification_logs (
        user_id,
        notification_type,
        message_id,
        title,
        body,
        payload
    ) VALUES (
        NEW.receiver_id,
        'new_message',
        NEW.id,
        'New Message',
        notification_body,
        jsonb_build_object(
            'conversation_id', NEW.conversation_id::text,
            'sender_id', NEW.sender_id::text,
            'message_id', NEW.id::text
        )
    );

    -- Note: You can also call the Edge Function directly here using pg_net extension
    -- For now, we'll use a separate polling service or webhook

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Send notification when new message is inserted
CREATE TRIGGER trigger_notify_new_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_message();

-- Function to send push notification for new matches
CREATE OR REPLACE FUNCTION notify_new_match()
RETURNS TRIGGER AS $$
DECLARE
    user1_name TEXT;
    user2_name TEXT;
BEGIN
    -- Only notify when match is confirmed (both users swiped right)
    IF NEW.status != 'matched' THEN
        RETURN NEW;
    END IF;

    -- Get user names
    SELECT first_name INTO user1_name
    FROM profiles
    WHERE id = NEW.user1_id;

    SELECT first_name INTO user2_name
    FROM profiles
    WHERE id = NEW.user2_id;

    -- Notify user1
    INSERT INTO notification_logs (
        user_id,
        notification_type,
        match_id,
        title,
        body,
        payload
    ) VALUES (
        NEW.user1_id,
        'new_match',
        NEW.id,
        'It''s a Match! 🎉',
        'You and ' || user2_name || ' both want to practice together!',
        jsonb_build_object(
            'match_id', NEW.id::text,
            'other_user_id', NEW.user2_id::text
        )
    );

    -- Notify user2
    INSERT INTO notification_logs (
        user_id,
        notification_type,
        match_id,
        title,
        body,
        payload
    ) VALUES (
        NEW.user2_id,
        'new_match',
        NEW.id,
        'It''s a Match! 🎉',
        'You and ' || user1_name || ' both want to practice together!',
        jsonb_build_object(
            'match_id', NEW.id::text,
            'other_user_id', NEW.user1_id::text
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Send notification when new match is created
CREATE TRIGGER trigger_notify_new_match
    AFTER INSERT OR UPDATE OF status ON matches
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_match();

-- Create a function to process pending notifications (to be called by a cron job or service)
CREATE OR REPLACE FUNCTION process_pending_notifications()
RETURNS TABLE (
    notification_id UUID,
    user_id UUID,
    notification_type TEXT,
    title TEXT,
    body TEXT,
    payload JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        nl.id as notification_id,
        nl.user_id,
        nl.notification_type,
        nl.title,
        nl.body,
        nl.payload
    FROM notification_logs nl
    WHERE nl.sent_at IS NOT NULL
      AND nl.delivered_at IS NULL
      AND nl.failed_at IS NULL
      AND nl.sent_at > NOW() - INTERVAL '5 minutes'  -- Only process recent notifications
    ORDER BY nl.sent_at ASC
    LIMIT 100;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark notification as delivered
CREATE OR REPLACE FUNCTION mark_notification_delivered(
    p_notification_id UUID,
    p_apns_response JSONB DEFAULT NULL,
    p_apns_id TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE notification_logs
    SET
        delivered_at = NOW(),
        apns_response = p_apns_response,
        apns_id = p_apns_id
    WHERE id = p_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark notification as failed
CREATE OR REPLACE FUNCTION mark_notification_failed(
    p_notification_id UUID,
    p_error_message TEXT,
    p_apns_response JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE notification_logs
    SET
        failed_at = NOW(),
        error_message = p_error_message,
        apns_response = p_apns_response
    WHERE id = p_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION process_pending_notifications() TO service_role;
GRANT EXECUTE ON FUNCTION mark_notification_delivered(UUID, JSONB, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION mark_notification_failed(UUID, TEXT, JSONB) TO service_role;

-- Comments
COMMENT ON FUNCTION notify_new_message() IS 'Automatically creates notification log entry when new message is inserted';
COMMENT ON FUNCTION notify_new_match() IS 'Automatically creates notification log entries when users match';
COMMENT ON FUNCTION process_pending_notifications() IS 'Returns pending notifications to be sent via APNs';
COMMENT ON FUNCTION mark_notification_delivered(UUID, JSONB, TEXT) IS 'Marks notification as successfully delivered';
COMMENT ON FUNCTION mark_notification_failed(UUID, TEXT, JSONB) IS 'Marks notification as failed with error details';
