'use client'

import { useEffect, useState } from 'react'

interface OpenRouterHealth {
  status: string
  healthy: boolean
  message?: string
  warning?: string
  actionRequired?: boolean
  keyInfo?: {
    label: string
    limit: number
    usage: number
    usagePercent: number
    limitRemaining: number
  }
  lastChecked?: string
}

export function OpenRouterStatus() {
  const [health, setHealth] = useState<OpenRouterHealth | null>(null)
  const [loading, setLoading] = useState(true)

  const checkHealth = async () => {
    setLoading(true)
    try {
      const res = await fetch('/api/health/openrouter')
      const data = await res.json()
      setHealth(data)
    } catch (error) {
      setHealth({
        status: 'error',
        healthy: false,
        message: 'Failed to check status',
      })
    }
    setLoading(false)
  }

  useEffect(() => {
    checkHealth()
    // Check every 5 minutes
    const interval = setInterval(checkHealth, 5 * 60 * 1000)
    return () => clearInterval(interval)
  }, [])

  if (loading && !health) {
    return (
      <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
        <div className="animate-pulse flex items-center gap-2">
          <div className="w-3 h-3 bg-gray-300 rounded-full"></div>
          <div className="h-4 bg-gray-300 rounded w-32"></div>
        </div>
      </div>
    )
  }

  if (!health) return null

  const getStatusColor = () => {
    if (!health.healthy) return 'bg-red-500'
    if (health.warning) return 'bg-yellow-500'
    return 'bg-green-500'
  }

  const getStatusBg = () => {
    if (!health.healthy) return 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800'
    if (health.warning) return 'bg-yellow-50 dark:bg-yellow-900/20 border-yellow-200 dark:border-yellow-800'
    return 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800'
  }

  return (
    <div className={`rounded-lg p-4 border ${getStatusBg()}`}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className={`w-3 h-3 rounded-full ${getStatusColor()} ${health.healthy && !health.warning ? 'animate-pulse' : ''}`}></div>
          <div>
            <div className="font-medium text-gray-900 dark:text-white flex items-center gap-2">
              OpenRouter API
              {loading && <span className="text-xs text-gray-500">(checking...)</span>}
            </div>
            {health.keyInfo && (
              <div className="text-sm text-gray-600 dark:text-gray-400">
                Usage: ${health.keyInfo.usage?.toFixed(2) || '0.00'} / ${health.keyInfo.limit?.toFixed(2) || '∞'}
                {health.keyInfo.usagePercent !== null && (
                  <span className="ml-2">({health.keyInfo.usagePercent}%)</span>
                )}
              </div>
            )}
          </div>
        </div>

        {health.keyInfo?.usagePercent != null && (
          <div className="w-24 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
            <div
              className={`h-full transition-all ${
                health.keyInfo!.usagePercent >= 90 ? 'bg-red-500' :
                health.keyInfo!.usagePercent >= 75 ? 'bg-yellow-500' :
                'bg-green-500'
              }`}
              style={{ width: `${Math.min(health.keyInfo!.usagePercent, 100)}%` }}
            />
          </div>
        )}
      </div>

      {(health.warning || health.message) && (
        <div className={`mt-2 text-sm ${health.healthy ? 'text-yellow-700 dark:text-yellow-400' : 'text-red-700 dark:text-red-400'}`}>
          {health.warning || health.message}
        </div>
      )}

      {health.actionRequired && (
        <a
          href="https://openrouter.ai/settings/keys"
          target="_blank"
          rel="noopener noreferrer"
          className="mt-2 inline-block text-sm text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 underline"
        >
          Manage API keys →
        </a>
      )}

      <button
        onClick={checkHealth}
        disabled={loading}
        className="mt-2 text-xs text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
      >
        Refresh status
      </button>
    </div>
  )
}
