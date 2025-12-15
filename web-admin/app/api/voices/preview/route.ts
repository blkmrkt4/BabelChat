import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const { text, languageCode, voiceName, speakingRate, pitch, gender } = await request.json()

    if (!text || !languageCode || !voiceName) {
      return NextResponse.json(
        { error: 'text, languageCode, and voiceName are required' },
        { status: 400 }
      )
    }

    const apiKey = process.env.GOOGLE_CLOUD_API_KEY
    if (!apiKey) {
      return NextResponse.json(
        { error: 'Google Cloud API key not configured' },
        { status: 500 }
      )
    }

    // Call Google Cloud TTS API
    const response = await fetch(
      `https://texttospeech.googleapis.com/v1/text:synthesize?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          input: { text },
          voice: {
            languageCode,
            name: voiceName,
            ssmlGender: gender || 'NEUTRAL'
          },
          audioConfig: {
            audioEncoding: 'MP3',
            speakingRate: speakingRate || 0.85,
            pitch: pitch || 0
          }
        })
      }
    )

    const data = await response.json()

    if (!response.ok) {
      console.error('Google TTS error:', data)
      return NextResponse.json(
        { error: data.error?.message || 'Failed to generate speech' },
        { status: response.status }
      )
    }

    // Return the base64 audio content
    return NextResponse.json({ audioContent: data.audioContent })
  } catch (error) {
    console.error('TTS preview error:', error)
    return NextResponse.json(
      { error: 'Failed to generate voice preview' },
      { status: 500 }
    )
  }
}
