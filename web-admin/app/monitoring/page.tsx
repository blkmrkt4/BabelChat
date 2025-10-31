'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'

interface ServiceStatus {
  model_id: string
  category: string
  status: 'up' | 'down' | 'unknown'
  lastChecked: string
  consecutiveFailures: number
  avgResponseTime: number
}

export default function MonitoringPage() {
  const [services, setServices] = useState<ServiceStatus[]>([])
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState({
    allUp: false,
    totalChecks: 0,
    successRate: 0
  })

  useEffect(() => {
    loadStatus()

    // Refresh every 30 seconds
    const interval = setInterval(loadStatus, 30000)
    return () => clearInterval(interval)
  }, [])

  async function loadStatus() {
    const supabase = createClient()

    try {
      // Get all active models
      const { data: configs } = await supabase
        .from('ai_model_config')
        .select('model_id, category')
        .eq('is_active', true)

      if (!configs) return

      // Get recent health checks for each model
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
            category: config.category,
            status: 'unknown',
            lastChecked: 'Never',
            consecutiveFailures: 0,
            avgResponseTime: 0
          })
          continue
        }

        // Count consecutive failures from most recent
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
          category: config.category,
          status: consecutiveFailures === 0 ? 'up' : 'down',
          lastChecked: new Date(lastCheck.checked_at).toLocaleString(),
          consecutiveFailures,
          avgResponseTime
        })
      }

      setServices(statuses)

      // Calculate overall stats
      const allUp = statuses.every(s => s.status === 'up')
      const { data: last24h } = await supabase
        .from('api_health_checks')
        .select('status')
        .gte('checked_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())

      const totalChecks = last24h?.length || 0
      const successCount = last24h?.filter(c => c.status === 'success').length || 0
      const successRate = totalChecks > 0 ? (successCount / totalChecks) * 100 : 0

      setStats({ allUp, totalChecks, successRate })
      setLoading(false)

    } catch (error) {
      console.error('Failed to load monitoring status:', error)
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-xl">Loading status...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">LangChat Service Status</h1>
          <p className="text-gray-600">Last updated: {new Date().toLocaleTimeString()}</p>
        </div>

        {/* Overall Status Banner */}
        <div className={`p-6 rounded-lg mb-8 ${
          stats.allUp
            ? 'bg-green-100 border-2 border-green-500'
            : 'bg-red-100 border-2 border-red-500'
        }`}>
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center gap-3">
                <div className={`text-4xl ${stats.allUp ? '✅' : '🚨'}`}>
                  {stats.allUp ? '✅' : '🚨'}
                </div>
                <div>
                  <h2 className="text-2xl font-bold">
                    {stats.allUp ? 'All Systems Operational' : 'Service Disruption Detected'}
                  </h2>
                  <p className="text-gray-700">
                    Success Rate (24h): {stats.successRate.toFixed(1)}% ({stats.totalChecks} checks)
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Service Status Cards */}
        <div className="space-y-4">
          <h3 className="text-xl font-semibold mb-4">Service Details</h3>

          {services.map((service) => (
            <div
              key={service.model_id}
              className={`bg-white p-6 rounded-lg shadow border-l-4 ${
                service.status === 'up'
                  ? 'border-green-500'
                  : service.status === 'down'
                  ? 'border-red-500'
                  : 'border-gray-400'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <span className="text-2xl">
                      {service.status === 'up' ? '🟢' : service.status === 'down' ? '🔴' : '⚪'}
                    </span>
                    <div>
                      <h4 className="font-bold text-lg">{service.category.toUpperCase()}</h4>
                      <p className="text-sm text-gray-600 font-mono">{service.model_id}</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-3 gap-4 mt-3">
                    <div>
                      <div className="text-xs text-gray-500">Status</div>
                      <div className={`font-semibold ${
                        service.status === 'up' ? 'text-green-600' :
                        service.status === 'down' ? 'text-red-600' :
                        'text-gray-600'
                      }`}>
                        {service.status.toUpperCase()}
                      </div>
                    </div>

                    <div>
                      <div className="text-xs text-gray-500">Last Checked</div>
                      <div className="font-semibold">{service.lastChecked}</div>
                    </div>

                    <div>
                      <div className="text-xs text-gray-500">Avg Response Time</div>
                      <div className="font-semibold">{service.avgResponseTime}ms</div>
                    </div>
                  </div>

                  {service.consecutiveFailures > 0 && (
                    <div className="mt-3 p-3 bg-red-50 rounded">
                      <span className="text-red-700 font-semibold">
                        ⚠️ {service.consecutiveFailures} consecutive failures detected
                      </span>
                      {service.consecutiveFailures >= 3 && (
                        <span className="text-red-600 ml-2">• SMS alert sent</span>
                      )}
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Manual Refresh Button */}
        <div className="mt-8 flex justify-center">
          <button
            onClick={() => {
              setLoading(true)
              loadStatus()
            }}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
          >
            Refresh Status
          </button>
        </div>
      </div>
    </div>
  )
}
