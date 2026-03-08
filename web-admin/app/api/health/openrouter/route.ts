import { NextResponse } from 'next/server'

// Check OpenRouter API key status and limits
export async function GET() {
  const apiKey = process.env.OPENROUTER_API_KEY

  if (!apiKey) {
    return NextResponse.json({
      status: 'error',
      message: 'OpenRouter API key not configured',
      healthy: false,
    })
  }

  try {
    // Check key status by making a minimal API call
    const response = await fetch('https://openrouter.ai/api/v1/auth/key', {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
      },
    })

    if (!response.ok) {
      // Try to get error details
      const errorText = await response.text()
      let errorMessage = `API returned ${response.status}`

      try {
        const errorJson = JSON.parse(errorText)
        errorMessage = errorJson.error?.message || errorMessage
      } catch {
        // Use status-based message
      }

      // Check for specific error codes
      if (response.status === 403) {
        return NextResponse.json({
          status: 'limit_exceeded',
          message: 'API key limit exceeded - add credits or increase key limit at https://openrouter.ai/settings/keys',
          healthy: false,
          actionRequired: true,
        })
      }

      if (response.status === 401) {
        return NextResponse.json({
          status: 'invalid_key',
          message: 'API key is invalid or expired',
          healthy: false,
          actionRequired: true,
        })
      }

      return NextResponse.json({
        status: 'error',
        message: errorMessage,
        healthy: false,
      })
    }

    const data = await response.json()

    // Calculate usage percentage if limits are available
    let usagePercent = null
    let warning = null

    if (data.limit && data.usage !== undefined) {
      usagePercent = Math.round((data.usage / data.limit) * 100)

      if (usagePercent >= 90) {
        warning = 'Critical: API key usage is at 90%+ - translations may fail soon!'
      } else if (usagePercent >= 75) {
        warning = 'Warning: API key usage is at 75%+ - consider adding credits'
      }
    }

    return NextResponse.json({
      status: 'healthy',
      healthy: true,
      keyInfo: {
        label: data.label || 'Default',
        limit: data.limit,
        usage: data.usage,
        usagePercent,
        limitRemaining: data.limit ? (data.limit - (data.usage || 0)) : null,
      },
      warning,
      lastChecked: new Date().toISOString(),
    })

  } catch (error) {
    return NextResponse.json({
      status: 'error',
      message: `Failed to check API status: ${error}`,
      healthy: false,
    })
  }
}
