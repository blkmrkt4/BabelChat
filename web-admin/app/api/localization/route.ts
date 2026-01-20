import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabase = createClient(supabaseUrl, supabaseKey)

// GET - Fetch translations with optional filters
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const languageCode = searchParams.get('language_code')
    const stringKey = searchParams.get('string_key')
    const verified = searchParams.get('verified')

    let query = supabase
      .from('app_translations')
      .select('*')
      .order('string_key', { ascending: true })

    if (languageCode) {
      query = query.eq('language_code', languageCode)
    }

    if (stringKey) {
      query = query.eq('string_key', stringKey)
    }

    if (verified !== null && verified !== undefined) {
      query = query.eq('verified', verified === 'true')
    }

    const { data, error } = await query

    if (error) {
      console.error('Error fetching translations:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to fetch translations' }, { status: 500 })
  }
}

// POST - Create a new translation
export async function POST(request: Request) {
  try {
    const translation = await request.json()

    const { data, error } = await supabase
      .from('app_translations')
      .insert({
        string_key: translation.string_key,
        context: translation.context || null,
        language_code: translation.language_code,
        value: translation.value,
        source: translation.source || 'human',
        verified: translation.verified ?? false,
      })
      .select()
      .single()

    if (error) {
      console.error('Error creating translation:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to create translation' }, { status: 500 })
  }
}

// PUT - Update an existing translation
export async function PUT(request: Request) {
  try {
    const translation = await request.json()

    if (!translation.id) {
      return NextResponse.json({ error: 'id is required' }, { status: 400 })
    }

    const { data, error } = await supabase
      .from('app_translations')
      .update({
        value: translation.value,
        source: translation.source || 'human',
        verified: translation.verified ?? false,
        context: translation.context,
      })
      .eq('id', translation.id)
      .select()
      .single()

    if (error) {
      console.error('Error updating translation:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to update translation' }, { status: 500 })
  }
}

// DELETE - Delete a translation
export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const id = searchParams.get('id')

    if (!id) {
      return NextResponse.json({ error: 'id is required' }, { status: 400 })
    }

    const { error } = await supabase
      .from('app_translations')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Error deleting translation:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error:', error)
    return NextResponse.json({ error: 'Failed to delete translation' }, { status: 500 })
  }
}
