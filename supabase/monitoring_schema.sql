-- =====================================================
-- LangChat API Monitoring System
-- =====================================================
-- Run this entire file in Supabase SQL Editor

-- 1. Health check results (proactive monitoring)
CREATE TABLE IF NOT EXISTS api_health_checks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checked_at timestamptz DEFAULT now(),
  service text NOT NULL, -- 'openrouter'
  model_id text, -- which model was tested
  category text, -- 'translation', 'grammar', 'scoring'
  status text NOT NULL, -- 'success', 'error', 'timeout', 'rate_limited'
  response_time_ms int,
  error_code text, -- HTTP status code or error type
  error_message text,
  metadata jsonb -- full error details
);

CREATE INDEX IF NOT EXISTS idx_health_checks_time ON api_health_checks(checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_health_checks_status ON api_health_checks(status);
CREATE INDEX IF NOT EXISTS idx_health_checks_model ON api_health_checks(model_id);

-- 2. Error logs from iOS app (reactive monitoring)
CREATE TABLE IF NOT EXISTS api_error_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  occurred_at timestamptz DEFAULT now(),
  user_id uuid REFERENCES auth.users(id),
  service text NOT NULL,
  model_id text,
  category text,
  error_type text, -- '401', '429', '500', 'timeout', 'network'
  error_message text,
  request_metadata jsonb, -- what was being requested
  app_version text, -- iOS app version
  device_info text -- iPhone model, iOS version
);

CREATE INDEX IF NOT EXISTS idx_error_logs_time ON api_error_logs(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_error_logs_user ON api_error_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_error_logs_type ON api_error_logs(error_type);

-- 3. Alert configuration
CREATE TABLE IF NOT EXISTS alert_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type text NOT NULL, -- 'email', 'webhook', 'slack'
  destination text NOT NULL, -- email address or webhook URL
  enabled boolean DEFAULT true,
  failure_threshold int DEFAULT 3, -- consecutive failures before alerting
  cooldown_minutes int DEFAULT 60, -- wait before re-alerting
  services text[] DEFAULT ARRAY['openrouter'], -- which services to monitor
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 4. Alert history (prevent spam)
CREATE TABLE IF NOT EXISTS alert_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sent_at timestamptz DEFAULT now(),
  alert_config_id uuid REFERENCES alert_config(id),
  service text,
  model_id text,
  reason text,
  metadata jsonb
);

CREATE INDEX IF NOT EXISTS idx_alert_history_time ON alert_history(sent_at DESC);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE api_health_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_history ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies - Allow service role to do everything
CREATE POLICY "Service role full access on health_checks" ON api_health_checks
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on error_logs" ON api_error_logs
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on alert_config" ON alert_config
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on alert_history" ON alert_history
  FOR ALL USING (auth.role() = 'service_role');

-- 7. Allow authenticated users to read monitoring data (for web admin)
CREATE POLICY "Authenticated users can read health_checks" ON api_health_checks
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read error_logs" ON api_error_logs
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read alert_config" ON alert_config
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read alert_history" ON alert_history
  FOR SELECT USING (auth.role() = 'authenticated');

-- 8. Allow iOS app to insert error logs
CREATE POLICY "Users can insert their own error logs" ON api_error_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 9. Insert default alert configuration
INSERT INTO alert_config (alert_type, destination, enabled, failure_threshold, cooldown_minutes)
VALUES ('webhook', 'https://hooks.slack.com/services/YOUR_SLACK_WEBHOOK', false, 3, 60)
ON CONFLICT DO NOTHING;

-- 10. Create a view for monitoring dashboard
CREATE OR REPLACE VIEW monitoring_summary AS
SELECT
  date_trunc('hour', checked_at) as hour,
  service,
  model_id,
  category,
  COUNT(*) as total_checks,
  COUNT(*) FILTER (WHERE status = 'success') as successful,
  COUNT(*) FILTER (WHERE status != 'success') as failed,
  ROUND(AVG(response_time_ms)) as avg_response_time_ms,
  ROUND((COUNT(*) FILTER (WHERE status = 'success')::numeric / COUNT(*)) * 100, 2) as success_rate
FROM api_health_checks
WHERE checked_at > now() - interval '24 hours'
GROUP BY date_trunc('hour', checked_at), service, model_id, category
ORDER BY hour DESC;

-- 11. Grant permissions for web admin
GRANT SELECT ON monitoring_summary TO authenticated;

-- =====================================================
-- DONE! Now go to Supabase Dashboard to see the tables
-- =====================================================
