'use client'

import { useState, useEffect, useRef } from 'react'

interface Voice {
  language_code: string
  language_name: string
  google_language_code: string
  google_voice_name: string
  voice_gender: 'MALE' | 'FEMALE' | 'NEUTRAL'
  speaking_rate: number
  pitch: number
  enabled: boolean
  updated_at?: string
}

// Common Google TTS voice options grouped by language
// Includes Neural2, Wavenet, and Chirp (newest, most natural) voices
const GOOGLE_VOICES: Record<string, { code: string; voices: { name: string; gender: string; type?: string }[] }> = {
  'English (US)': { code: 'en-US', voices: [
    // Chirp voices (newest, most natural)
    { name: 'en-US-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'en-US-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    { name: 'en-US-Chirp-HD-O', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'en-US-Chirp3-HD-Achernar', gender: 'FEMALE', type: 'Chirp3 HD' },
    { name: 'en-US-Chirp3-HD-Aoede', gender: 'FEMALE', type: 'Chirp3 HD' },
    { name: 'en-US-Chirp3-HD-Charon', gender: 'MALE', type: 'Chirp3 HD' },
    { name: 'en-US-Chirp3-HD-Fenrir', gender: 'MALE', type: 'Chirp3 HD' },
    { name: 'en-US-Chirp3-HD-Kore', gender: 'FEMALE', type: 'Chirp3 HD' },
    { name: 'en-US-Chirp3-HD-Puck', gender: 'MALE', type: 'Chirp3 HD' },
    // Neural2 voices
    { name: 'en-US-Neural2-A', gender: 'MALE', type: 'Neural2' },
    { name: 'en-US-Neural2-C', gender: 'FEMALE', type: 'Neural2' },
    { name: 'en-US-Neural2-D', gender: 'MALE', type: 'Neural2' },
    { name: 'en-US-Neural2-E', gender: 'FEMALE', type: 'Neural2' },
    { name: 'en-US-Neural2-F', gender: 'FEMALE', type: 'Neural2' },
    { name: 'en-US-Neural2-G', gender: 'FEMALE', type: 'Neural2' },
    { name: 'en-US-Neural2-H', gender: 'FEMALE', type: 'Neural2' },
    { name: 'en-US-Neural2-I', gender: 'MALE', type: 'Neural2' },
    { name: 'en-US-Neural2-J', gender: 'MALE', type: 'Neural2' },
  ]},
  'English (UK)': { code: 'en-GB', voices: [
    // Chirp voices
    { name: 'en-GB-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'en-GB-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'en-GB-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'en-GB-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'en-GB-Neural2-C', gender: 'FEMALE', type: 'Neural2' },
    { name: 'en-GB-Neural2-D', gender: 'MALE', type: 'Neural2' },
    { name: 'en-GB-Neural2-F', gender: 'FEMALE', type: 'Neural2' },
  ]},
  'English (AU)': { code: 'en-AU', voices: [
    // Chirp voices
    { name: 'en-AU-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'en-AU-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'en-AU-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'en-AU-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'en-AU-Neural2-C', gender: 'FEMALE', type: 'Neural2' },
    { name: 'en-AU-Neural2-D', gender: 'MALE', type: 'Neural2' },
  ]},
  'Spanish (Spain)': { code: 'es-ES', voices: [
    // Chirp voices
    { name: 'es-ES-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'es-ES-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'es-ES-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'es-ES-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'es-ES-Neural2-C', gender: 'FEMALE', type: 'Neural2' },
    { name: 'es-ES-Neural2-D', gender: 'FEMALE', type: 'Neural2' },
    { name: 'es-ES-Neural2-E', gender: 'FEMALE', type: 'Neural2' },
    { name: 'es-ES-Neural2-F', gender: 'MALE', type: 'Neural2' },
  ]},
  'Spanish (US)': { code: 'es-US', voices: [
    // Chirp voices
    { name: 'es-US-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'es-US-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'es-US-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'es-US-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'es-US-Neural2-C', gender: 'MALE', type: 'Neural2' },
  ]},
  'Spanish (Mexico)': { code: 'es-MX', voices: [
    { name: 'es-MX-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'es-MX-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'es-MX-Neural2-C', gender: 'FEMALE', type: 'Neural2' },
  ]},
  'French (France)': { code: 'fr-FR', voices: [
    // Chirp voices
    { name: 'fr-FR-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'fr-FR-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'fr-FR-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'fr-FR-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'fr-FR-Neural2-C', gender: 'FEMALE', type: 'Neural2' },
    { name: 'fr-FR-Neural2-D', gender: 'MALE', type: 'Neural2' },
    { name: 'fr-FR-Neural2-E', gender: 'FEMALE', type: 'Neural2' },
  ]},
  'French (Canada)': { code: 'fr-CA', voices: [
    // Chirp voices
    { name: 'fr-CA-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'fr-CA-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'fr-CA-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'fr-CA-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'fr-CA-Neural2-C', gender: 'FEMALE', type: 'Neural2' },
    { name: 'fr-CA-Neural2-D', gender: 'MALE', type: 'Neural2' },
  ]},
  'German': { code: 'de-DE', voices: [
    // Chirp voices
    { name: 'de-DE-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'de-DE-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'de-DE-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'de-DE-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'de-DE-Neural2-C', gender: 'FEMALE', type: 'Neural2' },
    { name: 'de-DE-Neural2-D', gender: 'MALE', type: 'Neural2' },
    { name: 'de-DE-Neural2-F', gender: 'FEMALE', type: 'Neural2' },
  ]},
  'Italian': { code: 'it-IT', voices: [
    // Chirp voices
    { name: 'it-IT-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'it-IT-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'it-IT-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'it-IT-Neural2-B', gender: 'FEMALE', type: 'Neural2' },
    { name: 'it-IT-Neural2-C', gender: 'MALE', type: 'Neural2' },
  ]},
  'Portuguese (Brazil)': { code: 'pt-BR', voices: [
    // Chirp voices
    { name: 'pt-BR-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'pt-BR-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'pt-BR-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'pt-BR-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'pt-BR-Neural2-C', gender: 'FEMALE', type: 'Neural2' },
  ]},
  'Portuguese (Portugal)': { code: 'pt-PT', voices: [
    // Chirp voices
    { name: 'pt-PT-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'pt-PT-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'pt-PT-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'pt-PT-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'pt-PT-Neural2-C', gender: 'MALE', type: 'Neural2' },
    { name: 'pt-PT-Neural2-D', gender: 'FEMALE', type: 'Neural2' },
  ]},
  'Japanese': { code: 'ja-JP', voices: [
    // Chirp voices
    { name: 'ja-JP-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'ja-JP-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'ja-JP-Neural2-B', gender: 'FEMALE', type: 'Neural2' },
    { name: 'ja-JP-Neural2-C', gender: 'MALE', type: 'Neural2' },
    { name: 'ja-JP-Neural2-D', gender: 'MALE', type: 'Neural2' },
  ]},
  'Korean': { code: 'ko-KR', voices: [
    // Chirp voices
    { name: 'ko-KR-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'ko-KR-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'ko-KR-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'ko-KR-Neural2-B', gender: 'FEMALE', type: 'Neural2' },
    { name: 'ko-KR-Neural2-C', gender: 'MALE', type: 'Neural2' },
  ]},
  'Chinese (Mandarin)': { code: 'cmn-CN', voices: [
    // Chirp voices
    { name: 'cmn-CN-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'cmn-CN-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Wavenet voices
    { name: 'cmn-CN-Wavenet-A', gender: 'FEMALE', type: 'Wavenet' },
    { name: 'cmn-CN-Wavenet-B', gender: 'MALE', type: 'Wavenet' },
    { name: 'cmn-CN-Wavenet-C', gender: 'MALE', type: 'Wavenet' },
    { name: 'cmn-CN-Wavenet-D', gender: 'FEMALE', type: 'Wavenet' },
  ]},
  'Chinese (Cantonese)': { code: 'yue-HK', voices: [
    { name: 'yue-HK-Standard-A', gender: 'FEMALE' },
    { name: 'yue-HK-Standard-B', gender: 'MALE' },
    { name: 'yue-HK-Standard-C', gender: 'FEMALE' },
    { name: 'yue-HK-Standard-D', gender: 'MALE' },
  ]},
  'Russian': { code: 'ru-RU', voices: [
    { name: 'ru-RU-Wavenet-A', gender: 'FEMALE' },
    { name: 'ru-RU-Wavenet-B', gender: 'MALE' },
    { name: 'ru-RU-Wavenet-C', gender: 'FEMALE' },
    { name: 'ru-RU-Wavenet-D', gender: 'MALE' },
    { name: 'ru-RU-Wavenet-E', gender: 'FEMALE' },
  ]},
  'Arabic': { code: 'ar-XA', voices: [
    { name: 'ar-XA-Wavenet-A', gender: 'FEMALE' },
    { name: 'ar-XA-Wavenet-B', gender: 'MALE' },
    { name: 'ar-XA-Wavenet-C', gender: 'MALE' },
    { name: 'ar-XA-Wavenet-D', gender: 'FEMALE' },
  ]},
  'Hindi': { code: 'hi-IN', voices: [
    // Chirp voices
    { name: 'hi-IN-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'hi-IN-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'hi-IN-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'hi-IN-Neural2-B', gender: 'MALE', type: 'Neural2' },
    { name: 'hi-IN-Neural2-C', gender: 'MALE', type: 'Neural2' },
    { name: 'hi-IN-Neural2-D', gender: 'FEMALE', type: 'Neural2' },
  ]},
  'Dutch': { code: 'nl-NL', voices: [
    { name: 'nl-NL-Wavenet-A', gender: 'FEMALE' },
    { name: 'nl-NL-Wavenet-B', gender: 'MALE' },
    { name: 'nl-NL-Wavenet-C', gender: 'MALE' },
    { name: 'nl-NL-Wavenet-D', gender: 'FEMALE' },
    { name: 'nl-NL-Wavenet-E', gender: 'FEMALE' },
  ]},
  'Swedish': { code: 'sv-SE', voices: [
    { name: 'sv-SE-Wavenet-A', gender: 'FEMALE' },
    { name: 'sv-SE-Wavenet-B', gender: 'FEMALE' },
    { name: 'sv-SE-Wavenet-C', gender: 'FEMALE' },
    { name: 'sv-SE-Wavenet-D', gender: 'MALE' },
    { name: 'sv-SE-Wavenet-E', gender: 'MALE' },
  ]},
  'Norwegian': { code: 'nb-NO', voices: [
    { name: 'nb-NO-Wavenet-A', gender: 'FEMALE' },
    { name: 'nb-NO-Wavenet-B', gender: 'MALE' },
    { name: 'nb-NO-Wavenet-C', gender: 'FEMALE' },
    { name: 'nb-NO-Wavenet-D', gender: 'MALE' },
    { name: 'nb-NO-Wavenet-E', gender: 'FEMALE' },
  ]},
  'Danish': { code: 'da-DK', voices: [
    { name: 'da-DK-Wavenet-A', gender: 'FEMALE' },
    { name: 'da-DK-Wavenet-C', gender: 'MALE' },
    { name: 'da-DK-Wavenet-D', gender: 'FEMALE' },
    { name: 'da-DK-Wavenet-E', gender: 'FEMALE' },
  ]},
  'Finnish': { code: 'fi-FI', voices: [
    { name: 'fi-FI-Wavenet-A', gender: 'FEMALE' },
  ]},
  'Polish': { code: 'pl-PL', voices: [
    { name: 'pl-PL-Wavenet-A', gender: 'FEMALE' },
    { name: 'pl-PL-Wavenet-B', gender: 'MALE' },
    { name: 'pl-PL-Wavenet-C', gender: 'MALE' },
    { name: 'pl-PL-Wavenet-D', gender: 'FEMALE' },
    { name: 'pl-PL-Wavenet-E', gender: 'FEMALE' },
  ]},
  'Turkish': { code: 'tr-TR', voices: [
    { name: 'tr-TR-Wavenet-A', gender: 'FEMALE' },
    { name: 'tr-TR-Wavenet-B', gender: 'MALE' },
    { name: 'tr-TR-Wavenet-C', gender: 'FEMALE' },
    { name: 'tr-TR-Wavenet-D', gender: 'FEMALE' },
    { name: 'tr-TR-Wavenet-E', gender: 'MALE' },
  ]},
  'Thai': { code: 'th-TH', voices: [
    // Chirp voices
    { name: 'th-TH-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'th-TH-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'th-TH-Neural2-C', gender: 'FEMALE', type: 'Neural2' },
  ]},
  'Vietnamese': { code: 'vi-VN', voices: [
    // Chirp voices
    { name: 'vi-VN-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'vi-VN-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Neural2 voices
    { name: 'vi-VN-Neural2-A', gender: 'FEMALE', type: 'Neural2' },
    { name: 'vi-VN-Neural2-D', gender: 'MALE', type: 'Neural2' },
  ]},
  'Indonesian': { code: 'id-ID', voices: [
    { name: 'id-ID-Wavenet-A', gender: 'FEMALE' },
    { name: 'id-ID-Wavenet-B', gender: 'MALE' },
    { name: 'id-ID-Wavenet-C', gender: 'MALE' },
    { name: 'id-ID-Wavenet-D', gender: 'FEMALE' },
  ]},
  'Greek': { code: 'el-GR', voices: [
    { name: 'el-GR-Wavenet-A', gender: 'FEMALE' },
  ]},
  'Hebrew': { code: 'he-IL', voices: [
    { name: 'he-IL-Wavenet-A', gender: 'FEMALE' },
    { name: 'he-IL-Wavenet-B', gender: 'MALE' },
    { name: 'he-IL-Wavenet-C', gender: 'FEMALE' },
    { name: 'he-IL-Wavenet-D', gender: 'MALE' },
  ]},
  'Czech': { code: 'cs-CZ', voices: [
    { name: 'cs-CZ-Wavenet-A', gender: 'FEMALE' },
  ]},
  'Romanian': { code: 'ro-RO', voices: [
    { name: 'ro-RO-Wavenet-A', gender: 'FEMALE' },
  ]},
  'Hungarian': { code: 'hu-HU', voices: [
    { name: 'hu-HU-Wavenet-A', gender: 'FEMALE' },
  ]},
  'Ukrainian': { code: 'uk-UA', voices: [
    { name: 'uk-UA-Wavenet-A', gender: 'FEMALE' },
  ]},
  'Bengali': { code: 'bn-IN', voices: [
    { name: 'bn-IN-Wavenet-A', gender: 'FEMALE' },
    { name: 'bn-IN-Wavenet-B', gender: 'MALE' },
  ]},
  'Tamil': { code: 'ta-IN', voices: [
    { name: 'ta-IN-Wavenet-A', gender: 'FEMALE' },
    { name: 'ta-IN-Wavenet-B', gender: 'MALE' },
    { name: 'ta-IN-Wavenet-C', gender: 'FEMALE' },
    { name: 'ta-IN-Wavenet-D', gender: 'MALE' },
  ]},
  'Telugu': { code: 'te-IN', voices: [
    { name: 'te-IN-Standard-A', gender: 'FEMALE' },
    { name: 'te-IN-Standard-B', gender: 'MALE' },
  ]},
  'Marathi': { code: 'mr-IN', voices: [
    { name: 'mr-IN-Wavenet-A', gender: 'FEMALE' },
    { name: 'mr-IN-Wavenet-B', gender: 'MALE' },
    { name: 'mr-IN-Wavenet-C', gender: 'FEMALE' },
  ]},
  'Gujarati': { code: 'gu-IN', voices: [
    { name: 'gu-IN-Wavenet-A', gender: 'FEMALE' },
    { name: 'gu-IN-Wavenet-B', gender: 'MALE' },
  ]},
  'Kannada': { code: 'kn-IN', voices: [
    { name: 'kn-IN-Wavenet-A', gender: 'FEMALE' },
    { name: 'kn-IN-Wavenet-B', gender: 'MALE' },
  ]},
  'Malayalam': { code: 'ml-IN', voices: [
    { name: 'ml-IN-Wavenet-A', gender: 'FEMALE' },
    { name: 'ml-IN-Wavenet-B', gender: 'MALE' },
  ]},
  'Filipino': { code: 'fil-PH', voices: [
    // Chirp voices
    { name: 'fil-PH-Chirp-HD-F', gender: 'FEMALE', type: 'Chirp HD' },
    { name: 'fil-PH-Chirp-HD-D', gender: 'MALE', type: 'Chirp HD' },
    // Wavenet voices
    { name: 'fil-PH-Wavenet-A', gender: 'FEMALE', type: 'Wavenet' },
    { name: 'fil-PH-Wavenet-B', gender: 'FEMALE', type: 'Wavenet' },
    { name: 'fil-PH-Wavenet-C', gender: 'MALE', type: 'Wavenet' },
    { name: 'fil-PH-Wavenet-D', gender: 'MALE', type: 'Wavenet' },
  ]},
  'Malay': { code: 'ms-MY', voices: [
    { name: 'ms-MY-Wavenet-A', gender: 'FEMALE' },
    { name: 'ms-MY-Wavenet-B', gender: 'MALE' },
    { name: 'ms-MY-Wavenet-C', gender: 'FEMALE' },
    { name: 'ms-MY-Wavenet-D', gender: 'MALE' },
  ]},
  'Catalan': { code: 'ca-ES', voices: [
    { name: 'ca-ES-Standard-A', gender: 'FEMALE' },
  ]},
  'Afrikaans': { code: 'af-ZA', voices: [
    { name: 'af-ZA-Standard-A', gender: 'FEMALE' },
  ]},
  'Bulgarian': { code: 'bg-BG', voices: [
    { name: 'bg-BG-Standard-A', gender: 'FEMALE' },
  ]},
  'Icelandic': { code: 'is-IS', voices: [
    { name: 'is-IS-Standard-A', gender: 'FEMALE' },
  ]},
  'Slovak': { code: 'sk-SK', voices: [
    { name: 'sk-SK-Wavenet-A', gender: 'FEMALE' },
  ]},
  'Serbian': { code: 'sr-RS', voices: [
    { name: 'sr-RS-Standard-A', gender: 'FEMALE' },
  ]},
  'Latvian': { code: 'lv-LV', voices: [
    { name: 'lv-LV-Standard-A', gender: 'MALE' },
  ]},
  'Lithuanian': { code: 'lt-LT', voices: [
    { name: 'lt-LT-Standard-A', gender: 'MALE' },
  ]},
  'Swahili': { code: 'sw-KE', voices: [
    { name: 'sw-KE-Standard-A', gender: 'FEMALE' },
  ]},
}

// Default test phrases by language
const DEFAULT_PHRASES: Record<string, string> = {
  'en-US': 'Hello! How are you doing today?',
  'en-GB': 'Hello! How are you doing today?',
  'en-AU': 'Hello! How are you doing today?',
  'es-ES': 'Hola! Como estas hoy?',
  'es-US': 'Hola! Como estas hoy?',
  'es-MX': 'Hola! Como estas hoy?',
  'fr-FR': 'Bonjour! Comment allez-vous?',
  'fr-CA': 'Bonjour! Comment allez-vous?',
  'de-DE': 'Hallo! Wie geht es Ihnen heute?',
  'it-IT': 'Ciao! Come stai oggi?',
  'pt-BR': 'Ola! Como voce esta hoje?',
  'pt-PT': 'Ola! Como voce esta hoje?',
  'ja-JP': 'Konnichiwa! Ogenki desu ka?',
  'ko-KR': 'Annyeonghaseyo! Jal jinaesyeosseoyo?',
  'cmn-CN': 'Ni hao! Ni jin tian zen me yang?',
  'ru-RU': 'Privet! Kak dela?',
  'ar-XA': 'Marhaba! Kaif halak?',
  'hi-IN': 'Namaste! Aap kaise hain?',
}

export default function VoicesPage() {
  const [voices, setVoices] = useState<Voice[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState<string | null>(null)
  const [editingVoice, setEditingVoice] = useState<Voice | null>(null)
  const [showAddForm, setShowAddForm] = useState(false)
  const [filter, setFilter] = useState('')

  // Voice preview state
  const [previewText, setPreviewText] = useState('Hello! How are you doing today?')
  const [previewLang, setPreviewLang] = useState('English (US)')
  const [previewVoice, setPreviewVoice] = useState('en-US-Neural2-J')
  const [previewRate, setPreviewRate] = useState(0.85)
  const [previewPlaying, setPreviewPlaying] = useState(false)
  const [previewError, setPreviewError] = useState<string | null>(null)
  const audioRef = useRef<HTMLAudioElement | null>(null)

  useEffect(() => {
    loadVoices()
  }, [])

  // Update default phrase when language changes
  useEffect(() => {
    const langCode = GOOGLE_VOICES[previewLang]?.code
    if (langCode && DEFAULT_PHRASES[langCode]) {
      setPreviewText(DEFAULT_PHRASES[langCode])
    }
  }, [previewLang])

  async function loadVoices() {
    try {
      setLoading(true)
      const response = await fetch('/api/voices')
      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to load voices')
      }

      setVoices(result.data || [])
    } catch (error) {
      console.error('Failed to load voices:', error)
    } finally {
      setLoading(false)
    }
  }

  async function playPreview(text?: string, voiceName?: string, langCode?: string, rate?: number) {
    const textToSpeak = text || previewText
    const voice = voiceName || previewVoice
    const code = langCode || GOOGLE_VOICES[previewLang]?.code || 'en-US'
    const speakingRate = rate ?? previewRate

    if (!textToSpeak.trim()) {
      setPreviewError('Please enter some text to preview')
      return
    }

    // Find the voice info to get gender
    let gender = 'NEUTRAL'
    for (const [, info] of Object.entries(GOOGLE_VOICES)) {
      const voiceInfo = info.voices.find(v => v.name === voice)
      if (voiceInfo) {
        gender = voiceInfo.gender
        break
      }
    }

    try {
      setPreviewPlaying(true)
      setPreviewError(null)

      // Stop any currently playing audio
      if (audioRef.current) {
        audioRef.current.pause()
        audioRef.current = null
      }

      const response = await fetch('/api/voices/preview', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text: textToSpeak,
          languageCode: code,
          voiceName: voice,
          speakingRate,
          pitch: 0,
          gender
        })
      })

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to generate preview')
      }

      // Play the audio
      const audioSrc = `data:audio/mp3;base64,${result.audioContent}`
      const audio = new Audio(audioSrc)
      audioRef.current = audio

      audio.onended = () => setPreviewPlaying(false)
      audio.onerror = () => {
        setPreviewError('Failed to play audio')
        setPreviewPlaying(false)
      }

      await audio.play()
    } catch (error) {
      console.error('Preview error:', error)
      setPreviewError(error instanceof Error ? error.message : 'Failed to generate preview')
      setPreviewPlaying(false)
    }
  }

  function stopPreview() {
    if (audioRef.current) {
      audioRef.current.pause()
      audioRef.current = null
    }
    setPreviewPlaying(false)
  }

  async function saveVoice(voice: Voice) {
    try {
      setSaving(voice.language_code)
      const response = await fetch('/api/voices', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(voice)
      })

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to save voice')
      }

      setVoices(prev => prev.map(v =>
        v.language_code === voice.language_code ? { ...voice, updated_at: new Date().toISOString() } : v
      ))
      setEditingVoice(null)
    } catch (error) {
      console.error('Failed to save voice:', error)
      alert('Failed to save voice configuration')
    } finally {
      setSaving(null)
    }
  }

  async function addVoice(voice: Voice) {
    try {
      setSaving('new')
      const response = await fetch('/api/voices', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(voice)
      })

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to add voice')
      }

      setVoices(prev => [...prev, result.data].sort((a, b) => a.language_name.localeCompare(b.language_name)))
      setShowAddForm(false)
    } catch (error) {
      console.error('Failed to add voice:', error)
      alert('Failed to add voice configuration')
    } finally {
      setSaving(null)
    }
  }

  async function deleteVoice(languageCode: string) {
    if (!confirm('Are you sure you want to delete this voice configuration?')) return

    try {
      setSaving(languageCode)
      const response = await fetch(`/api/voices?language_code=${languageCode}`, {
        method: 'DELETE'
      })

      if (!response.ok) {
        const result = await response.json()
        throw new Error(result.error || 'Failed to delete voice')
      }

      setVoices(prev => prev.filter(v => v.language_code !== languageCode))
    } catch (error) {
      console.error('Failed to delete voice:', error)
      alert('Failed to delete voice configuration')
    } finally {
      setSaving(null)
    }
  }

  async function toggleEnabled(voice: Voice) {
    await saveVoice({ ...voice, enabled: !voice.enabled })
  }

  const filteredVoices = voices.filter(v =>
    v.language_name.toLowerCase().includes(filter.toLowerCase()) ||
    v.language_code.toLowerCase().includes(filter.toLowerCase()) ||
    v.google_voice_name.toLowerCase().includes(filter.toLowerCase())
  )

  const previewVoices = GOOGLE_VOICES[previewLang]?.voices || []

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-xl text-gray-500">Loading voices...</div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">TTS Voice Configuration</h2>
          <p className="text-gray-600 mt-1">
            Configure Google Cloud TTS voices for each language. Test voices below before applying.
          </p>
        </div>
        <button
          onClick={() => setShowAddForm(true)}
          className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
        >
          + Add Language
        </button>
      </div>

      {/* Voice Preview Section */}
      <div className="bg-gradient-to-r from-blue-50 to-indigo-50 border-2 border-blue-200 rounded-lg p-6">
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <span className="text-2xl">🔊</span> Voice Preview
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
          {/* Language Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Language</label>
            <select
              value={previewLang}
              onChange={(e) => {
                setPreviewLang(e.target.value)
                const info = GOOGLE_VOICES[e.target.value]
                if (info?.voices.length) {
                  setPreviewVoice(info.voices[0].name)
                }
              }}
              className="w-full border rounded px-3 py-2"
            >
              {Object.keys(GOOGLE_VOICES).sort().map(lang => (
                <option key={lang} value={lang}>{lang}</option>
              ))}
            </select>
          </div>

          {/* Voice Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Voice</label>
            <select
              value={previewVoice}
              onChange={(e) => setPreviewVoice(e.target.value)}
              className="w-full border rounded px-3 py-2 font-mono text-sm"
            >
              {previewVoices.map(v => (
                <option key={v.name} value={v.name}>
                  {v.type ? `[${v.type}] ` : ''}{v.name.split('-').slice(-1)[0]} ({v.gender})
                </option>
              ))}
            </select>
            <div className="text-xs text-gray-500 mt-1">
              Full name: <span className="font-mono">{previewVoice}</span>
            </div>
          </div>

          {/* Speed */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Speed ({previewRate}x)
            </label>
            <input
              type="range"
              min="0.5"
              max="1.5"
              step="0.05"
              value={previewRate}
              onChange={(e) => setPreviewRate(parseFloat(e.target.value))}
              className="w-full mt-2"
            />
          </div>

          {/* Play Button */}
          <div className="flex items-end">
            <button
              onClick={() => previewPlaying ? stopPreview() : playPreview()}
              disabled={!previewText.trim()}
              className={`w-full px-4 py-2 rounded font-semibold flex items-center justify-center gap-2 ${
                previewPlaying
                  ? 'bg-red-500 text-white hover:bg-red-600'
                  : 'bg-blue-600 text-white hover:bg-blue-700'
              } disabled:bg-gray-400`}
            >
              {previewPlaying ? (
                <>
                  <span>⏹</span> Stop
                </>
              ) : (
                <>
                  <span>▶</span> Play Preview
                </>
              )}
            </button>
          </div>
        </div>

        {/* Text Input */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Test Phrase</label>
          <textarea
            value={previewText}
            onChange={(e) => setPreviewText(e.target.value)}
            placeholder="Enter text to preview..."
            rows={2}
            className="w-full border rounded px-3 py-2"
          />
        </div>

        {previewError && (
          <div className="mt-2 text-red-600 text-sm">{previewError}</div>
        )}
      </div>

      {/* Search/Filter */}
      <div className="flex gap-4 items-center">
        <input
          type="text"
          placeholder="Search languages..."
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="border rounded px-3 py-2 w-64"
        />
        <span className="text-gray-500">
          {filteredVoices.length} of {voices.length} languages
        </span>
      </div>

      {/* Add Form */}
      {showAddForm && (
        <VoiceForm
          voice={null}
          onSave={addVoice}
          onCancel={() => setShowAddForm(false)}
          saving={saving === 'new'}
          existingCodes={voices.map(v => v.language_code)}
          onPreview={playPreview}
        />
      )}

      {/* Voice List */}
      <div className="grid gap-4">
        {filteredVoices.map((voice) => (
          <div key={voice.language_code} className={`border rounded-lg p-4 ${voice.enabled ? 'bg-white' : 'bg-gray-100'}`}>
            {editingVoice?.language_code === voice.language_code ? (
              <VoiceForm
                voice={editingVoice}
                onSave={saveVoice}
                onCancel={() => setEditingVoice(null)}
                saving={saving === voice.language_code}
                existingCodes={voices.map(v => v.language_code)}
                onPreview={playPreview}
              />
            ) : (
              <div className="flex justify-between items-start">
                <div className="flex-1">
                  <div className="flex items-center gap-3">
                    <h3 className="text-lg font-semibold">{voice.language_name}</h3>
                    <span className="text-sm bg-gray-200 px-2 py-0.5 rounded">{voice.language_code}</span>
                    <span className={`text-sm px-2 py-0.5 rounded ${
                      voice.voice_gender === 'MALE' ? 'bg-blue-100 text-blue-700' :
                      voice.voice_gender === 'FEMALE' ? 'bg-pink-100 text-pink-700' :
                      'bg-gray-100 text-gray-700'
                    }`}>
                      {voice.voice_gender === 'MALE' ? '♂ Male' : voice.voice_gender === 'FEMALE' ? '♀ Female' : '⚪ Neutral'}
                    </span>
                    {!voice.enabled && (
                      <span className="text-sm bg-red-100 text-red-700 px-2 py-0.5 rounded">Disabled</span>
                    )}
                  </div>
                  <div className="mt-2 grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div>
                      <span className="text-gray-500">Voice:</span>
                      <div className="font-mono">{voice.google_voice_name}</div>
                    </div>
                    <div>
                      <span className="text-gray-500">Language Code:</span>
                      <div className="font-mono">{voice.google_language_code}</div>
                    </div>
                    <div>
                      <span className="text-gray-500">Speed:</span>
                      <div>{voice.speaking_rate}x</div>
                    </div>
                  </div>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => playPreview(
                      DEFAULT_PHRASES[voice.google_language_code] || 'Hello, how are you?',
                      voice.google_voice_name,
                      voice.google_language_code,
                      voice.speaking_rate
                    )}
                    disabled={previewPlaying}
                    className="bg-purple-100 text-purple-700 px-3 py-1 rounded text-sm hover:bg-purple-200 disabled:opacity-50"
                    title="Preview this voice"
                  >
                    ▶ Test
                  </button>
                  <button
                    onClick={() => toggleEnabled(voice)}
                    disabled={saving === voice.language_code}
                    className={`px-3 py-1 rounded text-sm ${
                      voice.enabled
                        ? 'bg-yellow-100 text-yellow-700 hover:bg-yellow-200'
                        : 'bg-green-100 text-green-700 hover:bg-green-200'
                    }`}
                  >
                    {voice.enabled ? 'Disable' : 'Enable'}
                  </button>
                  <button
                    onClick={() => setEditingVoice(voice)}
                    disabled={saving === voice.language_code}
                    className="bg-blue-100 text-blue-700 px-3 py-1 rounded text-sm hover:bg-blue-200"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => deleteVoice(voice.language_code)}
                    disabled={saving === voice.language_code}
                    className="bg-red-100 text-red-700 px-3 py-1 rounded text-sm hover:bg-red-200"
                  >
                    Delete
                  </button>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>

      {filteredVoices.length === 0 && !showAddForm && (
        <div className="text-center py-8 text-gray-500">
          {filter ? 'No languages match your search' : 'No voice configurations yet. Add one to get started.'}
        </div>
      )}
    </div>
  )
}

// Voice Form Component
function VoiceForm({
  voice,
  onSave,
  onCancel,
  saving,
  existingCodes,
  onPreview
}: {
  voice: Voice | null
  onSave: (voice: Voice) => void
  onCancel: () => void
  saving: boolean
  existingCodes: string[]
  onPreview: (text?: string, voiceName?: string, langCode?: string, rate?: number) => void
}) {
  const isNew = !voice
  const [form, setForm] = useState<Voice>(voice || {
    language_code: '',
    language_name: '',
    google_language_code: 'en-US',
    google_voice_name: 'en-US-Neural2-J',
    voice_gender: 'NEUTRAL',
    speaking_rate: 0.85,
    pitch: 0,
    enabled: true
  })

  const [selectedGoogleLang, setSelectedGoogleLang] = useState(() => {
    for (const [name, info] of Object.entries(GOOGLE_VOICES)) {
      if (info.voices.some(v => v.name === form.google_voice_name)) {
        return name
      }
    }
    return 'English (US)'
  })

  const availableVoices = GOOGLE_VOICES[selectedGoogleLang]?.voices || []

  function handleGoogleLangChange(langName: string) {
    setSelectedGoogleLang(langName)
    const info = GOOGLE_VOICES[langName]
    if (info) {
      const firstVoice = info.voices[0]
      setForm(prev => ({
        ...prev,
        google_language_code: info.code,
        google_voice_name: firstVoice.name,
        voice_gender: firstVoice.gender as Voice['voice_gender']
      }))
    }
  }

  function handleVoiceChange(voiceName: string) {
    const voiceInfo = availableVoices.find(v => v.name === voiceName)
    setForm(prev => ({
      ...prev,
      google_voice_name: voiceName,
      voice_gender: (voiceInfo?.gender || 'NEUTRAL') as Voice['voice_gender']
    }))
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()

    if (!form.language_code || !form.language_name) {
      alert('Language code and name are required')
      return
    }

    if (isNew && existingCodes.includes(form.language_code)) {
      alert('A voice configuration with this language code already exists')
      return
    }

    onSave(form)
  }

  return (
    <form onSubmit={handleSubmit} className="bg-gray-50 p-4 rounded-lg border-2 border-blue-200">
      <h4 className="font-semibold mb-4">{isNew ? 'Add New Language' : 'Edit Voice Configuration'}</h4>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        {/* Language Code */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Language Code *
          </label>
          <input
            type="text"
            value={form.language_code}
            onChange={(e) => setForm(prev => ({ ...prev, language_code: e.target.value.toLowerCase() }))}
            disabled={!isNew}
            placeholder="e.g., en, es, fr"
            className="w-full border rounded px-3 py-2 disabled:bg-gray-200"
            required
          />
        </div>

        {/* Language Name */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Display Name *
          </label>
          <input
            type="text"
            value={form.language_name}
            onChange={(e) => setForm(prev => ({ ...prev, language_name: e.target.value }))}
            placeholder="e.g., English, Spanish"
            className="w-full border rounded px-3 py-2"
            required
          />
        </div>

        {/* Google Language */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Google TTS Language
          </label>
          <select
            value={selectedGoogleLang}
            onChange={(e) => handleGoogleLangChange(e.target.value)}
            className="w-full border rounded px-3 py-2"
          >
            {Object.keys(GOOGLE_VOICES).sort().map(lang => (
              <option key={lang} value={lang}>{lang}</option>
            ))}
          </select>
        </div>

        {/* Voice Selection */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Voice
          </label>
          <select
            value={form.google_voice_name}
            onChange={(e) => handleVoiceChange(e.target.value)}
            className="w-full border rounded px-3 py-2 font-mono text-sm"
          >
            {availableVoices.map(v => (
              <option key={v.name} value={v.name}>
                {v.type ? `[${v.type}] ` : ''}{v.name.split('-').slice(-1)[0]} ({v.gender})
              </option>
            ))}
          </select>
          <div className="text-xs text-gray-500 mt-1">
            Full: <span className="font-mono">{form.google_voice_name}</span>
          </div>
        </div>

        {/* Gender (auto-filled but editable) */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Gender
          </label>
          <select
            value={form.voice_gender}
            onChange={(e) => setForm(prev => ({ ...prev, voice_gender: e.target.value as Voice['voice_gender'] }))}
            className="w-full border rounded px-3 py-2"
          >
            <option value="NEUTRAL">Neutral</option>
            <option value="FEMALE">Female</option>
            <option value="MALE">Male</option>
          </select>
        </div>

        {/* Speaking Rate */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Speed ({form.speaking_rate}x)
          </label>
          <input
            type="range"
            min="0.5"
            max="1.5"
            step="0.05"
            value={form.speaking_rate}
            onChange={(e) => setForm(prev => ({ ...prev, speaking_rate: parseFloat(e.target.value) }))}
            className="w-full"
          />
          <div className="flex justify-between text-xs text-gray-500">
            <span>Slower</span>
            <span>Faster</span>
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-2 mt-4">
        <button
          type="button"
          onClick={() => onPreview(
            DEFAULT_PHRASES[form.google_language_code] || 'Hello, how are you?',
            form.google_voice_name,
            form.google_language_code,
            form.speaking_rate
          )}
          className="bg-purple-600 text-white px-4 py-2 rounded hover:bg-purple-700"
        >
          ▶ Preview Voice
        </button>
        <button
          type="submit"
          disabled={saving}
          className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:bg-blue-400"
        >
          {saving ? 'Saving...' : isNew ? 'Add Language' : 'Save Changes'}
        </button>
        <button
          type="button"
          onClick={onCancel}
          disabled={saving}
          className="bg-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-400"
        >
          Cancel
        </button>
      </div>
    </form>
  )
}
