-- AI Model Configuration and Scoring Table
-- For testing and evaluating different AI models for translation, grammar, and scoring

CREATE TABLE IF NOT EXISTS ai_model_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

    -- Model identification
    model_id TEXT NOT NULL, -- e.g., "openai/gpt-4", "anthropic/claude-3"
    model_name TEXT NOT NULL,
    model_provider TEXT NOT NULL, -- e.g., "openai", "anthropic"

    -- Model purpose/category
    category TEXT NOT NULL CHECK (category IN ('translation', 'grammar', 'scoring', 'general')),

    -- Cost information from OpenRouter
    input_cost_per_token DECIMAL(10, 8),
    output_cost_per_token DECIMAL(10, 8),

    -- User configuration
    master_prompt TEXT, -- Hidden system prompt for the model
    temperature DECIMAL(3, 2) DEFAULT 0.7,
    max_tokens INTEGER DEFAULT 1000,

    -- User scoring
    user_score DECIMAL(2, 1) CHECK (user_score >= 0 AND user_score <= 5),
    score_notes TEXT,
    tests_performed INTEGER DEFAULT 0,

    -- Metadata
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false, -- Default model for this category
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique constraint: one default per category per user
    CONSTRAINT unique_default_per_category UNIQUE (user_id, category, is_default) WHERE is_default = true,
    CONSTRAINT unique_user_model_category UNIQUE (user_id, model_id, category)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_ai_configs_user_category ON ai_model_configs(user_id, category);
CREATE INDEX IF NOT EXISTS idx_ai_configs_score ON ai_model_configs(user_score DESC NULLS LAST);

-- Enable RLS
ALTER TABLE ai_model_configs ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can manage their AI configs" ON ai_model_configs
    FOR ALL USING (auth.uid() = user_id);

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_ai_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamp
DROP TRIGGER IF EXISTS update_ai_config_timestamp ON ai_model_configs;
CREATE TRIGGER update_ai_config_timestamp
    BEFORE UPDATE ON ai_model_configs
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_config_timestamp();

-- Insert some default OpenRouter models for all users (without scores)
INSERT INTO ai_model_configs (user_id, model_id, model_name, model_provider, category, input_cost_per_token, output_cost_per_token, master_prompt)
SELECT
    id as user_id,
    model.model_id,
    model.model_name,
    model.model_provider,
    model.category,
    model.input_cost,
    model.output_cost,
    model.default_prompt
FROM profiles
CROSS JOIN (
    VALUES
    -- Translation models
    ('openai/gpt-4-turbo', 'GPT-4 Turbo', 'openai', 'translation', 0.00001, 0.00003,
     'You are a professional translator. Translate the following text from {source_language} to {target_language}. Maintain the tone and style of the original message. Only return the translation, no explanations.'),
    ('anthropic/claude-3-opus', 'Claude 3 Opus', 'anthropic', 'translation', 0.000015, 0.000075,
     'You are a professional translator. Translate the following text from {source_language} to {target_language}. Maintain the tone and style of the original message. Only return the translation, no explanations.'),
    ('google/gemini-pro', 'Gemini Pro', 'google', 'translation', 0.000001, 0.000002,
     'You are a professional translator. Translate the following text from {source_language} to {target_language}. Maintain the tone and style of the original message. Only return the translation, no explanations.'),

    -- Grammar models
    ('openai/gpt-4-turbo', 'GPT-4 Turbo', 'openai', 'grammar', 0.00001, 0.00003,
     'You are a language expert. Check the following {language} text for grammar errors and provide corrections with brief explanations. Format: {"corrections": [...], "explanation": "..."}'),
    ('anthropic/claude-3-sonnet', 'Claude 3 Sonnet', 'anthropic', 'grammar', 0.000003, 0.000015,
     'You are a language expert. Check the following {language} text for grammar errors and provide corrections with brief explanations. Format: {"corrections": [...], "explanation": "..."}'),

    -- Scoring models
    ('openai/gpt-3.5-turbo', 'GPT-3.5 Turbo', 'openai', 'scoring', 0.0000005, 0.0000015,
     'Rate the following {language} text for correctness on a scale of 0-100. Consider grammar, spelling, and natural expression. Return only a JSON: {"score": X, "brief_feedback": "..."}'),
    ('anthropic/claude-instant', 'Claude Instant', 'anthropic', 'scoring', 0.0000008, 0.0000024,
     'Rate the following {language} text for correctness on a scale of 0-100. Consider grammar, spelling, and natural expression. Return only a JSON: {"score": X, "brief_feedback": "..."}')
) AS model(model_id, model_name, model_provider, category, input_cost, output_cost, default_prompt)
ON CONFLICT (user_id, model_id, category) DO NOTHING;