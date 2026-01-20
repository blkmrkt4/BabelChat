import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabase = createClient(supabaseUrl, supabaseKey)

// GET - Fetch translation statistics by language
export async function GET() {
  try {
    // Get total count of English strings (our source)
    const { count: totalStrings, error: countError } = await supabase
      .from('app_translations')
      .select('*', { count: 'exact', head: true })
      .eq('language_code', 'en')

    if (countError) {
      console.error('Error fetching total count:', countError)
      return NextResponse.json({ error: countError.message }, { status: 500 })
    }

    // Get all distinct language codes
    const { data: languages, error: langError } = await supabase
      .from('app_translations')
      .select('language_code')

    if (langError) {
      console.error('Error fetching languages:', langError)
      return NextResponse.json({ error: langError.message }, { status: 500 })
    }

    // Get unique language codes
    const uniqueLanguages = [...new Set(languages?.map(l => l.language_code) || [])]

    // Get counts for each language
    const stats: Record<string, { total: number; verified: number }> = {}

    for (const langCode of uniqueLanguages) {
      // Get total count for this language
      const { count: total } = await supabase
        .from('app_translations')
        .select('*', { count: 'exact', head: true })
        .eq('language_code', langCode)

      // Get verified count for this language
      const { count: verified } = await supabase
        .from('app_translations')
        .select('*', { count: 'exact', head: true })
        .eq('language_code', langCode)
        .eq('verified', true)

      stats[langCode] = {
        total: total || 0,
        verified: verified || 0,
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
