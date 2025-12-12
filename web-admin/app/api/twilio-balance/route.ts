import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  // Check authorization
  const referer = request.headers.get('referer') || ''
  const authHeader = request.headers.get('authorization')
  const expectedKey = process.env.HEALTH_CHECK_SECRET || 'dev-secret'

  const isSameOrigin = referer.includes('localhost') ||
                       referer.includes(process.env.NEXT_PUBLIC_BASE_URL || '')
  const hasValidToken = authHeader === `Bearer ${expectedKey}`

  if (!hasValidToken && !isSameOrigin) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const accountSid = process.env.TWILIO_ACCOUNT_SID
  const authToken = process.env.TWILIO_AUTH_TOKEN

  if (!accountSid || !authToken) {
    return NextResponse.json({
      success: false,
      error: 'Twilio credentials not configured',
      configured: false
    })
  }

  try {
    // Fetch account balance from Twilio API
    const response = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Balance.json`,
      {
        headers: {
          'Authorization': 'Basic ' + Buffer.from(`${accountSid}:${authToken}`).toString('base64')
        }
      }
    )

    if (!response.ok) {
      const errorData = await response.json()
      return NextResponse.json({
        success: false,
        error: errorData.message || `HTTP ${response.status}`,
        configured: true
      })
    }

    const data = await response.json()

    // Also fetch account info for phone number
    const accountResponse = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${accountSid}.json`,
      {
        headers: {
          'Authorization': 'Basic ' + Buffer.from(`${accountSid}:${authToken}`).toString('base64')
        }
      }
    )

    let accountInfo = null
    if (accountResponse.ok) {
      accountInfo = await accountResponse.json()
    }

    return NextResponse.json({
      success: true,
      configured: true,
      data: {
        balance: parseFloat(data.balance),
        currency: data.currency,
        accountSid: accountSid.substring(0, 8) + '...',
        friendlyName: accountInfo?.friendly_name || 'Unknown',
        status: accountInfo?.status || 'unknown',
        twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER
          ? process.env.TWILIO_PHONE_NUMBER.substring(0, 5) + '***' + process.env.TWILIO_PHONE_NUMBER.slice(-2)
          : 'Not configured',
        timestamp: new Date().toISOString()
      }
    })

  } catch (error) {
    console.error('Twilio balance check failed:', error)
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      configured: true
    })
  }
}
