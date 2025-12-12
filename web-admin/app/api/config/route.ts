import { NextResponse } from 'next/server'

export async function GET() {
  try {
    // Get phone numbers from environment
    const primaryPhone = process.env.ALERT_PHONE_NUMBER
    const backupPhone = process.env.ALERT_PHONE_NUMBER_BACKUP

    // Mask phone numbers for security (show first 3 and last 4 digits)
    const maskPhone = (phone: string | undefined) => {
      if (!phone) return 'Not configured'
      return phone.replace(/(\+\d{2})(\d+)(\d{4})/, '$1 *** *** $3')
    }

    return NextResponse.json({
      phoneNumbers: {
        primary: maskPhone(primaryPhone),
        backup: maskPhone(backupPhone),
        primaryFull: primaryPhone, // For API calls (not displayed)
        backupFull: backupPhone
      },
      twilioNumber: process.env.TWILIO_PHONE_NUMBER,
      healthCheck: {
        frequency: '15 minutes',
        failureThreshold: 3,
        cooldownMinutes: 60
      },
      services: [
        { name: 'Translation API', category: 'translation' },
        { name: 'Grammar Check API', category: 'grammar' },
        { name: 'Scoring API', category: 'scoring' }
      ]
    })
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
}
