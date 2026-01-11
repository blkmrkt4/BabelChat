import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Initialize Supabase with service role key (has elevated permissions)
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

// POST /api/users/[id]/ban - Ban a user
export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: userId } = await params
    const body = await request.json()
    const { reason } = body

    if (!userId) {
      return NextResponse.json(
        { success: false, error: 'User ID is required' },
        { status: 400 }
      )
    }

    // Check if user exists
    const { data: user, error: fetchError } = await supabase
      .from('profiles')
      .select('id, first_name, last_name, email, is_banned')
      .eq('id', userId)
      .single()

    if (fetchError || !user) {
      return NextResponse.json(
        { success: false, error: 'User not found' },
        { status: 404 }
      )
    }

    // Check if already banned
    if (user.is_banned) {
      return NextResponse.json(
        { success: false, error: 'User is already banned' },
        { status: 400 }
      )
    }

    // Ban the user
    const { error: updateError } = await supabase
      .from('profiles')
      .update({
        is_banned: true,
        banned_at: new Date().toISOString(),
        ban_reason: reason || 'No reason provided'
      })
      .eq('id', userId)

    if (updateError) {
      console.error('Error banning user:', updateError)
      return NextResponse.json(
        { success: false, error: 'Failed to ban user' },
        { status: 500 }
      )
    }

    // Log the action to audit log
    await supabase.from('admin_audit_log').insert({
      action: 'user_banned',
      target_user_id: userId,
      details: {
        reason: reason || 'No reason provided',
        user_name: `${user.first_name} ${user.last_name}`,
        user_email: user.email
      }
    })

    return NextResponse.json({
      success: true,
      message: `User ${user.first_name} ${user.last_name} has been banned`,
      data: { userId, banned: true }
    })

  } catch (error) {
    console.error('Ban user error:', error)
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    )
  }
}

// DELETE /api/users/[id]/ban - Unban a user
export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: userId } = await params

    if (!userId) {
      return NextResponse.json(
        { success: false, error: 'User ID is required' },
        { status: 400 }
      )
    }

    // Check if user exists
    const { data: user, error: fetchError } = await supabase
      .from('profiles')
      .select('id, first_name, last_name, email, is_banned')
      .eq('id', userId)
      .single()

    if (fetchError || !user) {
      return NextResponse.json(
        { success: false, error: 'User not found' },
        { status: 404 }
      )
    }

    // Check if actually banned
    if (!user.is_banned) {
      return NextResponse.json(
        { success: false, error: 'User is not banned' },
        { status: 400 }
      )
    }

    // Unban the user
    const { error: updateError } = await supabase
      .from('profiles')
      .update({
        is_banned: false,
        banned_at: null,
        ban_reason: null
      })
      .eq('id', userId)

    if (updateError) {
      console.error('Error unbanning user:', updateError)
      return NextResponse.json(
        { success: false, error: 'Failed to unban user' },
        { status: 500 }
      )
    }

    // Log the action to audit log
    await supabase.from('admin_audit_log').insert({
      action: 'user_unbanned',
      target_user_id: userId,
      details: {
        user_name: `${user.first_name} ${user.last_name}`,
        user_email: user.email
      }
    })

    return NextResponse.json({
      success: true,
      message: `User ${user.first_name} ${user.last_name} has been unbanned`,
      data: { userId, banned: false }
    })

  } catch (error) {
    console.error('Unban user error:', error)
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    )
  }
}
