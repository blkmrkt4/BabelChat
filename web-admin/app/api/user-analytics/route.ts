import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export async function GET() {
  try {
    // Get total users count
    const { count: totalUsers, error: totalError } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })

    if (totalError) throw totalError

    // Get premium users count
    const { count: premiumUsers, error: premiumError } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })
      .eq('is_premium', true)

    if (premiumError) throw premiumError

    // Get users active in last 24 hours
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
    const { count: activeToday, error: activeError } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })
      .gte('last_active', yesterday)

    if (activeError) throw activeError

    // Get users active in last 7 days
    const lastWeek = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
    const { count: activeWeek, error: activeWeekError } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })
      .gte('last_active', lastWeek)

    if (activeWeekError) throw activeWeekError

    // Get total messages count
    const { count: totalMessages, error: messagesError } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true })

    if (messagesError) throw messagesError

    // Get messages from last 24 hours
    const { count: messagesToday, error: messagesTodayError } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', yesterday)

    if (messagesTodayError) throw messagesTodayError

    // Get messages from last 7 days
    const { count: messagesWeek, error: messagesWeekError } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', lastWeek)

    if (messagesWeekError) throw messagesWeekError

    // Calculate averages
    const freeUsers = (totalUsers || 0) - (premiumUsers || 0)
    const avgMessagesPerUser = totalUsers && totalUsers > 0
      ? ((totalMessages || 0) / totalUsers).toFixed(1)
      : '0'

    // Try to get message counts by user type (free vs premium)
    // This requires joining messages with profiles
    let messagesByFreeUsers = 0
    let messagesByPremiumUsers = 0

    try {
      // Get all sender IDs and their message counts
      const { data: messageCounts } = await supabase
        .from('messages')
        .select('sender_id')

      if (messageCounts && messageCounts.length > 0) {
        // Get premium user IDs
        const { data: premiumProfiles } = await supabase
          .from('profiles')
          .select('id')
          .eq('is_premium', true)

        const premiumIds = new Set(premiumProfiles?.map(p => p.id) || [])

        for (const msg of messageCounts) {
          if (premiumIds.has(msg.sender_id)) {
            messagesByPremiumUsers++
          } else {
            messagesByFreeUsers++
          }
        }
      }
    } catch {
      // If this fails, we'll just show 0s
      console.log('Could not calculate messages by user type')
    }

    const avgMessagesFree = freeUsers > 0
      ? (messagesByFreeUsers / freeUsers).toFixed(1)
      : '0'
    const avgMessagesPremium = premiumUsers && premiumUsers > 0
      ? (messagesByPremiumUsers / premiumUsers).toFixed(1)
      : '0'

    return NextResponse.json({
      success: true,
      data: {
        users: {
          total: totalUsers || 0,
          free: freeUsers,
          premium: premiumUsers || 0,
          activeToday: activeToday || 0,
          activeWeek: activeWeek || 0,
        },
        messages: {
          total: totalMessages || 0,
          today: messagesToday || 0,
          week: messagesWeek || 0,
          byFreeUsers: messagesByFreeUsers,
          byPremiumUsers: messagesByPremiumUsers,
          avgPerUser: avgMessagesPerUser,
          avgPerFreeUser: avgMessagesFree,
          avgPerPremiumUser: avgMessagesPremium,
        },
        timestamp: new Date().toISOString()
      }
    })
  } catch (error) {
    console.error('User analytics error:', error)
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    )
  }
}
