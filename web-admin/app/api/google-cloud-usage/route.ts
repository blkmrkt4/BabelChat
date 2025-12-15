import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Google Cloud TTS pricing (per character)
const TTS_PRICING = {
  standard: 0.000004,    // $4 per 1M characters
  wavenet: 0.000016,     // $16 per 1M characters
  neural2: 0.000016,     // $16 per 1M characters
}

// Average characters per TTS play (estimated)
const AVG_CHARS_PER_PLAY = 100

export async function GET() {
  try {
    const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

    if (!supabaseUrl || !supabaseKey) {
      return NextResponse.json({ success: false, error: 'Supabase not configured' })
    }

    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get total TTS plays this month from all users
    const startOfMonth = new Date()
    startOfMonth.setDate(1)
    startOfMonth.setHours(0, 0, 0, 0)

    // Get sum of TTS plays from profiles where billing cycle started this month
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('tts_plays_used_this_month, subscription_tier')

    if (profilesError) {
      console.error('Error fetching profiles:', profilesError)
      return NextResponse.json({ success: false, error: 'Failed to fetch TTS usage data' })
    }

    let totalPlaysThisMonth = 0
    let playsThisMonthByTier = { free: 0, premium: 0, pro: 0 }

    for (const profile of profiles || []) {
      const plays = profile.tts_plays_used_this_month || 0
      totalPlaysThisMonth += plays

      const tier = profile.subscription_tier || 'free'
      if (tier === 'free') {
        playsThisMonthByTier.free += plays
      } else if (tier === 'premium') {
        playsThisMonthByTier.premium += plays
      } else if (tier === 'pro') {
        playsThisMonthByTier.pro += plays
      }
    }

    // Only premium/pro users use Google TTS (free users use Apple voices)
    const googleTTSPlays = playsThisMonthByTier.premium + playsThisMonthByTier.pro
    const estimatedCharacters = googleTTSPlays * AVG_CHARS_PER_PLAY

    // Calculate estimated cost (assuming mostly Neural2/Wavenet voices)
    const estimatedCost = estimatedCharacters * TTS_PRICING.neural2

    // Get usage trend (last 7 days vs previous 7 days)
    // Note: We don't have daily tracking, so we'll estimate based on monthly data
    const daysIntoMonth = new Date().getDate()
    const avgPlaysPerDay = totalPlaysThisMonth / Math.max(1, daysIntoMonth)

    // Project monthly usage and cost
    const daysInMonth = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).getDate()
    const projectedMonthlyPlays = Math.round(avgPlaysPerDay * daysInMonth)
    const projectedGooglePlays = projectedMonthlyPlays * (googleTTSPlays / Math.max(1, totalPlaysThisMonth))
    const projectedMonthlyCost = projectedGooglePlays * AVG_CHARS_PER_PLAY * TTS_PRICING.neural2

    return NextResponse.json({
      success: true,
      data: {
        currentMonth: {
          totalPlays: totalPlaysThisMonth,
          googleTTSPlays: googleTTSPlays,
          appleTTSPlays: playsThisMonthByTier.free,
          estimatedCharacters: estimatedCharacters,
          estimatedCost: estimatedCost
        },
        byTier: playsThisMonthByTier,
        projections: {
          monthlyPlays: projectedMonthlyPlays,
          monthlyCost: projectedMonthlyCost
        },
        pricing: {
          perCharacter: TTS_PRICING.neural2,
          perMillionChars: TTS_PRICING.neural2 * 1000000,
          avgCharsPerPlay: AVG_CHARS_PER_PLAY
        },
        timestamp: new Date().toISOString()
      }
    })

  } catch (error) {
    console.error('Error getting Google Cloud usage:', error)
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    })
  }
}
