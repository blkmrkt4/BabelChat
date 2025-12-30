-- Migration: Add Muse name configuration to tts_voices
-- This allows configuring male and female Muse names per language

-- Add columns for Muse names
ALTER TABLE tts_voices
ADD COLUMN IF NOT EXISTS male_muse_name TEXT,
ADD COLUMN IF NOT EXISTS female_muse_name TEXT,
ADD COLUMN IF NOT EXISTS is_muse_language BOOLEAN DEFAULT false;

-- Set existing female Muse names (don't change these)
UPDATE tts_voices SET
  female_muse_name = CASE language_code
    WHEN 'en' THEN 'Emma'
    WHEN 'es' THEN 'Maria'
    WHEN 'fr' THEN 'Sophie'
    WHEN 'pt' THEN 'Racquel'
    WHEN 'it' THEN 'Giulia'
    WHEN 'ja' THEN 'Yuki'
    WHEN 'ko' THEN 'Jiwoo'
    WHEN 'zh' THEN 'Lin'
    WHEN 'ru' THEN 'Natasha'
    WHEN 'pl' THEN 'Kasia'
    WHEN 'hi' THEN 'Poonam'
    WHEN 'id' THEN 'Dewi'
    WHEN 'tl' THEN 'Evangeline'
    WHEN 'sv' THEN 'Astrid'
    WHEN 'da' THEN 'Freja'
    WHEN 'fi' THEN 'Aino'
    WHEN 'no' THEN 'Ingrid'
    WHEN 'ar' THEN 'Layla'
    WHEN 'de' THEN 'Anna'
    WHEN 'nl' THEN 'Emma'
    ELSE NULL
  END,
  male_muse_name = CASE language_code
    WHEN 'en' THEN 'James'
    WHEN 'es' THEN 'Carlos'
    WHEN 'fr' THEN 'Pierre'
    WHEN 'pt' THEN 'Lucas'
    WHEN 'it' THEN 'Marco'
    WHEN 'ja' THEN 'Kenji'
    WHEN 'ko' THEN 'Minho'
    WHEN 'zh' THEN 'Wei'
    WHEN 'ru' THEN 'Dmitri'
    WHEN 'pl' THEN 'Jakub'
    WHEN 'hi' THEN 'Arjun'
    WHEN 'id' THEN 'Budi'
    WHEN 'tl' THEN 'Miguel'
    WHEN 'sv' THEN 'Erik'
    WHEN 'da' THEN 'Magnus'
    WHEN 'fi' THEN 'Mikko'
    WHEN 'no' THEN 'Lars'
    WHEN 'ar' THEN 'Omar'
    WHEN 'de' THEN 'Max'
    WHEN 'nl' THEN 'Lars'
    ELSE NULL
  END,
  is_muse_language = CASE language_code
    WHEN 'en' THEN true
    WHEN 'es' THEN true
    WHEN 'fr' THEN true
    WHEN 'pt' THEN true
    WHEN 'it' THEN true
    WHEN 'ja' THEN true
    WHEN 'ko' THEN true
    WHEN 'zh' THEN true
    WHEN 'ru' THEN true
    WHEN 'pl' THEN true
    WHEN 'hi' THEN true
    WHEN 'id' THEN true
    WHEN 'tl' THEN true
    WHEN 'sv' THEN true
    WHEN 'da' THEN true
    WHEN 'fi' THEN true
    WHEN 'no' THEN true
    WHEN 'ar' THEN true
    WHEN 'de' THEN true
    WHEN 'nl' THEN true
    ELSE false
  END
WHERE male_muse_name IS NULL OR female_muse_name IS NULL;

-- Add comments
COMMENT ON COLUMN tts_voices.male_muse_name IS 'Name for the male Muse character for this language';
COMMENT ON COLUMN tts_voices.female_muse_name IS 'Name for the female Muse character for this language';
COMMENT ON COLUMN tts_voices.is_muse_language IS 'Whether this language has a Muse character available';
