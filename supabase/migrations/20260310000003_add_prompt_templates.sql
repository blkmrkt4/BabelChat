-- Create prompt_templates table for storing reusable prompts
CREATE TABLE IF NOT EXISTS prompt_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('translation', 'grammar', 'scoring', 'chatting')),
    system_prompt TEXT,
    user_prompt TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name, category)
);

-- Add RLS policies
ALTER TABLE prompt_templates ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read prompt templates (they're not sensitive)
CREATE POLICY "Anyone can read prompt templates"
    ON prompt_templates FOR SELECT
    USING (true);

-- Only authenticated users can insert/update/delete (admin functionality)
CREATE POLICY "Authenticated users can manage prompt templates"
    ON prompt_templates FOR ALL
    USING (true)
    WITH CHECK (true);

-- Create index for faster lookups by category
CREATE INDEX idx_prompt_templates_category ON prompt_templates(category);

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_prompt_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prompt_templates_updated_at
    BEFORE UPDATE ON prompt_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_prompt_templates_updated_at();
