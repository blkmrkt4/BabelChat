import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabase = createClient(supabaseUrl, supabaseKey)

// GET - Export translations in various formats
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const format = searchParams.get('format') || 'json'
    const languageCode = searchParams.get('language_code')

    // Fetch all translations with pagination to avoid row limit
    let allData: Translation[] = []
    let offset = 0
    const limit = 1000

    while (true) {
      let query = supabase
        .from('app_translations')
        .select('*')
        .order('string_key', { ascending: true })
        .range(offset, offset + limit - 1)

      if (languageCode) {
        query = query.eq('language_code', languageCode)
      }

      const { data, error } = await query

      if (error) {
        console.error('Error fetching translations:', error)
        return NextResponse.json({ error: error.message }, { status: 500 })
      }

      if (!data || data.length === 0) break
      allData = allData.concat(data)
      if (data.length < limit) break
      offset += limit
    }

    const data = allData

    switch (format) {
      case 'xcstrings': {
        // Generate Apple String Catalog format
        const xcstrings = generateXCStrings(data || [], languageCode)
        return new NextResponse(JSON.stringify(xcstrings, null, 2), {
          headers: {
            'Content-Type': 'application/json',
            'Content-Disposition': `attachment; filename="Localizable.xcstrings"`,
          },
        })
      }

      case 'csv': {
        // Generate CSV format
        const csv = generateCSV(data || [])
        return new NextResponse(csv, {
          headers: {
            'Content-Type': 'text/csv',
            'Content-Disposition': `attachment; filename="translations${languageCode ? `_${languageCode}` : ''}.csv"`,
          },
        })
      }

      case 'json':
      default: {
        // Standard JSON export
        return NextResponse.json({ data })
      }
    }
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to export translations' }, { status: 500 })
  }
}

interface Translation {
  string_key: string
  context?: string
  language_code: string
  value: string
  source?: string
  verified?: boolean
}

// Generate Apple String Catalog format (.xcstrings)
function generateXCStrings(translations: Translation[], filterLanguage?: string | null) {
  const strings: Record<string, {
    comment?: string
    extractionState?: string
    localizations: Record<string, { stringUnit: { state: string; value: string } }>
  }> = {}

  // Group translations by string_key
  const grouped: Record<string, Translation[]> = {}
  for (const t of translations) {
    if (!grouped[t.string_key]) {
      grouped[t.string_key] = []
    }
    grouped[t.string_key].push(t)
  }

  // Build xcstrings structure
  for (const [key, items] of Object.entries(grouped)) {
    const firstItem = items[0]
    strings[key] = {
      comment: firstItem.context || undefined,
      extractionState: 'manual',
      localizations: {},
    }

    for (const item of items) {
      strings[key].localizations[item.language_code] = {
        stringUnit: {
          state: item.verified ? 'translated' : 'needs_review',
          value: item.value,
        },
      }
    }
  }

  return {
    sourceLanguage: 'en',
    strings,
    version: '1.0',
  }
}

// Generate CSV format
function generateCSV(translations: Translation[]) {
  const headers = ['string_key', 'context', 'language_code', 'value', 'source', 'verified']
  const rows = [headers.join(',')]

  for (const t of translations) {
    const row = [
      escapeCSV(t.string_key),
      escapeCSV(t.context || ''),
      escapeCSV(t.language_code),
      escapeCSV(t.value),
      escapeCSV(t.source || ''),
      t.verified ? 'true' : 'false',
    ]
    rows.push(row.join(','))
  }

  return rows.join('\n')
}

function escapeCSV(str: string): string {
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`
  }
  return str
}
