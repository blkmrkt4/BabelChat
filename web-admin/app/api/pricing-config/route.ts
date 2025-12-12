import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

const CONFIG_ID = '00000000-0000-0000-0000-000000000001'

export async function GET() {
  try {
    const { data, error } = await supabase
      .from('pricing_config')
      .select('*')
      .eq('id', CONFIG_ID)
      .single()

    if (error) {
      console.error('Error fetching pricing config:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data })
  } catch (error) {
    console.error('Pricing config GET error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

export async function PUT(request: Request) {
  try {
    const body = await request.json()

    const { data, error } = await supabase
      .from('pricing_config')
      .update({
        premium_price_usd: body.premium_price_usd,
        premium_banner: body.premium_banner,
        premium_features: body.premium_features,
        free_features: body.free_features,
        updated_at: new Date().toISOString()
      })
      .eq('id', CONFIG_ID)
      .select()
      .single()

    if (error) {
      console.error('Error updating pricing config:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ data, success: true })
  } catch (error) {
    console.error('Pricing config PUT error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}
