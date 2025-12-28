-- Add Fallback Model 4 columns to ai_config table
-- This allows configuring a 4th fallback model for translation/grammar/scoring

ALTER TABLE ai_config
ADD COLUMN IF NOT EXISTS fallback_model_4_id TEXT,
ADD COLUMN IF NOT EXISTS fallback_model_4_name TEXT;

-- Add comment for documentation
COMMENT ON COLUMN ai_config.fallback_model_4_id IS 'Fourth fallback model ID from OpenRouter';
COMMENT ON COLUMN ai_config.fallback_model_4_name IS 'Fourth fallback model display name';
