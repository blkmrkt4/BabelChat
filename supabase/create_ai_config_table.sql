-- Create AI Configuration Table
-- This table stores global AI model configurations that apply to ALL users
-- Only admins can modify, all users read the same configuration

CREATE TABLE IF NOT EXISTS ai_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL UNIQUE, -- 'translation', 'grammar', 'scoring'
    model_id TEXT NOT NULL, -- e.g., 'anthropic/claude-3.5-sonnet'
    model_name TEXT NOT NULL, -- e.g., 'Claude 3.5 Sonnet'
    model_provider TEXT NOT NULL, -- e.g., 'anthropic', 'openai'
    prompt_template TEXT NOT NULL, -- System prompt with {learning_language} and {native_language} placeholders
    grammar_level_1_prompt TEXT, -- For grammar only: minimal feedback
    grammar_level_2_prompt TEXT, -- For grammar only: moderate feedback
    grammar_level_3_prompt TEXT, -- For grammar only: detailed feedback
    temperature FLOAT DEFAULT 0.7, -- 0.0-1.0
    max_tokens INT DEFAULT 1000,
    is_active BOOLEAN DEFAULT true, -- Allow disabling/A-B testing
    updated_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add index for fast lookups
CREATE INDEX IF NOT EXISTS idx_ai_config_category ON ai_config(category);
CREATE INDEX IF NOT EXISTS idx_ai_config_active ON ai_config(is_active);

-- Enable RLS
ALTER TABLE ai_config ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can read active configs
CREATE POLICY "Anyone can read active AI configs"
    ON ai_config
    FOR SELECT
    USING (is_active = true);

-- Policy: Only authenticated admins can modify (you can refine this later)
CREATE POLICY "Only admins can modify AI configs"
    ON ai_config
    FOR ALL
    USING (auth.role() = 'authenticated'); -- Temporary: refine with admin role later

-- Add helpful comments
COMMENT ON TABLE ai_config IS 'Global AI model configurations for translation, grammar, and scoring';
COMMENT ON COLUMN ai_config.category IS 'Configuration category: translation, grammar, or scoring';
COMMENT ON COLUMN ai_config.prompt_template IS 'System prompt template with {learning_language} and {native_language} placeholders';
COMMENT ON COLUMN ai_config.temperature IS 'Model temperature for response randomness (0.0-1.0)';
