import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export async function GET() {
  try {
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString()
    const lastWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString()
    const lastMonth = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString()

    // Get total Muse interactions
    const { count: totalInteractions, error: totalError } = await supabase
      .from('muse_interactions')
      .select('*', { count: 'exact', head: true })

    if (totalError) throw totalError

    // Get interactions today
    const { count: interactionsToday, error: todayError } = await supabase
      .from('muse_interactions')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', today)

    if (todayError) throw todayError

    // Get interactions this week
    const { count: interactionsWeek, error: weekError } = await supabase
      .from('muse_interactions')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', lastWeek)

    if (weekError) throw weekError

    // Get interactions this month
    const { count: interactionsMonth, error: monthError } = await supabase
      .from('muse_interactions')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', lastMonth)

    if (monthError) throw monthError

    // Get breakdown by Muse
    const { data: byMuseData, error: byMuseError } = await supabase
      .from('muse_interactions')
      .select('muse_id, muse_name, language')

    if (byMuseError) throw byMuseError

    // Aggregate by Muse
    const museStats: Record<string, { name: string; language: string; count: number }> = {}
    for (const interaction of byMuseData || []) {
      const key = interaction.muse_id
      if (!museStats[key]) {
        museStats[key] = {
          name: interaction.muse_name,
          language: interaction.language,
          count: 0
        }
      }
      museStats[key].count++
    }

    // Convert to sorted array
    const byMuse = Object.entries(museStats)
      .map(([id, stats]) => ({
        museId: id,
        museName: stats.name,
        language: stats.language,
        interactions: stats.count
      }))
      .sort((a, b) => b.interactions - a.interactions)

    // Get breakdown by language
    const languageStats: Record<string, number> = {}
    for (const interaction of byMuseData || []) {
      const lang = interaction.language
      languageStats[lang] = (languageStats[lang] || 0) + 1
    }

    const byLanguage = Object.entries(languageStats)
      .map(([language, count]) => ({ language, interactions: count }))
      .sort((a, b) => b.interactions - a.interactions)

    // Get unique users who have used Muses
    const { data: uniqueUsersData, error: uniqueUsersError } = await supabase
      .from('muse_interactions')
      .select('user_id')

    if (uniqueUsersError) throw uniqueUsersError

    const uniqueUsers = new Set(uniqueUsersData?.map(d => d.user_id) || []).size

    // Get unique users today
    const { data: uniqueUsersTodayData, error: uniqueUsersTodayError } = await supabase
      .from('muse_interactions')
      .select('user_id')
      .gte('created_at', today)

    if (uniqueUsersTodayError) throw uniqueUsersTodayError

    const uniqueUsersToday = new Set(uniqueUsersTodayData?.map(d => d.user_id) || []).size

    return NextResponse.json({
      success: true,
      data: {
        summary: {
          totalInteractions: totalInteractions || 0,
          interactionsToday: interactionsToday || 0,
          interactionsWeek: interactionsWeek || 0,
          interactionsMonth: interactionsMonth || 0,
          uniqueUsers,
          uniqueUsersToday,
          avgPerUser: uniqueUsers > 0 ? ((totalInteractions || 0) / uniqueUsers).toFixed(1) : '0'
        },
        byMuse,
        byLanguage,
        timestamp: new Date().toISOString()
      }
    })
  } catch (error) {
    console.error('Muse usage error:', error)
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    )
  }
}
