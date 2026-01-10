-- Fix demo profile languages and proficiency
UPDATE profiles SET
    learning_languages = ARRAY['French', 'Spanish'],
    proficiency_levels = '{"French": "beginner", "Spanish": "beginner"}'::jsonb
WHERE id = '2b89fd98-a443-459a-8e1a-fb0922b0a536';

-- Verify
SELECT first_name, learning_languages, proficiency_levels FROM profiles
WHERE id = '2b89fd98-a443-459a-8e1a-fb0922b0a536';
