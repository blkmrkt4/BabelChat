import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabase = createClient(supabaseUrl, supabaseKey)

interface ImportRow {
  string_key: string
  context?: string
  language_code: string
  value: string
  source?: string
  verified?: boolean
}

// POST - Import translations in bulk
export async function POST(request: Request) {
  try {
    const { translations, overwrite = false }: { translations: ImportRow[]; overwrite: boolean } = await request.json()

    if (!translations || !Array.isArray(translations) || translations.length === 0) {
      return NextResponse.json({ error: 'translations array is required' }, { status: 400 })
    }

    // Validate required fields
    for (const t of translations) {
      if (!t.string_key || !t.language_code || !t.value) {
        return NextResponse.json({
          error: 'Each translation must have string_key, language_code, and value'
        }, { status: 400 })
      }
    }

    let imported = 0
    let skipped = 0
    let errors: string[] = []

    for (const t of translations) {
      try {
        if (overwrite) {
          // Upsert - will update if exists
          const { error } = await supabase
            .from('app_translations')
            .upsert({
              string_key: t.string_key,
              context: t.context || null,
              language_code: t.language_code,
              value: t.value,
              source: t.source || 'imported',
              verified: t.verified ?? false,
            }, {
              onConflict: 'string_key,language_code'
            })

          if (error) {
            errors.push(`${t.string_key}/${t.language_code}: ${error.message}`)
          } else {
            imported++
          }
        } else {
          // Insert only - skip if exists
          const { error } = await supabase
            .from('app_translations')
            .insert({
              string_key: t.string_key,
              context: t.context || null,
              language_code: t.language_code,
              value: t.value,
              source: t.source || 'imported',
              verified: t.verified ?? false,
            })

          if (error) {
            if (error.code === '23505') { // Unique violation
              skipped++
            } else {
              errors.push(`${t.string_key}/${t.language_code}: ${error.message}`)
            }
          } else {
            imported++
          }
        }
      } catch (e) {
        errors.push(`${t.string_key}/${t.language_code}: ${e}`)
      }
    }

    return NextResponse.json({
      success: true,
      imported,
      skipped,
      errors: errors.length > 0 ? errors : undefined,
    })
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to import translations' }, { status: 500 })
  }
}
