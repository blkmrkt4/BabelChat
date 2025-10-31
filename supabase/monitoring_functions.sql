-- =====================================================
-- Health Check Functions using pg_net
-- =====================================================
-- Run this in Supabase SQL Editor AFTER monitoring_schema.sql

-- 1. Enable pg_net extension (for making HTTP requests from PostgreSQL)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Create function to test a single model
CREATE OR REPLACE FUNCTION test_openrouter_model(
  p_model_id text,
  p_category text,
  p_api_key text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_request_id uuid;
  v_test_prompt text;
BEGIN
  -- Simple test prompt based on category
  v_test_prompt := CASE p_category
    WHEN 'translation' THEN 'Translate to Spanish: Hello'
    WHEN 'grammar' THEN 'Check grammar: I goes to store'
    WHEN 'scoring' THEN 'Rate this text: Good job'
    ELSE 'test'
  END;

  -- Make async HTTP request to OpenRouter
  SELECT INTO v_request_id net.http_post(
    url := 'https://openrouter.ai/api/v1/chat/completions',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || p_api_key,
      'Content-Type', 'application/json',
      'HTTP-Referer', 'https://langchat.app',
      'X-Title', 'LangChat Health Check'
    ),
    body := jsonb_build_object(
      'model', p_model_id,
      'messages', jsonb_build_array(
        jsonb_build_object('role', 'user', 'content', v_test_prompt)
      ),
      'max_tokens', 10
    )
  );

  -- Insert pending check record
  INSERT INTO api_health_checks (
    service,
    model_id,
    category,
    status,
    metadata
  ) VALUES (
    'openrouter',
    p_model_id,
    p_category,
    'pending',
    jsonb_build_object('request_id', v_request_id)
  );

  RETURN v_request_id;
END;
$$;

-- 3. Create function to process HTTP response
CREATE OR REPLACE FUNCTION process_health_check_response()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status_code int;
  v_response jsonb;
  v_start_time timestamptz;
  v_response_time int;
BEGIN
  -- Get the HTTP response
  v_status_code := NEW.status_code;
  v_response := NEW.content::jsonb;

  -- Calculate response time (approximate)
  v_start_time := (
    SELECT checked_at
    FROM api_health_checks
    WHERE metadata->>'request_id' = NEW.id::text
    LIMIT 1
  );

  v_response_time := EXTRACT(EPOCH FROM (now() - v_start_time)) * 1000;

  -- Update the health check record
  IF v_status_code = 200 THEN
    UPDATE api_health_checks
    SET
      status = 'success',
      response_time_ms = v_response_time,
      checked_at = now()
    WHERE metadata->>'request_id' = NEW.id::text;
  ELSE
    UPDATE api_health_checks
    SET
      status = 'error',
      response_time_ms = v_response_time,
      error_code = v_status_code::text,
      error_message = COALESCE(
        v_response->>'error',
        v_response->'error'->>'message',
        'Unknown error'
      ),
      metadata = v_response,
      checked_at = now()
    WHERE metadata->>'request_id' = NEW.id::text;
  END IF;

  -- Check if we need to send alerts
  PERFORM check_and_send_alerts();

  RETURN NEW;
END;
$$;

-- 4. Create trigger to process responses automatically
CREATE TRIGGER on_http_response
  AFTER INSERT ON net.http_request_queue
  FOR EACH ROW
  EXECUTE FUNCTION process_health_check_response();

-- 5. Create function to run all health checks
CREATE OR REPLACE FUNCTION run_all_health_checks(p_api_key text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_config RECORD;
  v_request_id uuid;
  v_results json;
BEGIN
  -- Test all active models
  FOR v_config IN
    SELECT model_id, category
    FROM ai_model_config
    WHERE is_active = true
  LOOP
    v_request_id := test_openrouter_model(
      v_config.model_id,
      v_config.category,
      p_api_key
    );
  END LOOP;

  -- Return summary
  SELECT json_build_object(
    'success', true,
    'message', 'Health checks initiated',
    'models_tested', COUNT(*)
  )
  INTO v_results
  FROM ai_model_config
  WHERE is_active = true;

  RETURN v_results;
END;
$$;

-- 6. Create alert checking function
CREATE OR REPLACE FUNCTION check_and_send_alerts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_config RECORD;
  v_failures int;
  v_last_alert timestamptz;
  v_model_key text;
BEGIN
  -- For each enabled alert config
  FOR v_config IN
    SELECT * FROM alert_config WHERE enabled = true
  LOOP
    -- Check each model for consecutive failures
    FOR v_model_key IN
      SELECT DISTINCT model_id
      FROM api_health_checks
      WHERE checked_at > now() - interval '2 hours'
    LOOP
      -- Count recent consecutive failures
      SELECT COUNT(*)
      INTO v_failures
      FROM (
        SELECT status
        FROM api_health_checks
        WHERE model_id = v_model_key
          AND checked_at > now() - interval '1 hour'
        ORDER BY checked_at DESC
        LIMIT v_config.failure_threshold
      ) recent
      WHERE status != 'success';

      -- If threshold exceeded, check cooldown and send alert
      IF v_failures >= v_config.failure_threshold THEN
        -- Get last alert time for this model
        SELECT sent_at INTO v_last_alert
        FROM alert_history
        WHERE alert_config_id = v_config.id
          AND model_id = v_model_key
        ORDER BY sent_at DESC
        LIMIT 1;

        -- Send alert if cooldown expired or first alert
        IF v_last_alert IS NULL OR
           (now() - v_last_alert) > (v_config.cooldown_minutes * interval '1 minute')
        THEN
          -- Send the alert (webhook/email)
          PERFORM send_alert(
            v_config.id,
            v_config.alert_type,
            v_config.destination,
            'openrouter',
            v_model_key,
            format('%s consecutive failures detected', v_failures)
          );

          -- Log alert sent
          INSERT INTO alert_history (
            alert_config_id,
            service,
            model_id,
            reason,
            metadata
          ) VALUES (
            v_config.id,
            'openrouter',
            v_model_key,
            format('%s consecutive failures', v_failures),
            jsonb_build_object('failure_count', v_failures)
          );
        END IF;
      END IF;
    END LOOP;
  END LOOP;
END;
$$;

-- 7. Create webhook alert sender
CREATE OR REPLACE FUNCTION send_alert(
  p_config_id uuid,
  p_alert_type text,
  p_destination text,
  p_service text,
  p_model_id text,
  p_reason text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_message text;
  v_request_id uuid;
BEGIN
  v_message := format(
    '⚠️ ALERT: %s model %s - %s',
    p_service,
    p_model_id,
    p_reason
  );

  IF p_alert_type = 'webhook' OR p_alert_type = 'slack' THEN
    -- Send to Slack/Discord webhook
    SELECT INTO v_request_id net.http_post(
      url := p_destination,
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := jsonb_build_object(
        'text', v_message,
        'username', 'LangChat Monitor',
        'icon_emoji', ':warning:'
      )
    );
  END IF;

  -- Log that we attempted to send
  RAISE NOTICE 'Alert sent: %', v_message;
END;
$$;

-- 8. Create a simple cron-like scheduler using pg_cron
-- First, enable the extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule health checks every 15 minutes
-- NOTE: Replace 'YOUR_OPENROUTER_API_KEY' with your actual key
SELECT cron.schedule(
  'langchat-health-check',
  '*/15 * * * *',
  $$SELECT run_all_health_checks('YOUR_OPENROUTER_API_KEY')$$
);

-- 9. View scheduled jobs
-- SELECT * FROM cron.job;

-- 10. Manually trigger health check (for testing)
-- SELECT run_all_health_checks('YOUR_OPENROUTER_API_KEY');

-- =====================================================
-- SETUP COMPLETE!
--
-- Next steps:
-- 1. Replace 'YOUR_OPENROUTER_API_KEY' in the cron.schedule above
-- 2. Add a webhook URL to alert_config table:
--    UPDATE alert_config SET
--      destination = 'https://hooks.slack.com/services/YOUR/WEBHOOK',
--      enabled = true
--    WHERE alert_type = 'webhook';
-- 3. Test manually: SELECT run_all_health_checks('your-api-key');
-- =====================================================
