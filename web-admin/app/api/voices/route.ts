import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabase = createClient(supabaseUrl, supabaseKey)

// Derive male/female voice names from the selected voice
function deriveGenderedVoices(voiceName: string, langCode: string): { male: string; female: string } {
  // For Chirp HD voices, use D for male and F for female
  if (voiceName.includes('Chirp-HD-')) {
    const base = voiceName.replace(/Chirp-HD-[A-Z]$/, 'Chirp-HD-')
    return {
      male: base + 'D',
      female: base + 'F'
    }
  }

  // For Chirp3 HD voices (named voices like Charon, Kore), keep as-is
  if (voiceName.includes('Chirp3-HD-')) {
    return { male: voiceName, female: voiceName }
  }

  // For Neural2/Wavenet voices, try to find male/female variants
  // Common pattern: voices ending in A, C, E are often female; B, D, F are often male
  // But this varies by language, so just use the selected voice for both
  return { male: voiceName, female: voiceName }
}

export async function GET() {
  try {
    const { data, error } = await supabase
      .from('tts_voices')
      .select('*')
      .order('language_name', { ascending: true })

    if (error) {
      console.error('Error fetching voices:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to fetch voices' }, { status: 500 })
  }
}

export async function PUT(request: Request) {
  try {
    const voice = await request.json()

    // Auto-derive male/female voices from the main voice selection
    const genderedVoices = deriveGenderedVoices(voice.google_voice_name, voice.google_language_code)

    const { data, error } = await supabase
      .from('tts_voices')
      .upsert({
        language_code: voice.language_code,
        language_name: voice.language_name,
        google_language_code: voice.google_language_code,
        google_voice_name: voice.google_voice_name,
        voice_gender: voice.voice_gender || 'NEUTRAL',
        speaking_rate: voice.speaking_rate || 0.85,
        pitch: voice.pitch || 0,
        enabled: voice.enabled ?? true,
        male_voice_name: voice.male_voice_name || genderedVoices.male,
        female_voice_name: voice.female_voice_name || genderedVoices.female,
        // Muse configuration
        male_muse_name: voice.male_muse_name || null,
        female_muse_name: voice.female_muse_name || null,
        is_muse_language: voice.is_muse_language ?? false,
        updated_at: new Date().toISOString()
      })
      .select()
      .single()

    if (error) {
      console.error('Error updating voice:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to update voice' }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const voice = await request.json()

    // Auto-derive male/female voices from the main voice selection
    const genderedVoices = deriveGenderedVoices(voice.google_voice_name, voice.google_language_code)

    const { data, error } = await supabase
      .from('tts_voices')
      .insert({
        language_code: voice.language_code,
        language_name: voice.language_name,
        google_language_code: voice.google_language_code,
        google_voice_name: voice.google_voice_name,
        voice_gender: voice.voice_gender || 'NEUTRAL',
        speaking_rate: voice.speaking_rate || 0.85,
        pitch: voice.pitch || 0,
        enabled: voice.enabled ?? true,
        male_voice_name: voice.male_voice_name || genderedVoices.male,
        female_voice_name: voice.female_voice_name || genderedVoices.female,
        // Muse configuration
        male_muse_name: voice.male_muse_name || null,
        female_muse_name: voice.female_muse_name || null,
        is_muse_language: voice.is_muse_language ?? false
      })
      .select()
      .single()

    if (error) {
      console.error('Error creating voice:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to create voice' }, { status: 500 })
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const languageCode = searchParams.get('language_code')

    if (!languageCode) {
      return NextResponse.json({ error: 'language_code required' }, { status: 400 })
    }

    const { error } = await supabase
      .from('tts_voices')
      .delete()
      .eq('language_code', languageCode)

    if (error) {
      console.error('Error deleting voice:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to delete voice' }, { status: 500 })
  }
}
