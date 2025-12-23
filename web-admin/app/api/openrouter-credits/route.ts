import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    // Check authorization - allow if:
    // 1. Valid bearer token matches HEALTH_CHECK_SECRET (for external calls)
    // 2. Request is from same origin (internal admin page)
    const authHeader = request.headers.get('authorization');
    const healthCheckSecret = process.env.HEALTH_CHECK_SECRET;
    const referer = request.headers.get('referer') || '';
    const origin = request.headers.get('origin') || '';
    const host = request.headers.get('host') || '';

    const isValidToken = healthCheckSecret && authHeader === `Bearer ${healthCheckSecret}`;
    const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || '';
    const isSameOrigin = referer.includes('localhost') ||
                         origin.includes('localhost') ||
                         referer.includes(baseUrl) ||
                         origin.includes(baseUrl) ||
                         host.includes('vercel.app') ||
                         host.includes('silentseer.com');

    if (!isValidToken && !isSameOrigin) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Get OpenRouter API key from environment
    const apiKey = process.env.OPENROUTER_API_KEY;

    if (!apiKey) {
      return NextResponse.json(
        { error: 'OpenRouter API key not configured' },
        { status: 500 }
      );
    }

    // Try to fetch overall account balance first
    let accountBalance = null;

    // Attempt to get account-level balance from /api/v1/auth or /api/v1/credits
    try {
      const accountResponse = await fetch('https://openrouter.ai/api/v1/credits', {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
      });

      if (accountResponse.ok) {
        const accountData = await accountResponse.json();
        console.log('💰 Account balance endpoint response:', JSON.stringify(accountData, null, 2));
        // The response has total_credits and total_usage in data.data
        accountBalance = accountData.data?.total_credits || accountData.data?.balance || accountData.balance || accountData.credits || null;
      } else {
        console.log('⚠️ /api/v1/credits endpoint not available:', accountResponse.status);
      }
    } catch (error) {
      console.log('⚠️ Failed to fetch account balance:', error);
    }

    // Fetch API key information from OpenRouter
    const response = await fetch('https://openrouter.ai/api/v1/auth/key', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OpenRouter API error:', response.status, errorText);
      return NextResponse.json(
        { error: `OpenRouter API error: ${response.status}` },
        { status: response.status }
      );
    }

    const data = await response.json();

    // Log the full response to see all available fields
    console.log('🔍 Full OpenRouter API response:', JSON.stringify(data, null, 2));

    // Extract relevant credit information
    const creditsInfo = {
      // Account-level balance (from separate endpoint or this endpoint)
      // The /api/v1/credits endpoint returns total_credits
      accountBalance: accountBalance || data.data?.total_credits || data.data?.balance || data.data?.account_balance || data.data?.credit_balance || null,

      // Key-specific information
      label: data.data?.label || 'Unknown',
      usage: data.data?.usage || 0,
      limit: data.data?.limit || null,
      limitRemaining: data.data?.limit_remaining || null,
      isFreeLimit: data.data?.is_free_tier || false,
      rateLimit: data.data?.rate_limit || null,

      timestamp: new Date().toISOString(),
    };

    // Calculate remaining credits if limit is available
    if (creditsInfo.limit !== null) {
      creditsInfo.limitRemaining = creditsInfo.limit - creditsInfo.usage;
    }

    console.log('📊 Extracted credits info:', creditsInfo);

    return NextResponse.json({
      success: true,
      data: creditsInfo,
    });

  } catch (error) {
    console.error('Error fetching OpenRouter credits:', error);
    return NextResponse.json(
      { error: 'Failed to fetch credits information' },
      { status: 500 }
    );
  }
}
