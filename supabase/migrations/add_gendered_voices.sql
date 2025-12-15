-- Add male and female voice options to tts_voices table
-- This allows selecting different voices based on the message sender's gender

ALTER TABLE tts_voices
ADD COLUMN IF NOT EXISTS male_voice_name TEXT,
ADD COLUMN IF NOT EXISTS female_voice_name TEXT;

-- Update existing rows to split the voice by gender
-- The current google_voice_name becomes the default, and we set male/female variants

-- For languages with multiple voices, set appropriate male/female options
UPDATE tts_voices SET
  male_voice_name = CASE language_code
    WHEN 'en' THEN 'en-US-Neural2-J'
    WHEN 'es' THEN 'es-ES-Neural2-F'
    WHEN 'fr' THEN 'fr-FR-Neural2-D'
    WHEN 'de' THEN 'de-DE-Neural2-D'
    WHEN 'it' THEN 'it-IT-Neural2-C'
    WHEN 'pt' THEN 'pt-BR-Neural2-B'
    WHEN 'ja' THEN 'ja-JP-Neural2-C'
    WHEN 'ko' THEN 'ko-KR-Neural2-C'
    WHEN 'zh' THEN 'cmn-CN-Wavenet-B'
    WHEN 'ru' THEN 'ru-RU-Wavenet-B'
    WHEN 'ar' THEN 'ar-XA-Wavenet-B'
    WHEN 'hi' THEN 'hi-IN-Neural2-B'
    WHEN 'nl' THEN 'nl-NL-Wavenet-B'
    WHEN 'tr' THEN 'tr-TR-Wavenet-B'
    WHEN 'vi' THEN 'vi-VN-Neural2-D'
    WHEN 'tl' THEN 'fil-PH-Wavenet-B'
    WHEN 'th' THEN 'th-TH-Neural2-C'
    ELSE google_voice_name
  END,
  female_voice_name = CASE language_code
    WHEN 'en' THEN 'en-US-Neural2-F'
    WHEN 'es' THEN 'es-ES-Neural2-A'
    WHEN 'fr' THEN 'fr-FR-Neural2-A'
    WHEN 'de' THEN 'de-DE-Neural2-A'
    WHEN 'it' THEN 'it-IT-Neural2-A'
    WHEN 'pt' THEN 'pt-BR-Neural2-A'
    WHEN 'ja' THEN 'ja-JP-Neural2-B'
    WHEN 'ko' THEN 'ko-KR-Neural2-A'
    WHEN 'zh' THEN 'cmn-CN-Wavenet-A'
    WHEN 'ru' THEN 'ru-RU-Wavenet-A'
    WHEN 'ar' THEN 'ar-XA-Wavenet-A'
    WHEN 'hi' THEN 'hi-IN-Neural2-A'
    WHEN 'nl' THEN 'nl-NL-Wavenet-A'
    WHEN 'tr' THEN 'tr-TR-Wavenet-A'
    WHEN 'vi' THEN 'vi-VN-Neural2-A'
    WHEN 'tl' THEN 'fil-PH-Wavenet-A'
    WHEN 'th' THEN 'th-TH-Neural2-C'
    ELSE google_voice_name
  END
WHERE male_voice_name IS NULL OR female_voice_name IS NULL;

-- Set any remaining NULL values to the default voice
UPDATE tts_voices SET
  male_voice_name = COALESCE(male_voice_name, google_voice_name),
  female_voice_name = COALESCE(female_voice_name, google_voice_name);

-- Add comment for clarity
COMMENT ON COLUMN tts_voices.male_voice_name IS 'Google TTS voice name for male speakers';
COMMENT ON COLUMN tts_voices.female_voice_name IS 'Google TTS voice name for female speakers';
