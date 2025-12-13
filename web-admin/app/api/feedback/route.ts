import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Use service role key to bypass RLS
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export async function GET() {
  try {
    // First get all feedback
    const { data: feedbackData, error } = await supabase
      .from('feedback')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error fetching feedback:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    // Get unique user IDs
    const userIds = [...new Set(feedbackData?.filter(f => f.user_id).map(f => f.user_id))]

    // Fetch user profiles if there are any user IDs
    let userMap: Record<string, { id: string; first_name: string; last_name: string; profile_photos: string[] }> = {}
    if (userIds.length > 0) {
      const { data: users } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, profile_photos')
        .in('id', userIds)

      if (users) {
        userMap = users.reduce((acc, user) => {
          acc[user.id] = user
          return acc
        }, {} as typeof userMap)
      }
    }

    // Combine feedback with user data
    const data = feedbackData?.map(f => ({
      ...f,
      user: f.user_id ? userMap[f.user_id] || null : null
    }))

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Feedback API error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json()

    // Validate required fields
    if (!body.type || !body.message) {
      return NextResponse.json(
        { error: 'Missing required fields: type and message' },
        { status: 400 }
      )
    }

    const { data, error } = await supabase
      .from('feedback')
      .insert({
        user_id: body.user_id || null,
        type: body.type, // 'feature_request', 'bug_report', 'general'
        message: body.message,
        app_version: body.app_version || null,
        device_info: body.device_info || null,
        status: 'pending'
      })
      .select()
      .single()

    if (error) {
      console.error('Error inserting feedback:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data, success: true })
  } catch (error) {
    console.error('Feedback POST error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

export async function PATCH(request: Request) {
  try {
    const { feedbackId, status, admin_notes } = await request.json()

    if (!feedbackId || !status) {
      return NextResponse.json({ error: 'Missing feedbackId or status' }, { status: 400 })
    }

    const updateData: Record<string, unknown> = {
      status,
      reviewed_at: status !== 'pending' ? new Date().toISOString() : null
    }

    if (admin_notes !== undefined) {
      updateData.admin_notes = admin_notes
    }

    const { error } = await supabase
      .from('feedback')
      .update(updateData)
      .eq('id', feedbackId)

    if (error) {
      console.error('Error updating feedback:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Feedback PATCH error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}
