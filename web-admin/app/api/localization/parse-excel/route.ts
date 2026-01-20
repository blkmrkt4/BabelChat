import { NextResponse } from 'next/server'
import * as XLSX from 'xlsx'

// POST - Parse an Excel file and return translations JSON
export async function POST(request: Request) {
  try {
    const formData = await request.formData()
    const file = formData.get('file') as File

    if (!file) {
      return NextResponse.json({ error: 'No file provided' }, { status: 400 })
    }

    // Read the file
    const arrayBuffer = await file.arrayBuffer()
    const workbook = XLSX.read(arrayBuffer, { type: 'array' })

    // Get the first sheet
    const sheetName = workbook.SheetNames[0]
    const sheet = workbook.Sheets[sheetName]

    // Convert to JSON (array of arrays)
    const data = XLSX.utils.sheet_to_json(sheet, { header: 1 }) as any[][]

    if (data.length < 2) {
      return NextResponse.json({ error: 'Excel file appears to be empty' }, { status: 400 })
    }

    // Parse headers to find column indices
    const headers = data[0] as string[]

    // Find key columns (flexible matching)
    const keyCol = headers.findIndex(h =>
      h && (h.toLowerCase().includes('key') || h.toLowerCase().includes('string'))
    )
    const contextCol = headers.findIndex(h =>
      h && (h.toLowerCase().includes('context') || h.toLowerCase().includes('description'))
    )
    const englishCol = headers.findIndex(h =>
      h && (h.toLowerCase().includes('english') || h.toLowerCase() === 'en')
    )

    if (keyCol === -1 || englishCol === -1) {
      return NextResponse.json({
        error: 'Could not find required columns. Need "String Key" and "English" columns.',
        foundHeaders: headers.slice(0, 10)
      }, { status: 400 })
    }

    // Parse rows
    const translations: Array<{
      string_key: string
      context: string | null
      language_code: string
      value: string
      source: string
      verified: boolean
    }> = []

    for (let i = 1; i < data.length; i++) {
      const row = data[i]
      const stringKey = row[keyCol]
      const englishValue = row[englishCol]
      const context = contextCol !== -1 ? row[contextCol] : null

      // Skip empty rows or section headers
      if (!stringKey || !englishValue) continue

      // Skip section headers (typically all caps with no English value or context)
      if (typeof stringKey === 'string' && stringKey === stringKey.toUpperCase() && !context) {
        continue
      }

      translations.push({
        string_key: String(stringKey).trim(),
        context: context ? String(context).trim() : null,
        language_code: 'en',
        value: String(englishValue).trim(),
        source: 'human',
        verified: true
      })
    }

    return NextResponse.json({
      success: true,
      count: translations.length,
      translations,
      headers: headers.slice(0, 10), // Return first 10 headers for debugging
    })

  } catch (error) {
    console.error('Error parsing Excel:', error)
    return NextResponse.json({
      error: 'Failed to parse Excel file',
      details: error instanceof Error ? error.message : String(error)
    }, { status: 500 })
  }
}
