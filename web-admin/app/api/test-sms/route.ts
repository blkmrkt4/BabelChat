import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const { to, recipientType } = await request.json()

    if (!to) {
      return NextResponse.json(
        { success: false, error: 'Phone number is required' },
        { status: 400 }
      )
    }

    // Send test SMS (under 160 chars for trial account)
    const message = `LangChat Test: ${recipientType || 'test'} SMS monitoring is working. Alerts configured correctly.`

    const response = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL}/api/send-sms`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.HEALTH_CHECK_SECRET}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        to,
        message,
        priority: 'test'
      })
    })

    const data = await response.json()

    if (!response.ok) {
      return NextResponse.json(
        { success: false, error: data.error || 'Failed to send SMS' },
        { status: response.status }
      )
    }

    return NextResponse.json({
      success: true,
      message: `Test SMS sent to ${recipientType || 'phone'} number`,
      sid: data.sid,
      to: to.replace(/(\+\d{2})\d+(\d{4})/, '$1 *** *** $2') // Mask middle digits
    })

  } catch (error: any) {
    console.error('Test SMS error:', error)
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    )
  }
}
