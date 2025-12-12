-- Push Notifications Support
-- This migration adds device token storage and notification tracking

-- Create device_tokens table to store APNs tokens for push notifications
CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    device_type TEXT DEFAULT 'ios' CHECK (device_type IN ('ios', 'android')),
    environment TEXT DEFAULT 'development' CHECK (environment IN ('development', 'production')),

    -- Device metadata
    device_name TEXT,
    device_model TEXT,
    os_version TEXT,
    app_version TEXT,

    -- Token management
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,

    -- Ensure unique token per device
    UNIQUE(device_token, user_id)
);

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_device_tokens_token ON device_tokens(device_token) WHERE is_active = true;

-- Create notification_logs table to track sent notifications
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('new_message', 'new_match', 'like_received')),

    -- Related entities
    message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    match_id UUID REFERENCES matches(id) ON DELETE SET NULL,

    -- Notification content
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    payload JSONB DEFAULT '{}',

    -- Delivery tracking
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    delivered_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    error_message TEXT,

    -- APNs response
    apns_response JSONB,
    apns_id TEXT
);

-- Create index for notification logs
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id ON notification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_sent_at ON notification_logs(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_logs_message_id ON notification_logs(message_id);

-- Function to update device token last_used_at
CREATE OR REPLACE FUNCTION update_device_token_last_used()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_used_at = NOW();
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update last_used_at
CREATE TRIGGER trigger_update_device_token_last_used
    BEFORE UPDATE ON device_tokens
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE FUNCTION update_device_token_last_used();

-- Function to clean up inactive device tokens (older than 90 days)
CREATE OR REPLACE FUNCTION cleanup_inactive_device_tokens()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    WITH deleted AS (
        DELETE FROM device_tokens
        WHERE last_used_at < NOW() - INTERVAL '90 days'
        OR (created_at < NOW() - INTERVAL '90 days' AND last_used_at IS NULL)
        RETURNING *
    )
    SELECT COUNT(*) INTO deleted_count FROM deleted;

    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Row Level Security (RLS) policies
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

-- Users can only manage their own device tokens
CREATE POLICY "Users can view their own device tokens"
    ON device_tokens FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own device tokens"
    ON device_tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own device tokens"
    ON device_tokens FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own device tokens"
    ON device_tokens FOR DELETE
    USING (auth.uid() = user_id);

-- Users can view their own notification logs
CREATE POLICY "Users can view their own notification logs"
    ON notification_logs FOR SELECT
    USING (auth.uid() = user_id);

-- Only service role can insert notification logs (server-side only)
CREATE POLICY "Service role can insert notification logs"
    ON notification_logs FOR INSERT
    WITH CHECK (true);

-- Grant permissions
GRANT ALL ON device_tokens TO authenticated;
GRANT SELECT ON notification_logs TO authenticated;
GRANT ALL ON notification_logs TO service_role;

-- Comments for documentation
COMMENT ON TABLE device_tokens IS 'Stores APNs device tokens for push notifications';
COMMENT ON TABLE notification_logs IS 'Tracks all sent push notifications for debugging and analytics';
COMMENT ON COLUMN device_tokens.device_token IS 'APNs device token from iOS device';
COMMENT ON COLUMN device_tokens.environment IS 'Development or production APNs environment';
COMMENT ON COLUMN notification_logs.apns_response IS 'Full response from APNs server for debugging';
