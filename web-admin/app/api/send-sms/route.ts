import { NextResponse } from 'next/server'
import { Twilio } from 'twilio'

// Initialize Twilio client
const twilioClient = new Twilio(
  process.env.TWILIO_ACCOUNT_SID!,
  process.env.TWILIO_AUTH_TOKEN!
)

export async function POST(request: Request) {
  try {
    const { to, message, priority } = await request.json()

    // Verify authorization
    const authHeader = request.headers.get('authorization')
    const expectedKey = process.env.HEALTH_CHECK_SECRET || 'your-secret-key'

    if (authHeader !== `Bearer ${expectedKey}`) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Send SMS via Twilio
    const twilioMessage = await twilioClient.messages.create({
      body: message,
      to: to, // Your phone number (e.g., '+15555551234')
      from: process.env.TWILIO_PHONE_NUMBER! // Your Twilio number
    })

    console.log(`✅ SMS sent: ${twilioMessage.sid}`)

    return NextResponse.json({
      success: true,
      sid: twilioMessage.sid,
      cost: 0.0079, // Approximate US cost
      priority
    })

  } catch (error: any) {
    console.error('Failed to send SMS:', error)
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
}
