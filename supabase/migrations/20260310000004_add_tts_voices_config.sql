-- Migration: Add TTS voice configuration table
-- Run this in Supabase SQL Editor

-- Create table for TTS voice configurations per language
CREATE TABLE IF NOT EXISTS tts_voices (
    language_code VARCHAR(10) PRIMARY KEY,  -- e.g., 'en', 'es', 'fr'
    language_name VARCHAR(50) NOT NULL,      -- e.g., 'English', 'Spanish'
    google_language_code VARCHAR(20) NOT NULL, -- e.g., 'en-US', 'es-ES'
    google_voice_name VARCHAR(50) NOT NULL,   -- e.g., 'en-US-Neural2-J'
    voice_gender VARCHAR(10) DEFAULT 'NEUTRAL', -- MALE, FEMALE, NEUTRAL
    speaking_rate DECIMAL(3,2) DEFAULT 0.85,  -- 0.25 to 4.0, slower for learning
    pitch DECIMAL(4,2) DEFAULT 0.0,           -- -20.0 to 20.0
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE tts_voices ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read voice configs
CREATE POLICY "Anyone can read voice configs" ON tts_voices
    FOR SELECT USING (true);

-- Only allow admins to modify (you can adjust this based on your admin setup)
CREATE POLICY "Admins can modify voice configs" ON tts_voices
    FOR ALL USING (true);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_tts_voices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tts_voices_updated_at
    BEFORE UPDATE ON tts_voices
    FOR EACH ROW
    EXECUTE FUNCTION update_tts_voices_updated_at();

-- Insert default voice configurations for common languages
INSERT INTO tts_voices (language_code, language_name, google_language_code, google_voice_name, voice_gender) VALUES
    ('en', 'English', 'en-US', 'en-US-Neural2-J', 'MALE'),
    ('es', 'Spanish', 'es-ES', 'es-ES-Neural2-A', 'FEMALE'),
    ('fr', 'French', 'fr-FR', 'fr-FR-Neural2-A', 'FEMALE'),
    ('de', 'German', 'de-DE', 'de-DE-Neural2-A', 'FEMALE'),
    ('it', 'Italian', 'it-IT', 'it-IT-Neural2-A', 'FEMALE'),
    ('pt', 'Portuguese', 'pt-BR', 'pt-BR-Neural2-A', 'FEMALE'),
    ('zh', 'Chinese (Mandarin)', 'cmn-CN', 'cmn-CN-Wavenet-A', 'FEMALE'),
    ('ja', 'Japanese', 'ja-JP', 'ja-JP-Neural2-B', 'FEMALE'),
    ('ko', 'Korean', 'ko-KR', 'ko-KR-Neural2-A', 'FEMALE'),
    ('ru', 'Russian', 'ru-RU', 'ru-RU-Wavenet-A', 'FEMALE'),
    ('ar', 'Arabic', 'ar-XA', 'ar-XA-Wavenet-A', 'FEMALE'),
    ('hi', 'Hindi', 'hi-IN', 'hi-IN-Neural2-A', 'FEMALE'),
    ('nl', 'Dutch', 'nl-NL', 'nl-NL-Wavenet-A', 'FEMALE'),
    ('sv', 'Swedish', 'sv-SE', 'sv-SE-Wavenet-A', 'FEMALE'),
    ('no', 'Norwegian', 'nb-NO', 'nb-NO-Wavenet-A', 'FEMALE'),
    ('da', 'Danish', 'da-DK', 'da-DK-Wavenet-A', 'FEMALE'),
    ('fi', 'Finnish', 'fi-FI', 'fi-FI-Wavenet-A', 'FEMALE'),
    ('pl', 'Polish', 'pl-PL', 'pl-PL-Wavenet-A', 'FEMALE'),
    ('tr', 'Turkish', 'tr-TR', 'tr-TR-Wavenet-A', 'FEMALE'),
    ('th', 'Thai', 'th-TH', 'th-TH-Neural2-C', 'FEMALE'),
    ('vi', 'Vietnamese', 'vi-VN', 'vi-VN-Neural2-A', 'FEMALE'),
    ('id', 'Indonesian', 'id-ID', 'id-ID-Wavenet-A', 'FEMALE'),
    ('el', 'Greek', 'el-GR', 'el-GR-Wavenet-A', 'FEMALE'),
    ('he', 'Hebrew', 'he-IL', 'he-IL-Wavenet-A', 'FEMALE'),
    ('cs', 'Czech', 'cs-CZ', 'cs-CZ-Wavenet-A', 'FEMALE'),
    ('ro', 'Romanian', 'ro-RO', 'ro-RO-Wavenet-A', 'FEMALE'),
    ('hu', 'Hungarian', 'hu-HU', 'hu-HU-Wavenet-A', 'FEMALE'),
    ('uk', 'Ukrainian', 'uk-UA', 'uk-UA-Wavenet-A', 'FEMALE'),
    ('bg', 'Bulgarian', 'bg-BG', 'bg-BG-Standard-A', 'FEMALE'),
    ('hr', 'Croatian', 'hr-HR', 'hr-HR-Standard-A', 'FEMALE'),
    ('sk', 'Slovak', 'sk-SK', 'sk-SK-Wavenet-A', 'FEMALE'),
    ('sl', 'Slovenian', 'sl-SI', 'sl-SI-Standard-A', 'FEMALE'),
    ('sr', 'Serbian', 'sr-RS', 'sr-RS-Standard-A', 'FEMALE'),
    ('lt', 'Lithuanian', 'lt-LT', 'lt-LT-Standard-A', 'MALE'),
    ('lv', 'Latvian', 'lv-LV', 'lv-LV-Standard-A', 'MALE'),
    ('et', 'Estonian', 'et-EE', 'et-EE-Standard-A', 'FEMALE'),
    ('ms', 'Malay', 'ms-MY', 'ms-MY-Wavenet-A', 'FEMALE'),
    ('tl', 'Filipino/Tagalog', 'fil-PH', 'fil-PH-Wavenet-A', 'FEMALE'),
    ('bn', 'Bengali', 'bn-IN', 'bn-IN-Wavenet-A', 'FEMALE'),
    ('ta', 'Tamil', 'ta-IN', 'ta-IN-Wavenet-A', 'FEMALE'),
    ('te', 'Telugu', 'te-IN', 'te-IN-Standard-A', 'FEMALE'),
    ('mr', 'Marathi', 'mr-IN', 'mr-IN-Wavenet-A', 'FEMALE'),
    ('gu', 'Gujarati', 'gu-IN', 'gu-IN-Wavenet-A', 'FEMALE'),
    ('kn', 'Kannada', 'kn-IN', 'kn-IN-Wavenet-A', 'FEMALE'),
    ('ml', 'Malayalam', 'ml-IN', 'ml-IN-Wavenet-A', 'FEMALE'),
    ('pa', 'Punjabi', 'pa-IN', 'pa-IN-Wavenet-A', 'FEMALE'),
    ('sw', 'Swahili', 'sw-KE', 'sw-KE-Standard-A', 'FEMALE'),
    ('af', 'Afrikaans', 'af-ZA', 'af-ZA-Standard-A', 'FEMALE'),
    ('ca', 'Catalan', 'ca-ES', 'ca-ES-Standard-A', 'FEMALE'),
    ('eu', 'Basque', 'eu-ES', 'eu-ES-Standard-A', 'FEMALE'),
    ('gl', 'Galician', 'gl-ES', 'gl-ES-Standard-A', 'FEMALE'),
    ('is', 'Icelandic', 'is-IS', 'is-IS-Standard-A', 'FEMALE'),
    ('cy', 'Welsh', 'cy-GB', 'cy-GB-Standard-A', 'FEMALE'),
    ('ga', 'Irish', 'ga-IE', 'ga-IE-Standard-A', 'FEMALE'),
    ('mt', 'Maltese', 'mt-MT', 'mt-MT-Standard-A', 'FEMALE'),
    ('yue', 'Cantonese', 'yue-HK', 'yue-HK-Standard-A', 'FEMALE')
ON CONFLICT (language_code) DO NOTHING;

-- Add comment
COMMENT ON TABLE tts_voices IS 'Configuration for Google Cloud TTS voices per language';
