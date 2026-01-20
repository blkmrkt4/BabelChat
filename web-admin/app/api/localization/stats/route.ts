import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabase = createClient(supabaseUrl, supabaseKey)

// GET - Fetch translation statistics by language
export async function GET() {
  try {
    // Get all translations
    const { data: translations, error } = await supabase
      .from('app_translations')
      .select('language_code, verified')

    if (error) {
      console.error('Error fetching translation stats:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    // Get unique string keys to know total count
    const { data: uniqueKeys, error: keysError } = await supabase
      .from('app_translations')
      .select('string_key')

    if (keysError) {
      console.error('Error fetching unique keys:', keysError)
      return NextResponse.json({ error: keysError.message }, { status: 500 })
    }

    // Count unique string keys
    const uniqueKeySet = new Set(uniqueKeys?.map(k => k.string_key) || [])
    const totalStrings = uniqueKeySet.size

    // Group by language
    const stats: Record<string, { total: number; verified: number }> = {}

    for (const t of translations || []) {
      if (!stats[t.language_code]) {
        stats[t.language_code] = { total: 0, verified: 0 }
      }
      stats[t.language_code].total++
      if (t.verified) {
        stats[t.language_code].verified++
      }
    }

    // Get list of supported languages from tts_voices
    const { data: voices } = await supabase
      .from('tts_voices')
      .select('language_code, language_name')
      .eq('enabled', true)

    return NextResponse.json({
      totalStrings,
      languageStats: stats,
      supportedLanguages: voices || [],
    })
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to fetch translation stats' }, { status: 500 })
  }
}
