import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Use service role key to bypass RLS
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

// Delete a photo from user's profile
export async function DELETE(request: Request) {
  try {
    const { reportId, userId, photoUrl } = await request.json()

    if (!userId || !photoUrl) {
      return NextResponse.json({ error: 'Missing userId or photoUrl' }, { status: 400 })
    }

    // Get current profile photos
    const { data: profile, error: fetchError } = await supabase
      .from('profiles')
      .select('profile_photos')
      .eq('id', userId)
      .single()

    if (fetchError) {
      console.error('Error fetching profile:', fetchError)
      return NextResponse.json({ error: fetchError.message }, { status: 500 })
    }

    // Remove the photo from the array
    const currentPhotos = profile?.profile_photos || []
    const updatedPhotos = currentPhotos.filter((p: string) => p !== photoUrl)

    // Update profile with remaining photos
    const { error: updateError } = await supabase
      .from('profiles')
      .update({ profile_photos: updatedPhotos })
      .eq('id', userId)

    if (updateError) {
      console.error('Error updating profile:', updateError)
      return NextResponse.json({ error: updateError.message }, { status: 500 })
    }

    // Mark the report as resolved if reportId provided
    if (reportId) {
      await supabase
        .from('reported_users')
        .update({
          status: 'resolved',
          reviewed_at: new Date().toISOString()
        })
        .eq('id', reportId)
    }

    return NextResponse.json({
      success: true,
      message: 'Photo deleted successfully',
      remainingPhotos: updatedPhotos.length
    })
  } catch (error) {
    console.error('Delete photo error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

export async function GET() {
  try {
    const { data, error } = await supabase
      .from('reported_users')
      .select(`
        *,
        reporter:profiles!reported_users_reporter_id_fkey(id, first_name, last_name, profile_photos),
        reported:profiles!reported_users_reported_id_fkey(id, first_name, last_name, profile_photos)
      `)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error fetching reports:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Reports API error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json()

    const { data, error } = await supabase
      .from('reported_users')
      .insert(body)
      .select()
      .single()

    if (error) {
      console.error('Error inserting report:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Reports POST error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

export async function PATCH(request: Request) {
  try {
    const { reportId, status } = await request.json()

    if (!reportId || !status) {
      return NextResponse.json({ error: 'Missing reportId or status' }, { status: 400 })
    }

    const { error } = await supabase
      .from('reported_users')
      .update({
        status,
        reviewed_at: status !== 'pending' ? new Date().toISOString() : null
      })
      .eq('id', reportId)

    if (error) {
      console.error('Error updating report:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Reports PATCH error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}
