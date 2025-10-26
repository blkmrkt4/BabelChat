-- Seed AI Configuration with Production Defaults
-- Run this AFTER creating the ai_config table

-- Translation Configuration
INSERT INTO ai_config (category, model_id, model_name, model_provider, prompt_template, temperature, max_tokens)
VALUES (
    'translation',
    'anthropic/claude-3.5-sonnet',
    'Claude 3.5 Sonnet',
    'anthropic',
    'You are a professional translator. Translate the following text from {learning_language} to {native_language}. Provide ONLY the translation, no explanations or additional text.',
    0.3,
    1000
);

-- Grammar Check Configuration
INSERT INTO ai_config (
    category,
    model_id,
    model_name,
    model_provider,
    prompt_template,
    grammar_level_1_prompt,
    grammar_level_2_prompt,
    grammar_level_3_prompt,
    temperature,
    max_tokens
)
VALUES (
    'grammar',
    'anthropic/claude-3.5-sonnet',
    'Claude 3.5 Sonnet',
    'anthropic',
    -- Default prompt (level 2)
    'You are a {learning_language} language teacher helping a {native_language} speaker. Check the following text for grammar errors and provide feedback in JSON format with this structure:
    {
      "has_errors": boolean,
      "corrections": [
        {
          "original": "incorrect phrase",
          "corrected": "correct phrase",
          "explanation": "brief explanation in {native_language}"
        }
      ],
      "overall_feedback": "brief overall assessment"
    }',
    -- Level 1: Minimal feedback (only critical errors)
    'You are a {learning_language} language teacher. Check for CRITICAL grammar errors only. Provide minimal feedback in JSON:
    {
      "has_errors": boolean,
      "corrections": [{"original": "text", "corrected": "text"}]
    }',
    -- Level 2: Moderate feedback (default)
    'You are a {learning_language} language teacher helping a {native_language} speaker. Check the following text for grammar errors and provide feedback in JSON format with this structure:
    {
      "has_errors": boolean,
      "corrections": [
        {
          "original": "incorrect phrase",
          "corrected": "correct phrase",
          "explanation": "brief explanation in {native_language}"
        }
      ],
      "overall_feedback": "brief overall assessment"
    }',
    -- Level 3: Detailed feedback (everything)
    'You are an expert {learning_language} language teacher. Provide comprehensive grammar feedback including minor stylistic improvements. Use JSON format:
    {
      "has_errors": boolean,
      "corrections": [
        {
          "original": "text",
          "corrected": "text",
          "explanation": "detailed explanation in {native_language}",
          "severity": "critical|moderate|minor",
          "grammar_rule": "the grammar rule being violated"
        }
      ],
      "style_suggestions": ["suggestion 1", "suggestion 2"],
      "overall_feedback": "comprehensive assessment"
    }',
    0.3,
    1500
);

-- Scoring Configuration
INSERT INTO ai_config (category, model_id, model_name, model_provider, prompt_template, temperature, max_tokens)
VALUES (
    'scoring',
    'anthropic/claude-3.5-sonnet',
    'Claude 3.5 Sonnet',
    'anthropic',
    'You are a {learning_language} language assessment expert. Evaluate the following text written by a {native_language} speaker learning {learning_language}. Provide a score in JSON format:
    {
      "score": 0-100,
      "level": "beginner|intermediate|advanced",
      "strengths": ["strength 1", "strength 2"],
      "areas_for_improvement": ["area 1", "area 2"],
      "feedback": "encouraging feedback in {native_language}"
    }',
    0.3,
    800
);

-- Verify insertion
SELECT category, model_name, is_active FROM ai_config ORDER BY category;
