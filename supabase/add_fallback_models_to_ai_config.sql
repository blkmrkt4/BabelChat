-- Add fallback model columns to ai_config table
-- This supports model resilience by having 3 fallback options if primary model is unavailable

ALTER TABLE ai_config
ADD COLUMN IF NOT EXISTS fallback_model_1_id TEXT,
ADD COLUMN IF NOT EXISTS fallback_model_1_name TEXT,
ADD COLUMN IF NOT EXISTS fallback_model_2_id TEXT,
ADD COLUMN IF NOT EXISTS fallback_model_2_name TEXT,
ADD COLUMN IF NOT EXISTS fallback_model_3_id TEXT,
ADD COLUMN IF NOT EXISTS fallback_model_3_name TEXT;

-- Add helpful comments
COMMENT ON COLUMN ai_config.fallback_model_1_id IS 'First fallback model ID if primary fails';
COMMENT ON COLUMN ai_config.fallback_model_1_name IS 'First fallback model display name';
COMMENT ON COLUMN ai_config.fallback_model_2_id IS 'Second fallback model ID if first fallback fails';
COMMENT ON COLUMN ai_config.fallback_model_2_name IS 'Second fallback model display name';
COMMENT ON COLUMN ai_config.fallback_model_3_id IS 'Third fallback model ID if second fallback fails';
COMMENT ON COLUMN ai_config.fallback_model_3_name IS 'Third fallback model display name';
