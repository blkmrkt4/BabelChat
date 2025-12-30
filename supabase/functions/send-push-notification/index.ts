// Supabase Edge Function: send-push-notification
// Sends APNs push notifications when new messages arrive

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const APNS_ENDPOINT_DEVELOPMENT = "https://api.sandbox.push.apple.com"
const APNS_ENDPOINT_PRODUCTION = "https://api.push.apple.com"

// APNs configuration from environment variables
const APNS_KEY_ID = Deno.env.get('APNS_KEY_ID')
const APNS_TEAM_ID = Deno.env.get('APNS_TEAM_ID')
const APNS_BUNDLE_ID = Deno.env.get('APNS_BUNDLE_ID') || 'com.painkillerlabs.fluenca'
const APNS_PRIVATE_KEY = Deno.env.get('APNS_PRIVATE_KEY')

interface NotificationPayload {
  userId: string
  type: 'new_message' | 'new_match' | 'like_received'
  title: string
  body: string
  data?: Record<string, any>
}

serve(async (req) => {
  try {
    // Parse request body
    const payload: NotificationPayload = await req.json()
    const { userId, type, title, body, data = {} } = payload

    console.log(`📬 Sending ${type} notification to user ${userId}`)

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get user's device tokens
    const { data: tokens, error: tokensError } = await supabase
      .from('device_tokens')
      .select('*')
      .eq('user_id', userId)
      .eq('is_active', true)

    if (tokensError) {
      console.error('❌ Error fetching device tokens:', tokensError)
      throw tokensError
    }

    if (!tokens || tokens.length === 0) {
      console.log('⚠️ No active device tokens found for user')
      return new Response(
        JSON.stringify({ success: false, message: 'No active devices' }),
        { headers: { "Content-Type": "application/json" }, status: 200 }
      )
    }

    console.log(`📱 Found ${tokens.length} device(s) for user ${userId}`)

    // Send notification to each device
    const results = await Promise.all(
      tokens.map(token => sendAPNsNotification(token, type, title, body, data))
    )

    // Log results
    const successful = results.filter(r => r.success).length
    const failed = results.filter(r => !r.success).length

    console.log(`✅ Successfully sent to ${successful} device(s), ❌ failed: ${failed}`)

    return new Response(
      JSON.stringify({
        success: true,
        sent: successful,
        failed: failed,
        results: results
      }),
      { headers: { "Content-Type": "application/json" } }
    )

  } catch (error) {
    console.error('❌ Error in send-push-notification:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { "Content-Type": "application/json" }, status: 500 }
    )
  }
})

async function sendAPNsNotification(
  deviceToken: any,
  type: string,
  title: string,
  body: string,
  data: Record<string, any>
): Promise<{ success: boolean; error?: string; apnsId?: string }> {
  try {
    // Select endpoint based on environment
    const endpoint = deviceToken.environment === 'production'
      ? APNS_ENDPOINT_PRODUCTION
      : APNS_ENDPOINT_DEVELOPMENT

    const url = `${endpoint}/3/device/${deviceToken.device_token}`

    // Build APNs payload
    const apnsPayload = {
      aps: {
        alert: {
          title: title,
          body: body
        },
        badge: 1,
        sound: 'default',
        'content-available': 1
      },
      type: type,
      ...data
    }

    // Generate JWT for APNs authentication
    const jwt = await generateAPNsJWT()

    // Send HTTP/2 request to APNs
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'apns-topic': APNS_BUNDLE_ID,
        'apns-push-type': 'alert',
        'apns-priority': '10',
        'authorization': `bearer ${jwt}`,
        'content-type': 'application/json'
      },
      body: JSON.stringify(apnsPayload)
    })

    const apnsId = response.headers.get('apns-id')

    if (response.status === 200) {
      console.log(`✅ APNs success for device ${deviceToken.id}, apns-id: ${apnsId}`)
      return { success: true, apnsId: apnsId || undefined }
    } else {
      const errorBody = await response.text()
      console.error(`❌ APNs error (${response.status}):`, errorBody)
      return { success: false, error: errorBody }
    }

  } catch (error) {
    console.error('❌ Error sending to APNs:', error)
    return { success: false, error: error.message }
  }
}

// Generate JWT token for APNs authentication
async function generateAPNsJWT(): Promise<string> {
  // Note: This is a simplified version. In production, you'd use a proper JWT library
  // or import the APNs signing key properly

  if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_PRIVATE_KEY) {
    throw new Error('Missing APNs credentials in environment variables')
  }

  const header = {
    alg: 'ES256',
    kid: APNS_KEY_ID
  }

  const payload = {
    iss: APNS_TEAM_ID,
    iat: Math.floor(Date.now() / 1000)
  }

  // In a real implementation, you would use a JWT library here
  // For now, this is a placeholder that shows the structure
  console.log('⚠️ JWT generation needs to be implemented with proper ES256 signing')

  // You'll need to use a library like:
  // import * as jose from 'https://deno.land/x/jose@v4.11.2/index.ts'
  // And properly sign with your .p8 private key

  throw new Error('APNs JWT generation not yet implemented - requires ES256 signing library')
}
