'use client'

import { useState, useEffect } from 'react'

interface Config {
  phoneNumbers: {
    primary: string
    backup: string
    primaryFull: string
    backupFull: string
  }
  twilioNumber: string
  healthCheck: {
    frequency: string
    failureThreshold: number
    cooldownMinutes: number
  }
  services: Array<{ name: string; category: string }>
}

export default function SettingsPage() {
  const [testing, setTesting] = useState(false)
  const [result, setResult] = useState<{ success: boolean; message: string } | null>(null)
  const [config, setConfig] = useState<Config | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadConfig()
  }, [])

  async function loadConfig() {
    try {
      const response = await fetch('/api/config')
      const data = await response.json()
      setConfig(data)
    } catch (error) {
      console.error('Failed to load config:', error)
    } finally {
      setLoading(false)
    }
  }

  async function testSMS(recipient: 'primary' | 'backup' | 'both') {
    setTesting(true)
    setResult(null)

    try {
      if (!config) throw new Error('Configuration not loaded')

      const numbersToTest = recipient === 'both'
        ? [
            { phone: config.phoneNumbers.primaryFull, type: 'Primary' },
            { phone: config.phoneNumbers.backupFull, type: 'Backup' }
          ]
        : [
            {
              phone: recipient === 'primary'
                ? config.phoneNumbers.primaryFull
                : config.phoneNumbers.backupFull,
              type: recipient === 'primary' ? 'Primary' : 'Backup'
            }
          ]

      const results = []

      for (const { phone, type } of numbersToTest) {
        const response = await fetch('/api/test-sms', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            to: phone,
            recipientType: type
          })
        })

        const data = await response.json()
        results.push(data)
      }

      const allSuccessful = results.every(r => r.success)

      setResult({
        success: allSuccessful,
        message: allSuccessful
          ? `✅ SMS sent successfully to ${numbersToTest.length} number(s)! Check your phone(s).`
          : '❌ Some SMS failed to send. Check console for details.'
      })

    } catch (error: any) {
      setResult({
        success: false,
        message: `❌ Error: ${error.message}`
      })
    } finally {
      setTesting(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-xl">Loading settings...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold mb-8">Monitoring Settings</h1>

        {/* SMS Alert Configuration */}
        <div className="bg-white p-6 rounded-lg shadow mb-6">
          <h2 className="text-xl font-semibold mb-4">SMS Alert Configuration</h2>

          <div className="space-y-4 mb-6">
            <div>
              <div className="text-sm text-gray-600">Primary Phone Number</div>
              <div className="font-mono text-lg">{config?.phoneNumbers.primary}</div>
            </div>

            <div>
              <div className="text-sm text-gray-600">Backup Phone Number</div>
              <div className="font-mono text-lg">{config?.phoneNumbers.backup}</div>
            </div>

            <div className="pt-4 border-t">
              <div className="text-sm text-gray-600 mb-2">Alert Trigger</div>
              <div className="text-gray-800">
                SMS sent when: <span className="font-semibold">{config?.healthCheck.failureThreshold}+ consecutive failures</span> detected
              </div>
              <div className="text-sm text-gray-500 mt-1">
                (Translation, Grammar, or Scoring API is down)
              </div>
            </div>
          </div>

          {/* Test Buttons */}
          <div className="border-t pt-6">
            <h3 className="font-semibold mb-4">Test SMS Alerts</h3>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <button
                onClick={() => testSMS('primary')}
                disabled={testing}
                className="px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition"
              >
                {testing ? 'Sending...' : 'Test Primary'}
              </button>

              <button
                onClick={() => testSMS('backup')}
                disabled={testing}
                className="px-4 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition"
              >
                {testing ? 'Sending...' : 'Test Backup'}
              </button>

              <button
                onClick={() => testSMS('both')}
                disabled={testing}
                className="px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition"
              >
                {testing ? 'Sending...' : 'Test Both'}
              </button>
            </div>

            {/* Result Message */}
            {result && (
              <div className={`mt-4 p-4 rounded-lg ${
                result.success ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'
              }`}>
                {result.message}
              </div>
            )}

            <div className="mt-4 text-sm text-gray-500">
              <p>💡 Tip: Check your phone(s) for test messages. They should arrive within 5-10 seconds.</p>
              <p className="mt-1">📱 Messages will appear from: {config?.twilioNumber}</p>
            </div>
          </div>
        </div>

        {/* Current Configuration */}
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-semibold mb-4">System Configuration</h2>

          <div className="space-y-3">
            <div className="flex justify-between py-2 border-b">
              <span className="text-gray-600">Health Check Frequency</span>
              <span className="font-semibold">Every 15 minutes</span>
            </div>

            <div className="flex justify-between py-2 border-b">
              <span className="text-gray-600">Failure Threshold</span>
              <span className="font-semibold">3 consecutive failures</span>
            </div>

            <div className="flex justify-between py-2 border-b">
              <span className="text-gray-600">Alert Cooldown</span>
              <span className="font-semibold">60 minutes</span>
            </div>

            <div className="flex justify-between py-2">
              <span className="text-gray-600">Estimated Monthly Cost</span>
              <span className="font-semibold text-green-600">~$1.25 - $1.50</span>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t">
            <div className="text-sm text-gray-600 mb-2">Services Monitored</div>
            <div className="flex flex-wrap gap-2">
              <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">
                Translation API
              </span>
              <span className="px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-sm">
                Grammar Check API
              </span>
              <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm">
                Scoring API
              </span>
            </div>
          </div>
        </div>

        {/* Quick Links */}
        <div className="mt-6 flex gap-4">
          <a
            href="/monitoring"
            className="flex-1 text-center px-4 py-3 bg-gray-800 text-white rounded-lg hover:bg-gray-900 transition"
          >
            View Monitoring Dashboard
          </a>
        </div>
      </div>
    </div>
  )
}
