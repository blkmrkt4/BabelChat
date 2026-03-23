-- Admin settings table for persistent configuration
CREATE TABLE IF NOT EXISTS admin_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default monitoring refresh interval (30 minutes = 1800 seconds)
INSERT INTO admin_settings (key, value)
VALUES ('monitoring_refresh_interval', '{"seconds": 1800}')
ON CONFLICT (key) DO NOTHING;

-- Enable RLS
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read settings
CREATE POLICY "Anyone can read admin settings"
ON admin_settings FOR SELECT
TO anon, authenticated
USING (true);

-- Only service role can update
CREATE POLICY "Service role can update admin settings"
ON admin_settings FOR UPDATE
TO service_role
USING (true);

CREATE POLICY "Service role can insert admin settings"
ON admin_settings FOR INSERT
TO service_role
WITH CHECK (true);

COMMENT ON TABLE admin_settings IS 'Stores admin configuration settings';
