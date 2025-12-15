'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

interface ServiceStatus {
  model_id: string
  model_name: string
  category: string
  status: 'up' | 'down' | 'unknown'
  lastChecked: string
  consecutiveFailures: number
  avgResponseTime: number
}

interface OpenRouterCredits {
  accountBalance: number | null
  label: string
  usage: number
  limit: number | null
  limitRemaining: number | null
  isFreeLimit: boolean
  rateLimit: any
  timestamp: string
}

interface TwilioBalance {
  balance: number
  currency: string
  accountSid: string
  friendlyName: string
  status: string
  twilioPhoneNumber: string
  timestamp: string
}

interface SupabaseHealth {
  status: 'up' | 'down' | 'unknown'
  latency: number
  tablesAccessible: boolean
  timestamp: string
}

interface UserAnalytics {
  users: {
    total: number
    free: number
    premium: number
    activeToday: number
    activeWeek: number
  }
  messages: {
    total: number
    today: number
    week: number
    byFreeUsers: number
    byPremiumUsers: number
    avgPerUser: string
    avgPerFreeUser: string
    avgPerPremiumUser: string
  }
  timestamp: string
}

interface GoogleCloudUsage {
  currentMonth: {
    totalPlays: number
    googleTTSPlays: number
    appleTTSPlays: number
    estimatedCharacters: number
    estimatedCost: number
  }
  byTier: {
    free: number
    premium: number
    pro: number
  }
  projections: {
    monthlyPlays: number
    monthlyCost: number
  }
  pricing: {
    perCharacter: number
    perMillionChars: number
    avgCharsPerPlay: number
  }
  timestamp: string
}

interface MuseUsage {
  summary: {
    totalInteractions: number
    interactionsToday: number
    interactionsWeek: number
    interactionsMonth: number
    uniqueUsers: number
    uniqueUsersToday: number
    avgPerUser: string
  }
  byMuse: {
    museId: string
    museName: string
    language: string
    interactions: number
  }[]
  byLanguage: {
    language: string
    interactions: number
  }[]
  timestamp: string
}

export default function MonitoringPage() {
  const [services, setServices] = useState<ServiceStatus[]>([])
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState({
    allUp: false,
    totalChecks: 0,
    successRate: 0
  })
  const [credits, setCredits] = useState<OpenRouterCredits | null>(null)
  const [creditsLoading, setCreditsLoading] = useState(true)
  const [creditsError, setCreditsError] = useState<string | null>(null)
  const [healthCheckRunning, setHealthCheckRunning] = useState(false)
  const [healthCheckResult, setHealthCheckResult] = useState<{
    success: boolean
    message: string
    details?: any
  } | null>(null)

  // Twilio state
  const [twilio, setTwilio] = useState<TwilioBalance | null>(null)
  const [twilioLoading, setTwilioLoading] = useState(true)
  const [twilioError, setTwilioError] = useState<string | null>(null)
  const [twilioConfigured, setTwilioConfigured] = useState(true)

  // Supabase health state
  const [supabaseHealth, setSupabaseHealth] = useState<SupabaseHealth | null>(null)
  const [supabaseLoading, setSupabaseLoading] = useState(true)

  // User analytics state
  const [analytics, setAnalytics] = useState<UserAnalytics | null>(null)
  const [analyticsLoading, setAnalyticsLoading] = useState(true)
  const [analyticsError, setAnalyticsError] = useState<string | null>(null)

  // Google Cloud TTS usage state
  const [googleCloud, setGoogleCloud] = useState<GoogleCloudUsage | null>(null)
  const [googleCloudLoading, setGoogleCloudLoading] = useState(true)
  const [googleCloudError, setGoogleCloudError] = useState<string | null>(null)

  // Muse usage state
  const [museUsage, setMuseUsage] = useState<MuseUsage | null>(null)
  const [museUsageLoading, setMuseUsageLoading] = useState(true)
  const [museUsageError, setMuseUsageError] = useState<string | null>(null)

  // Auto-refresh config in seconds (0 = off), default 30 minutes
  const [refreshInterval, setRefreshInterval] = useState(30 * 60)
  const [nextRefreshIn, setNextRefreshIn] = useState(0)
  const [lastHealthCheck, setLastHealthCheck] = useState<string | null>(null)
  const [savingInterval, setSavingInterval] = useState(false)
  const [intervalLoaded, setIntervalLoaded] = useState(false)

  // Format seconds into readable string
  const formatDuration = (seconds: number): string => {
    if (seconds === 0) return ''
    const d = Math.floor(seconds / 86400)
    const h = Math.floor((seconds % 86400) / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = seconds % 60
    const parts: string[] = []
    if (d > 0) parts.push(`${d} day${d !== 1 ? 's' : ''}`)
    if (h > 0) parts.push(`${h} hr${h !== 1 ? 's' : ''}`)
    if (m > 0) parts.push(`${m} min${m !== 1 ? 's' : ''}`)
    if (s > 0 && d === 0 && h === 0) parts.push(`${s} sec${s !== 1 ? 's' : ''}`)
    return parts.join(' and ')
  }

  useEffect(() => {
    loadStatus()
    loadCredits()
    loadTwilioBalance()
    checkSupabaseHealth()
    loadRefreshInterval()
    loadUserAnalytics()
    loadGoogleCloudUsage()
    loadMuseUsage()
  }, [])

  async function loadMuseUsage() {
    try {
      setMuseUsageLoading(true)
      setMuseUsageError(null)

      const response = await fetch('/api/muse-usage')
      const data = await response.json()

      if (data.success) {
        setMuseUsage(data.data)
      } else {
        throw new Error(data.error || 'Failed to load Muse usage')
      }
    } catch (error) {
      console.error('Failed to load Muse usage:', error)
      setMuseUsageError(error instanceof Error ? error.message : 'Unknown error')
    } finally {
      setMuseUsageLoading(false)
    }
  }

  async function loadGoogleCloudUsage() {
    try {
      setGoogleCloudLoading(true)
      setGoogleCloudError(null)

      const response = await fetch('/api/google-cloud-usage')
      const data = await response.json()

      if (data.success) {
        setGoogleCloud(data.data)
      } else {
        throw new Error(data.error || 'Failed to load Google Cloud usage')
      }
    } catch (error) {
      console.error('Failed to load Google Cloud usage:', error)
      setGoogleCloudError(error instanceof Error ? error.message : 'Unknown error')
    } finally {
      setGoogleCloudLoading(false)
    }
  }

  async function loadRefreshInterval() {
    try {
      const response = await fetch('/api/admin-settings?key=monitoring_refresh_interval')
      const result = await response.json()
      if (result.data?.seconds !== undefined) {
        setRefreshInterval(result.data.seconds)
      }
    } catch (error) {
      console.error('Failed to load refresh interval:', error)
    } finally {
      setIntervalLoaded(true)
    }
  }

  async function saveRefreshInterval(seconds: number) {
    setSavingInterval(true)
    try {
      const response = await fetch('/api/admin-settings', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          key: 'monitoring_refresh_interval',
          value: { seconds }
        })
      })
      if (!response.ok) {
        throw new Error('Failed to save')
      }
    } catch (error) {
      console.error('Failed to save refresh interval:', error)
    } finally {
      setSavingInterval(false)
    }
  }

  async function loadUserAnalytics() {
    try {
      setAnalyticsLoading(true)
      setAnalyticsError(null)

      const response = await fetch('/api/user-analytics')
      const data = await response.json()

      if (data.success) {
        setAnalytics(data.data)
      } else {
        throw new Error(data.error || 'Failed to load analytics')
      }
    } catch (error) {
      console.error('Failed to load user analytics:', error)
      setAnalyticsError(error instanceof Error ? error.message : 'Unknown error')
    } finally {
      setAnalyticsLoading(false)
    }
  }

  useEffect(() => {
    if (refreshInterval === 0) {
      setNextRefreshIn(0)
      return
    }

    const startTime = Date.now()
    setNextRefreshIn(refreshInterval)

    const refreshTimer = setInterval(() => {
      loadStatus()
      loadCredits()
      loadTwilioBalance()
      checkSupabaseHealth()
      loadUserAnalytics()
      loadGoogleCloudUsage()
      loadMuseUsage()
    }, refreshInterval * 1000)

    const countdownTimer = setInterval(() => {
      const elapsed = Math.floor((Date.now() - startTime) / 1000)
      const remaining = Math.max(0, refreshInterval - (elapsed % refreshInterval))
      setNextRefreshIn(remaining)
    }, 1000)

    return () => {
      clearInterval(refreshTimer)
      clearInterval(countdownTimer)
    }
  }, [refreshInterval])

  async function loadTwilioBalance() {
    try {
      setTwilioLoading(true)
      setTwilioError(null)

      const response = await fetch('/api/twilio-balance')
      const data = await response.json()

      if (data.success) {
        setTwilio(data.data)
        setTwilioConfigured(true)
      } else {
        setTwilioConfigured(data.configured !== false)
        throw new Error(data.error || 'Failed to load Twilio balance')
      }
    } catch (error) {
      console.error('Failed to load Twilio balance:', error)
      setTwilioError(error instanceof Error ? error.message : 'Unknown error')
    } finally {
      setTwilioLoading(false)
    }
  }

  async function checkSupabaseHealth() {
    setSupabaseLoading(true)
    const startTime = Date.now()

    try {
      const { data, error } = await supabase
        .from('ai_config')
        .select('id')
        .limit(1)

      const latency = Date.now() - startTime

      if (error) {
        setSupabaseHealth({
          status: 'down',
          latency,
          tablesAccessible: false,
          timestamp: new Date().toISOString()
        })
      } else {
        setSupabaseHealth({
          status: 'up',
          latency,
          tablesAccessible: true,
          timestamp: new Date().toISOString()
        })
      }
    } catch (error) {
      setSupabaseHealth({
        status: 'down',
        latency: Date.now() - startTime,
        tablesAccessible: false,
        timestamp: new Date().toISOString()
      })
    } finally {
      setSupabaseLoading(false)
    }
  }

  async function loadCredits() {
    try {
      setCreditsLoading(true)
      setCreditsError(null)

      const response = await fetch('/api/openrouter-credits')

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || `HTTP ${response.status}`)
      }

      const data = await response.json()
      if (data.success) {
        setCredits(data.data)
      } else {
        throw new Error(data.error || 'Failed to load credits')
      }
    } catch (error) {
      console.error('Failed to load OpenRouter credits:', error)
      setCreditsError(error instanceof Error ? error.message : 'Unknown error')
    } finally {
      setCreditsLoading(false)
    }
  }

  async function runHealthCheck() {
    setHealthCheckRunning(true)
    setHealthCheckResult(null)

    try {
      const response = await fetch('/api/health-check', {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${process.env.NEXT_PUBLIC_HEALTH_CHECK_SECRET || 'dev-secret'}`
        }
      })

      const data = await response.json()

      if (response.ok) {
        const successCount = data.results?.filter((r: any) => r.status === 'success').length || 0
        const totalCount = data.results?.length || 0
        setHealthCheckResult({
          success: true,
          message: `${successCount}/${totalCount} models passed`,
          details: data
        })
        // Refresh all statuses and balances
        await Promise.all([
          loadStatus(),
          loadCredits(),
          loadTwilioBalance(),
          checkSupabaseHealth(),
          loadUserAnalytics(),
          loadGoogleCloudUsage(),
          loadMuseUsage()
        ])
      } else {
        setHealthCheckResult({
          success: false,
          message: data.error || 'Health check failed',
          details: data
        })
      }
    } catch (error) {
      setHealthCheckResult({
        success: false,
        message: error instanceof Error ? error.message : 'Failed to run health check'
      })
    } finally {
      setHealthCheckRunning(false)
    }
  }

  async function loadStatus() {
    try {
      const { data: configs, error: configError } = await supabase
        .from('ai_config')
        .select('model_id, model_name, category')
        .eq('is_active', true)

      if (configError) {
        console.error('Error loading ai_config:', configError)
        setLoading(false)
        return
      }

      if (!configs) return

      const statuses: ServiceStatus[] = []

      for (const config of configs) {
        const { data: checks } = await supabase
          .from('api_health_checks')
          .select('*')
          .eq('model_id', config.model_id)
          .order('checked_at', { ascending: false })
          .limit(5)

        if (!checks || checks.length === 0) {
          statuses.push({
            model_id: config.model_id,
            model_name: config.model_name,
            category: config.category,
            status: 'unknown',
            lastChecked: 'Never',
            consecutiveFailures: 0,
            avgResponseTime: 0
          })
          continue
        }

        let consecutiveFailures = 0
        for (const check of checks) {
          if (check.status === 'success') break
          consecutiveFailures++
        }

        const lastCheck = checks[0]
        const avgResponseTime = Math.round(
          checks.reduce((sum, c) => sum + (c.response_time_ms || 0), 0) / checks.length
        )

        statuses.push({
          model_id: config.model_id,
          model_name: config.model_name,
          category: config.category,
          status: consecutiveFailures === 0 ? 'up' : 'down',
          lastChecked: new Date(lastCheck.checked_at).toLocaleString(),
          consecutiveFailures,
          avgResponseTime
        })
      }

      setServices(statuses)

      const allUp = statuses.every(s => s.status === 'up')
      const { data: last24h } = await supabase
        .from('api_health_checks')
        .select('status')
        .gte('checked_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())

      const totalChecks = last24h?.length || 0
      const successCount = last24h?.filter(c => c.status === 'success').length || 0
      const successRate = totalChecks > 0 ? (successCount / totalChecks) * 100 : 0

      setStats({ allUp, totalChecks, successRate })

      // Get the most recent health check timestamp
      const { data: latestCheck } = await supabase
        .from('api_health_checks')
        .select('checked_at')
        .order('checked_at', { ascending: false })
        .limit(1)
        .single()

      if (latestCheck) {
        setLastHealthCheck(latestCheck.checked_at)
      }

      setLoading(false)

    } catch (error) {
      console.error('Failed to load monitoring status:', error)
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-lg text-gray-600">Loading...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <div className="max-w-5xl mx-auto space-y-4">
        {/* Header Row */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <h1 className="text-xl font-bold">Service Monitor</h1>
            <span className={`px-2 py-0.5 rounded text-xs font-medium ${
              stats.allUp ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
            }`}>
              {stats.allUp ? 'All Systems OK' : 'Issues Detected'}
            </span>
            <span className="text-xs text-gray-500">
              {stats.successRate.toFixed(0)}% uptime (24h)
            </span>
          </div>
          <div className="flex gap-2">
            <button
              onClick={runHealthCheck}
              disabled={healthCheckRunning}
              className={`px-3 py-1.5 text-sm text-white rounded transition ${
                healthCheckRunning ? 'bg-orange-400 cursor-not-allowed' : 'bg-orange-500 hover:bg-orange-600'
              }`}
            >
              {healthCheckRunning ? 'Running...' : 'Run Check'}
            </button>
            <button
              onClick={() => {
                setLoading(true)
                loadStatus()
                loadCredits()
                loadTwilioBalance()
                checkSupabaseHealth()
                loadUserAnalytics()
                loadGoogleCloudUsage()
                loadMuseUsage()
              }}
              className="px-3 py-1.5 text-sm bg-gray-200 text-gray-700 rounded hover:bg-gray-300 transition"
            >
              Refresh
            </button>
          </div>
        </div>

        {/* Health Check Result (compact) */}
        {healthCheckResult && (
          <div className={`px-3 py-2 rounded text-sm flex items-center gap-3 ${
            healthCheckResult.success ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'
          }`}>
            <span>{healthCheckResult.success ? '✓' : '✗'}</span>
            <span className="font-medium">{healthCheckResult.message}</span>
            {healthCheckResult.details?.results && (
              <div className="flex gap-2 ml-auto">
                {healthCheckResult.details.results.map((r: any, i: number) => (
                  <span key={i} className="flex items-center gap-1 text-xs">
                    <span className={r.status === 'success' ? 'text-green-500' : 'text-red-500'}>●</span>
                    {r.category}
                  </span>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Service Status Grid - All 4 services in one row */}
        <div className="grid grid-cols-4 gap-3">
          {/* OpenRouter */}
          <div className="bg-white rounded-lg shadow-sm p-3 border-l-4 border-blue-500">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold text-gray-500 uppercase">OpenRouter</span>
              {!creditsLoading && !creditsError && credits && (
                <span className="text-green-500 text-xs">●</span>
              )}
            </div>
            {creditsLoading ? (
              <div className="text-xs text-gray-400">Loading...</div>
            ) : creditsError ? (
              <div className="text-xs text-red-500">{creditsError}</div>
            ) : credits ? (
              <div className="space-y-1">
                {credits.accountBalance !== null && (
                  <div className="flex justify-between items-baseline">
                    <span className="text-xs text-gray-500">Balance</span>
                    <span className="text-lg font-bold text-blue-600">${credits.accountBalance.toFixed(2)}</span>
                  </div>
                )}
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">Usage</span>
                  <span className="font-medium">${credits.usage.toFixed(4)}</span>
                </div>
                {credits.limitRemaining !== null && (
                  <div className="flex justify-between text-xs">
                    <span className="text-gray-500">Remaining</span>
                    <span className={`font-medium ${credits.limitRemaining < 1 ? 'text-red-500' : 'text-green-600'}`}>
                      ${credits.limitRemaining.toFixed(2)}
                    </span>
                  </div>
                )}
              </div>
            ) : null}
          </div>

          {/* Twilio */}
          <div className="bg-white rounded-lg shadow-sm p-3 border-l-4 border-purple-500">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold text-gray-500 uppercase">Twilio SMS</span>
              {!twilioLoading && twilioConfigured && twilio && (
                <span className={twilio.status === 'active' ? 'text-green-500 text-xs' : 'text-yellow-500 text-xs'}>●</span>
              )}
            </div>
            {twilioLoading ? (
              <div className="text-xs text-gray-400">Loading...</div>
            ) : !twilioConfigured ? (
              <div className="text-xs text-yellow-600">Not configured</div>
            ) : twilioError ? (
              <div className="text-xs text-red-500">{twilioError}</div>
            ) : twilio ? (
              <div className="space-y-1">
                <div className="flex justify-between items-baseline">
                  <span className="text-xs text-gray-500">Balance</span>
                  <span className="text-lg font-bold text-purple-600">${twilio.balance.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">Status</span>
                  <span className="font-medium capitalize">{twilio.status}</span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">Phone</span>
                  <span className="font-mono">{twilio.twilioPhoneNumber}</span>
                </div>
              </div>
            ) : null}
          </div>

          {/* Supabase */}
          <div className="bg-white rounded-lg shadow-sm p-3 border-l-4 border-emerald-500">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold text-gray-500 uppercase">Supabase</span>
              {!supabaseLoading && supabaseHealth && (
                <span className={supabaseHealth.status === 'up' ? 'text-green-500 text-xs' : 'text-red-500 text-xs'}>●</span>
              )}
            </div>
            {supabaseLoading ? (
              <div className="text-xs text-gray-400">Checking...</div>
            ) : supabaseHealth ? (
              <div className="space-y-1">
                <div className="flex justify-between items-baseline">
                  <span className="text-xs text-gray-500">Status</span>
                  <span className={`text-lg font-bold ${supabaseHealth.status === 'up' ? 'text-emerald-600' : 'text-red-600'}`}>
                    {supabaseHealth.status === 'up' ? 'Healthy' : 'Down'}
                  </span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">Latency</span>
                  <span className="font-medium">{supabaseHealth.latency}ms</span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">Tables</span>
                  <span className={supabaseHealth.tablesAccessible ? 'text-green-600' : 'text-red-600'}>
                    {supabaseHealth.tablesAccessible ? 'Accessible' : 'Error'}
                  </span>
                </div>
              </div>
            ) : null}
          </div>

          {/* Google Cloud TTS */}
          <div className="bg-white rounded-lg shadow-sm p-3 border-l-4 border-amber-500">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold text-gray-500 uppercase">Google TTS</span>
              {!googleCloudLoading && googleCloud && (
                <span className="text-green-500 text-xs">Active</span>
              )}
            </div>
            {googleCloudLoading ? (
              <div className="text-xs text-gray-400">Loading...</div>
            ) : googleCloudError ? (
              <div className="text-xs text-red-500">{googleCloudError}</div>
            ) : googleCloud ? (
              <div className="space-y-1">
                <div className="flex justify-between items-baseline">
                  <span className="text-xs text-gray-500">Est. Cost</span>
                  <span className="text-lg font-bold text-amber-600">${googleCloud.currentMonth.estimatedCost.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">TTS Plays</span>
                  <span className="font-medium">{googleCloud.currentMonth.googleTTSPlays.toLocaleString()}</span>
                </div>
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">Proj. Monthly</span>
                  <span className="font-medium text-amber-600">${googleCloud.projections.monthlyCost.toFixed(2)}</span>
                </div>
              </div>
            ) : null}
          </div>
        </div>

        {/* Last Health Check + Auto-refresh */}
        <div className="bg-white rounded-lg shadow-sm px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <span className="text-sm font-medium text-gray-700">Last Health Check:</span>
              <span className="text-sm text-gray-600">
                {lastHealthCheck ? new Date(lastHealthCheck).toLocaleString() : 'Never'}
              </span>
              <span className="text-xs text-gray-400">({stats.totalChecks} checks in 24h)</span>
            </div>
            <div className="flex items-center gap-2 text-xs">
              <span className="text-gray-500">Auto-refresh:</span>
              <button
                onClick={() => setRefreshInterval(0)}
                className={`px-2 py-0.5 rounded transition ${
                  refreshInterval === 0
                    ? 'bg-gray-700 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                Off
              </button>
              <div className="flex items-center gap-1 bg-gray-100 rounded px-1.5 py-0.5">
                <input
                  type="number"
                  min="0"
                  max="7"
                  value={Math.floor(refreshInterval / 86400)}
                  onChange={(e) => {
                    const days = Math.max(0, parseInt(e.target.value) || 0)
                    const currentHours = Math.floor((refreshInterval % 86400) / 3600)
                    const currentMins = Math.floor((refreshInterval % 3600) / 60)
                    setRefreshInterval(days * 86400 + currentHours * 3600 + currentMins * 60)
                  }}
                  className="w-8 bg-transparent text-center text-gray-600 focus:outline-none"
                />
                <span className="text-gray-500">d</span>
                <input
                  type="number"
                  min="0"
                  max="23"
                  value={Math.floor((refreshInterval % 86400) / 3600)}
                  onChange={(e) => {
                    const hours = Math.min(23, Math.max(0, parseInt(e.target.value) || 0))
                    const currentDays = Math.floor(refreshInterval / 86400)
                    const currentMins = Math.floor((refreshInterval % 3600) / 60)
                    setRefreshInterval(currentDays * 86400 + hours * 3600 + currentMins * 60)
                  }}
                  className="w-8 bg-transparent text-center text-gray-600 focus:outline-none"
                />
                <span className="text-gray-500">h</span>
                <input
                  type="number"
                  min="0"
                  max="59"
                  value={Math.floor((refreshInterval % 3600) / 60)}
                  onChange={(e) => {
                    const mins = Math.min(59, Math.max(0, parseInt(e.target.value) || 0))
                    const currentDays = Math.floor(refreshInterval / 86400)
                    const currentHours = Math.floor((refreshInterval % 86400) / 3600)
                    setRefreshInterval(currentDays * 86400 + currentHours * 3600 + mins * 60)
                  }}
                  className="w-8 bg-transparent text-center text-gray-600 focus:outline-none"
                />
                <span className="text-gray-500">m</span>
              </div>
              <button
                onClick={() => saveRefreshInterval(refreshInterval)}
                disabled={savingInterval}
                className="px-2 py-0.5 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:bg-blue-300 transition"
              >
                {savingInterval ? '...' : 'Save'}
              </button>
            </div>
          </div>
          {refreshInterval > 0 && (
            <div className="text-xs text-gray-400 mt-2">
              Check will run every <span className="font-medium text-gray-500">{formatDuration(refreshInterval)}</span>
              {nextRefreshIn > 0 && (
                <span> — next check in <span className="font-medium text-gray-500">{formatDuration(nextRefreshIn)}</span></span>
              )}
            </div>
          )}
        </div>

        {/* AI Models Table */}
        <div className="bg-white rounded-lg shadow-sm overflow-hidden">
          <div className="px-3 py-2 border-b bg-gray-50">
            <span className="text-sm font-semibold text-gray-700">AI Models</span>
          </div>
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-xs text-gray-500 uppercase">
              <tr>
                <th className="px-3 py-2 text-left">Status</th>
                <th className="px-3 py-2 text-left">Category</th>
                <th className="px-3 py-2 text-left">Model</th>
                <th className="px-3 py-2 text-right">Response</th>
                <th className="px-3 py-2 text-right">Last Check</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {services.map((service) => (
                <tr key={`${service.category}-${service.model_id}`} className="hover:bg-gray-50">
                  <td className="px-3 py-2">
                    <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-xs font-medium ${
                      service.status === 'up' ? 'bg-green-100 text-green-700' :
                      service.status === 'down' ? 'bg-red-100 text-red-700' :
                      'bg-gray-100 text-gray-600'
                    }`}>
                      <span className={
                        service.status === 'up' ? 'text-green-500' :
                        service.status === 'down' ? 'text-red-500' :
                        'text-gray-400'
                      }>●</span>
                      {service.status.toUpperCase()}
                    </span>
                    {service.consecutiveFailures > 0 && (
                      <span className="ml-2 text-xs text-red-500" title={`${service.consecutiveFailures} consecutive failures`}>
                        ({service.consecutiveFailures}x)
                      </span>
                    )}
                  </td>
                  <td className="px-3 py-2">
                    <span className="font-medium capitalize">{service.category}</span>
                  </td>
                  <td className="px-3 py-2">
                    <div className="font-medium text-gray-900">{service.model_name}</div>
                    <div className="text-xs text-gray-400 font-mono truncate max-w-xs">{service.model_id}</div>
                  </td>
                  <td className="px-3 py-2 text-right">
                    <span className={`font-mono ${service.avgResponseTime > 3000 ? 'text-orange-600' : 'text-gray-600'}`}>
                      {service.avgResponseTime}ms
                    </span>
                  </td>
                  <td className="px-3 py-2 text-right text-gray-500 text-xs">
                    {service.lastChecked}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Setup Hint (compact) */}
        {services.length > 0 && services.every(s => s.status === 'unknown') && (
          <div className="bg-yellow-50 border border-yellow-200 rounded px-3 py-2 text-xs text-yellow-700">
            <strong>No health checks yet.</strong> Click &quot;Run Check&quot; to test models, or set up cron-job.org to call <code className="bg-yellow-100 px-1 rounded">/api/health-check</code> every 15 min.
          </div>
        )}

        {/* User Analytics */}
        <div className="bg-white rounded-lg shadow-sm overflow-hidden">
          <div className="px-3 py-2 border-b bg-gray-50">
            <span className="text-sm font-semibold text-gray-700">User Analytics</span>
          </div>
          {analyticsLoading ? (
            <div className="p-4 text-center text-gray-400 text-sm">Loading analytics...</div>
          ) : analyticsError ? (
            <div className="p-4 text-center text-red-500 text-sm">{analyticsError}</div>
          ) : analytics ? (
            <div className="p-4">
              <div className="grid grid-cols-2 gap-4">
                {/* Users Section */}
                <div className="space-y-3">
                  <h3 className="text-xs font-semibold text-gray-500 uppercase">Users</h3>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-2xl font-bold text-gray-800">{analytics.users.total}</div>
                      <div className="text-xs text-gray-500">Total Users</div>
                    </div>
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-2xl font-bold text-green-600">{analytics.users.activeToday}</div>
                      <div className="text-xs text-gray-500">Active Today</div>
                    </div>
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-2xl font-bold text-gray-600">{analytics.users.free}</div>
                      <div className="text-xs text-gray-500">Free Users</div>
                    </div>
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-2xl font-bold text-purple-600">{analytics.users.premium}</div>
                      <div className="text-xs text-gray-500">Premium Users</div>
                    </div>
                  </div>
                  <div className="text-xs text-gray-400">
                    {analytics.users.activeWeek} active in last 7 days
                  </div>
                </div>

                {/* Messages Section */}
                <div className="space-y-3">
                  <h3 className="text-xs font-semibold text-gray-500 uppercase">Messages</h3>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-2xl font-bold text-gray-800">{analytics.messages.total.toLocaleString()}</div>
                      <div className="text-xs text-gray-500">Total Messages</div>
                    </div>
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-2xl font-bold text-blue-600">{analytics.messages.today.toLocaleString()}</div>
                      <div className="text-xs text-gray-500">Today</div>
                    </div>
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-lg font-bold text-gray-600">{analytics.messages.avgPerFreeUser}</div>
                      <div className="text-xs text-gray-500">Avg/Free User</div>
                    </div>
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-lg font-bold text-purple-600">{analytics.messages.avgPerPremiumUser}</div>
                      <div className="text-xs text-gray-500">Avg/Premium User</div>
                    </div>
                  </div>
                  <div className="flex justify-between text-xs text-gray-400">
                    <span>{analytics.messages.week.toLocaleString()} in last 7 days</span>
                    <span>{analytics.messages.avgPerUser} avg/user</span>
                  </div>
                </div>
              </div>
            </div>
          ) : null}
        </div>

        {/* Muse Usage */}
        <div className="bg-white rounded-lg shadow-sm overflow-hidden">
          <div className="px-3 py-2 border-b bg-gray-50">
            <span className="text-sm font-semibold text-gray-700">Muse Usage (AI Practice Partners)</span>
          </div>
          {museUsageLoading ? (
            <div className="p-4 text-center text-gray-400 text-sm">Loading Muse usage...</div>
          ) : museUsageError ? (
            <div className="p-4 text-center text-red-500 text-sm">{museUsageError}</div>
          ) : museUsage ? (
            <div className="p-4">
              <div className="grid grid-cols-2 gap-4">
                {/* Summary Section */}
                <div className="space-y-3">
                  <h3 className="text-xs font-semibold text-gray-500 uppercase">Interactions</h3>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-2xl font-bold text-gray-800">{museUsage.summary.totalInteractions.toLocaleString()}</div>
                      <div className="text-xs text-gray-500">Total</div>
                    </div>
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-2xl font-bold text-pink-600">{museUsage.summary.interactionsToday.toLocaleString()}</div>
                      <div className="text-xs text-gray-500">Today</div>
                    </div>
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-lg font-bold text-gray-600">{museUsage.summary.uniqueUsers}</div>
                      <div className="text-xs text-gray-500">Unique Users</div>
                    </div>
                    <div className="bg-gray-50 rounded p-2">
                      <div className="text-lg font-bold text-pink-600">{museUsage.summary.avgPerUser}</div>
                      <div className="text-xs text-gray-500">Avg/User</div>
                    </div>
                  </div>
                  <div className="text-xs text-gray-400">
                    {museUsage.summary.interactionsWeek.toLocaleString()} in last 7 days • {museUsage.summary.uniqueUsersToday} users today
                  </div>
                </div>

                {/* By Muse Section */}
                <div className="space-y-3">
                  <h3 className="text-xs font-semibold text-gray-500 uppercase">By Muse</h3>
                  <div className="space-y-2 max-h-40 overflow-y-auto">
                    {museUsage.byMuse.length > 0 ? (
                      museUsage.byMuse.slice(0, 6).map((muse) => (
                        <div key={muse.museId} className="flex justify-between items-center bg-gray-50 rounded px-2 py-1">
                          <div>
                            <span className="font-medium text-sm">{muse.museName}</span>
                            <span className="text-xs text-gray-400 ml-2">{muse.language}</span>
                          </div>
                          <span className="text-sm font-bold text-pink-600">{muse.interactions.toLocaleString()}</span>
                        </div>
                      ))
                    ) : (
                      <div className="text-xs text-gray-400 text-center py-4">No Muse interactions yet</div>
                    )}
                  </div>
                  {museUsage.byLanguage.length > 0 && (
                    <div className="flex flex-wrap gap-1 pt-2 border-t">
                      {museUsage.byLanguage.slice(0, 5).map((lang) => (
                        <span key={lang.language} className="text-xs bg-pink-100 text-pink-700 px-2 py-0.5 rounded">
                          {lang.language}: {lang.interactions}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          ) : null}
        </div>
      </div>
    </div>
  )
}
