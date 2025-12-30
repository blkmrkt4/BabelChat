import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export interface UserDetail {
  id: string
  email: string
  firstName: string
  lastName: string
  subscriptionTier: string
  isPremium: boolean
  createdAt: string
  lastActive: string
  location: string
  nativeLanguage: string
  learningLanguages: string[]
  // Stats
  matchCount: number
  realMessagesSent: number
  realMessagesReceived: number
  museInteractions: number
  ttsPlaysUsed: number
  // Calculated
  isActiveToday: boolean
  isActiveWeek: boolean
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const sortBy = searchParams.get('sortBy') || 'lastActive'
    const sortOrder = searchParams.get('sortOrder') || 'desc'
    const limit = parseInt(searchParams.get('limit') || '100')
    const offset = parseInt(searchParams.get('offset') || '0')
    const search = searchParams.get('search') || ''

    // Get all users with their basic info
    let query = supabase
      .from('profiles')
      .select(`
        id,
        email,
        first_name,
        last_name,
        subscription_tier,
        is_premium,
        created_at,
        last_active,
        location,
        native_language,
        learning_languages,
        tts_plays_used_this_month
      `)

    // Apply search filter
    if (search) {
      query = query.or(`first_name.ilike.%${search}%,last_name.ilike.%${search}%,email.ilike.%${search}%`)
    }

    // Apply sorting
    const ascending = sortOrder === 'asc'
    switch (sortBy) {
      case 'name':
        query = query.order('first_name', { ascending })
        break
      case 'email':
        query = query.order('email', { ascending })
        break
      case 'createdAt':
        query = query.order('created_at', { ascending })
        break
      case 'ttsPlays':
        query = query.order('tts_plays_used_this_month', { ascending })
        break
      case 'lastActive':
      default:
        query = query.order('last_active', { ascending })
    }

    // Apply pagination
    query = query.range(offset, offset + limit - 1)

    const { data: users, error: usersError } = await query

    if (usersError) throw usersError

    if (!users || users.length === 0) {
      return NextResponse.json({
        success: true,
        data: {
          users: [],
          total: 0,
          timestamp: new Date().toISOString()
        }
      })
    }

    // Get total count
    const { count: totalCount } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })

    // Get all user IDs for batch queries
    const userIds = users.map(u => u.id)

    // Get match counts per user
    const { data: matchesData } = await supabase
      .from('matches')
      .select('user1_id, user2_id')
      .or(`user1_id.in.(${userIds.join(',')}),user2_id.in.(${userIds.join(',')})`)
      .eq('is_mutual', true)

    const matchCounts: Record<string, number> = {}
    for (const match of matchesData || []) {
      if (userIds.includes(match.user1_id)) {
        matchCounts[match.user1_id] = (matchCounts[match.user1_id] || 0) + 1
      }
      if (userIds.includes(match.user2_id)) {
        matchCounts[match.user2_id] = (matchCounts[match.user2_id] || 0) + 1
      }
    }

    // Get messages sent per user
    const { data: sentMessagesData } = await supabase
      .from('messages')
      .select('sender_id')
      .in('sender_id', userIds)

    const sentCounts: Record<string, number> = {}
    for (const msg of sentMessagesData || []) {
      sentCounts[msg.sender_id] = (sentCounts[msg.sender_id] || 0) + 1
    }

    // Get messages received per user (via conversations)
    const { data: receivedMessagesData } = await supabase
      .from('messages')
      .select('conversation_id, sender_id')

    // Get conversations to map to users
    const { data: conversationsData } = await supabase
      .from('conversations')
      .select('id, user1_id, user2_id')

    const convUserMap: Record<string, string[]> = {}
    for (const conv of conversationsData || []) {
      convUserMap[conv.id] = [conv.user1_id, conv.user2_id]
    }

    const receivedCounts: Record<string, number> = {}
    for (const msg of receivedMessagesData || []) {
      const participants = convUserMap[msg.conversation_id] || []
      const receiverId = participants.find(id => id !== msg.sender_id)
      if (receiverId && userIds.includes(receiverId)) {
        receivedCounts[receiverId] = (receivedCounts[receiverId] || 0) + 1
      }
    }

    // Get Muse interactions per user
    const { data: museData } = await supabase
      .from('muse_interactions')
      .select('user_id')
      .in('user_id', userIds)

    const museCounts: Record<string, number> = {}
    for (const interaction of museData || []) {
      museCounts[interaction.user_id] = (museCounts[interaction.user_id] || 0) + 1
    }

    // Calculate activity thresholds
    const now = new Date()
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000)
    const lastWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)

    // Build response
    const userDetails: UserDetail[] = users.map(user => {
      const lastActiveDate = user.last_active ? new Date(user.last_active) : null

      return {
        id: user.id,
        email: user.email || '',
        firstName: user.first_name || '',
        lastName: user.last_name || '',
        subscriptionTier: user.subscription_tier || 'free',
        isPremium: user.is_premium || false,
        createdAt: user.created_at,
        lastActive: user.last_active,
        location: user.location || '',
        nativeLanguage: user.native_language || '',
        learningLanguages: user.learning_languages || [],
        matchCount: matchCounts[user.id] || 0,
        realMessagesSent: sentCounts[user.id] || 0,
        realMessagesReceived: receivedCounts[user.id] || 0,
        museInteractions: museCounts[user.id] || 0,
        ttsPlaysUsed: user.tts_plays_used_this_month || 0,
        isActiveToday: lastActiveDate ? lastActiveDate >= yesterday : false,
        isActiveWeek: lastActiveDate ? lastActiveDate >= lastWeek : false,
      }
    })

    // Calculate summary stats
    const summary = {
      totalUsers: totalCount || 0,
      activeToday: userDetails.filter(u => u.isActiveToday).length,
      activeWeek: userDetails.filter(u => u.isActiveWeek).length,
      premiumUsers: userDetails.filter(u => u.isPremium).length,
      totalMatches: Object.values(matchCounts).reduce((a, b) => a + b, 0) / 2, // Divide by 2 since matches are counted twice
      totalRealMessages: Object.values(sentCounts).reduce((a, b) => a + b, 0),
      totalMuseInteractions: Object.values(museCounts).reduce((a, b) => a + b, 0),
      totalTTSPlays: userDetails.reduce((sum, u) => sum + u.ttsPlaysUsed, 0),
    }

    return NextResponse.json({
      success: true,
      data: {
        users: userDetails,
        summary,
        pagination: {
          total: totalCount || 0,
          limit,
          offset,
          hasMore: offset + limit < (totalCount || 0)
        },
        timestamp: new Date().toISOString()
      }
    })
  } catch (error) {
    console.error('Users detail error:', error)
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    )
  }
}
