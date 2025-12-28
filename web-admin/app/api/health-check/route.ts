import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Initialize Supabase with service role key (has elevated permissions)
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY!

export async function GET(request: Request) {
  // Verify the request is authorized
  const authHeader = request.headers.get('authorization')
  const referer = request.headers.get('referer') || ''
  const origin = request.headers.get('origin') || ''
  const host = request.headers.get('host') || ''
  const expectedKey = process.env.HEALTH_CHECK_SECRET || 'dev-secret'

  // Allow if: valid bearer token OR same-origin request (for web admin UI)
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || ''
  const isSameOrigin = referer.includes('localhost') ||
                       origin.includes('localhost') ||
                       referer.includes(baseUrl) ||
                       origin.includes(baseUrl) ||
                       (baseUrl && host.includes(new URL(baseUrl).host)) ||
                       host.includes('vercel.app') ||  // Allow Vercel preview deployments
                       host.includes('silentseer.com')  // Production domain
  const hasValidToken = authHeader === `Bearer ${expectedKey}`

  if (!hasValidToken && !isSameOrigin) {
    console.log('Unauthorized request:', { referer, origin, host, baseUrl })
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    // Get all active AI model configs
    const { data: configs, error: configError } = await supabase
      .from('ai_config')
      .select('*')
      .eq('is_active', true)

    if (configError) throw configError
    if (!configs || configs.length === 0) {
      return NextResponse.json({ error: 'No active models found' }, { status: 404 })
    }

    // Test each model
    const results = await Promise.allSettled(
      configs.map(config => testModel(config))
    )

    // Check for failures and send alerts if needed
    await checkAndSendAlerts()

    // Return summary
    const summary = {
      success: true,
      tested: configs.length,
      results: results.map((r, i) => ({
        model: configs[i].model_id,
        category: configs[i].category,
        status: r.status === 'fulfilled' ? 'success' : 'error',
        error: r.status === 'rejected' ? r.reason.message : null
      }))
    }

    return NextResponse.json(summary)

  } catch (error: any) {
    console.error('Health check failed:', error)
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
}

async function testModel(config: any) {
  const startTime = Date.now()

  try {
    // Make a minimal test request to OpenRouter
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://fluenca.app',
        'X-Title': 'Fluenca Health Check'
      },
      body: JSON.stringify({
        model: config.model_id,
        messages: [
          { role: 'user', content: 'test' }
        ],
        max_tokens: 5
      }),
      signal: AbortSignal.timeout(10000) // 10 second timeout
    })

    const responseTime = Date.now() - startTime
    const data = await response.json()

    // Log result to database
    const logData = {
      service: 'openrouter',
      model_id: config.model_id,
      category: config.category,
      status: response.ok ? 'success' : 'error',
      response_time_ms: responseTime,
      error_code: response.ok ? null : response.status.toString(),
      error_message: response.ok ? null : (data.error?.message || 'Unknown error'),
      metadata: response.ok ? null : data
    }

    await supabase.from('api_health_checks').insert(logData)

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${data.error?.message || 'Unknown error'}`)
    }

    return { success: true, responseTime }

  } catch (error: any) {
    const responseTime = Date.now() - startTime

    // Log error to database
    await supabase.from('api_health_checks').insert({
      service: 'openrouter',
      model_id: config.model_id,
      category: config.category,
      status: error.name === 'TimeoutError' ? 'timeout' : 'error',
      response_time_ms: responseTime,
      error_message: error.message,
      metadata: { error: error.toString() }
    })

    throw error
  }
}

async function checkAndSendAlerts() {
  // Get enabled alert configs
  const { data: alertConfigs } = await supabase
    .from('alert_config')
    .select('*')
    .eq('enabled', true)

  if (!alertConfigs || alertConfigs.length === 0) return

  // Get recent health checks (last hour)
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString()
  const { data: recentChecks } = await supabase
    .from('api_health_checks')
    .select('*')
    .gte('checked_at', oneHourAgo)
    .order('checked_at', { ascending: false })

  if (!recentChecks) return

  // Group by model and check for consecutive failures
  const modelFailures = new Map<string, { count: number, checks: any[] }>()

  recentChecks.forEach(check => {
    const key = `${check.service}:${check.model_id}`
    if (!modelFailures.has(key)) {
      modelFailures.set(key, { count: 0, checks: [] })
    }

    const failures = modelFailures.get(key)!
    failures.checks.push(check)

    // Count consecutive failures from most recent
    if (failures.checks.length <= 10 && check.status !== 'success') {
      failures.count++
    }
  })

  // Send alerts for models exceeding threshold
  for (const config of alertConfigs) {
    for (const [modelKey, failures] of modelFailures) {
      if (failures.count >= config.failure_threshold) {
        const [service, modelId] = modelKey.split(':')

        // Check cooldown period
        const cooldownAgo = new Date(Date.now() - config.cooldown_minutes * 60 * 1000).toISOString()
        const { data: recentAlert } = await supabase
          .from('alert_history')
          .select('sent_at')
          .eq('alert_config_id', config.id)
          .eq('service', service)
          .eq('model_id', modelId)
          .gte('sent_at', cooldownAgo)
          .limit(1)
          .single()

        // Only send if no recent alert
        if (!recentAlert) {
          await sendAlert(config, service, modelId, failures.count)
        }
      }
    }
  }
}

async function sendAlert(config: any, service: string, modelId: string, failureCount: number) {
  // Only send SMS for 3+ consecutive failures (service is actually down)
  if (failureCount < 3) return

  // Look up the model's role (Primary, FB1, FB2, etc.) from ai_config
  const modelRole = await getModelRole(modelId)

  // Format model name nicely (capitalize provider, keep model name)
  const formattedModelName = formatModelName(modelId)

  // Build the message
  const smsMessage = `Fluenca: ${formattedModelName} is ${modelRole} and it's down (${failureCount} failures).`

  try {
    // Send SMS via Twilio
    if (process.env.TWILIO_PHONE_NUMBER && process.env.ALERT_PHONE_NUMBER) {
      await fetch(`${process.env.NEXT_PUBLIC_BASE_URL}/api/send-sms`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${process.env.HEALTH_CHECK_SECRET}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          to: process.env.ALERT_PHONE_NUMBER,
          message: smsMessage,
          priority: 'critical'
        })
      })

      console.log(`📱 SMS sent: ${modelId} (${modelRole}) is DOWN`)
    }

    // Log alert sent
    await supabase.from('alert_history').insert({
      alert_config_id: config.id,
      service,
      model_id: modelId,
      reason: `${failureCount} consecutive failures - SMS sent`,
      metadata: {
        failure_count: failureCount,
        model_role: modelRole,
        message: smsMessage,
        sms_sent: true
      }
    })

  } catch (error) {
    console.error('Failed to send SMS alert:', error)
  }
}

// Look up the model's role across all ai_config categories
async function getModelRole(modelId: string): Promise<string> {
  try {
    const { data: configs } = await supabase
      .from('ai_config')
      .select('category, model_id, fallback_model_1_id, fallback_model_2_id, fallback_model_3_id, fallback_model_4_id')
      .eq('is_active', true)

    if (!configs) return 'a model'

    for (const config of configs) {
      if (config.model_id === modelId) {
        return `the Primary model (${config.category})`
      }
      if (config.fallback_model_1_id === modelId) {
        return `FB1 (${config.category})`
      }
      if (config.fallback_model_2_id === modelId) {
        return `FB2 (${config.category})`
      }
      if (config.fallback_model_3_id === modelId) {
        return `FB3 (${config.category})`
      }
      if (config.fallback_model_4_id === modelId) {
        return `FB4 (${config.category})`
      }
    }

    return 'a configured model'
  } catch (error) {
    console.error('Error looking up model role:', error)
    return 'a model'
  }
}

// Format model ID into a nicer display name
function formatModelName(modelId: string): string {
  // modelId format is typically "provider/model-name"
  const parts = modelId.split('/')
  if (parts.length === 2) {
    // Capitalize first letter of provider
    const provider = parts[0].charAt(0).toUpperCase() + parts[0].slice(1)
    return `${provider}/${parts[1]}`
  }
  return modelId
}
