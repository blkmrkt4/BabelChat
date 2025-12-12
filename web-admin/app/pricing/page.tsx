'use client'

import { useState, useEffect } from 'react'

interface Feature {
  title: string
  subtitle: string
  included: boolean
}

interface PricingConfig {
  premium_price_usd: number
  premium_banner: string
  premium_features: Feature[]
  free_features: Feature[]
  updated_at: string
}

const TITLE_MAX_LENGTH = 30
const SUBTITLE_MAX_LENGTH = 40
const BANNER_MAX_LENGTH = 40

export default function PricingPage() {
  const [config, setConfig] = useState<PricingConfig | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [hasChanges, setHasChanges] = useState(false)
  const [originalConfig, setOriginalConfig] = useState<PricingConfig | null>(null)

  useEffect(() => {
    loadConfig()
  }, [])

  async function loadConfig() {
    try {
      setLoading(true)
      const response = await fetch('/api/pricing-config')
      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to load pricing config')
      }

      setConfig(result.data)
      setOriginalConfig(JSON.parse(JSON.stringify(result.data)))
      setHasChanges(false)
    } catch (error) {
      console.error('Failed to load pricing config:', error)
      // Set defaults if table doesn't exist yet
      const defaults: PricingConfig = {
        premium_price_usd: 9.99,
        premium_banner: '7-Day Free Trial • Cancel Anytime',
        premium_features: [
          { title: 'Unlimited AI Chat Messages', subtitle: 'Practice without limits', included: true },
          { title: 'Unlimited Profile Views', subtitle: 'Browse all potential matches', included: true },
          { title: 'Direct Messaging', subtitle: 'Chat directly with matches', included: true },
          { title: 'Full Conversation History', subtitle: 'Access all your past chats', included: true },
          { title: 'All Language Pairs', subtitle: 'Learn any language combination', included: true },
          { title: 'Grammar Tips & Insights', subtitle: 'AI-powered learning assistance', included: true },
        ],
        free_features: [
          { title: '5 AI Chat Messages/Day', subtitle: 'Practice with AI assistance', included: true },
          { title: 'View 10 Profiles/Day', subtitle: 'Browse potential matches', included: true },
          { title: 'Unlimited Matches', subtitle: 'Match with learners (AI chat only)', included: true },
          { title: 'Direct Messaging', subtitle: 'Premium feature', included: false },
          { title: 'Unlimited Profiles', subtitle: 'Premium feature', included: false },
        ],
        updated_at: new Date().toISOString()
      }
      setConfig(defaults)
      setOriginalConfig(JSON.parse(JSON.stringify(defaults)))
    } finally {
      setLoading(false)
    }
  }

  async function saveConfig() {
    if (!config) return

    try {
      setSaving(true)
      const response = await fetch('/api/pricing-config', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config)
      })

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to save pricing config')
      }

      setOriginalConfig(JSON.parse(JSON.stringify(config)))
      setHasChanges(false)
      alert('Pricing changes pushed successfully!')
    } catch (error) {
      console.error('Failed to save pricing config:', error)
      alert('Failed to save pricing config: ' + (error instanceof Error ? error.message : 'Unknown error'))
    } finally {
      setSaving(false)
    }
  }

  function updateConfig(updates: Partial<PricingConfig>) {
    if (!config) return
    const newConfig = { ...config, ...updates }
    setConfig(newConfig)
    setHasChanges(JSON.stringify(newConfig) !== JSON.stringify(originalConfig))
  }

  function updatePremiumFeature(index: number, field: 'title' | 'subtitle' | 'included', value: string | boolean) {
    if (!config) return
    const features = [...config.premium_features]
    features[index] = { ...features[index], [field]: value }
    updateConfig({ premium_features: features })
  }

  function updateFreeFeature(index: number, field: 'title' | 'subtitle' | 'included', value: string | boolean) {
    if (!config) return
    const features = [...config.free_features]
    features[index] = { ...features[index], [field]: value }
    updateConfig({ free_features: features })
  }

  function addPremiumFeature() {
    if (!config) return
    updateConfig({
      premium_features: [...config.premium_features, { title: 'New Feature', subtitle: 'Description', included: true }]
    })
  }

  function removePremiumFeature(index: number) {
    if (!config) return
    const features = config.premium_features.filter((_, i) => i !== index)
    updateConfig({ premium_features: features })
  }

  function addFreeFeature() {
    if (!config) return
    updateConfig({
      free_features: [...config.free_features, { title: 'New Feature', subtitle: 'Description', included: true }]
    })
  }

  function removeFreeFeature(index: number) {
    if (!config) return
    const features = config.free_features.filter((_, i) => i !== index)
    updateConfig({ free_features: features })
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-lg text-gray-600">Loading...</div>
      </div>
    )
  }

  if (!config) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-lg text-red-600">Failed to load pricing config</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <div className="max-w-5xl mx-auto space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold">Pricing Configuration</h1>
            <p className="text-sm text-gray-500">
              Changes will be reflected in the iOS app after pushing
            </p>
          </div>
          <div className="flex items-center gap-3">
            {hasChanges && (
              <span className="text-sm text-orange-600 font-medium">Unsaved changes</span>
            )}
            <button
              onClick={saveConfig}
              disabled={!hasChanges || saving}
              className={`px-4 py-2 rounded font-medium transition ${
                hasChanges && !saving
                  ? 'bg-green-600 text-white hover:bg-green-700'
                  : 'bg-gray-200 text-gray-400 cursor-not-allowed'
              }`}
            >
              {saving ? 'Pushing...' : 'Push Pricing Changes'}
            </button>
          </div>
        </div>

        {/* Last updated */}
        {config.updated_at && (
          <div className="text-xs text-gray-400">
            Last updated: {new Date(config.updated_at).toLocaleString()}
          </div>
        )}

        <div className="grid grid-cols-2 gap-4">
          {/* Premium Tier */}
          <div className="bg-white rounded-lg shadow-sm p-4 space-y-4">
            <div className="flex items-center justify-between border-b pb-2">
              <h2 className="font-bold text-purple-700">Premium Tier</h2>
              <span className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded">Paid</span>
            </div>

            {/* Price */}
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">
                Price (USD)
              </label>
              <div className="flex items-center gap-2">
                <span className="text-gray-500">$</span>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  value={config.premium_price_usd}
                  onChange={(e) => updateConfig({ premium_price_usd: parseFloat(e.target.value) || 0 })}
                  className="w-24 px-2 py-1 border rounded text-lg font-bold focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
                <span className="text-gray-500">/month</span>
              </div>
            </div>

            {/* Banner */}
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">
                Banner Text ({config.premium_banner.length}/{BANNER_MAX_LENGTH})
              </label>
              <input
                type="text"
                value={config.premium_banner}
                onChange={(e) => updateConfig({ premium_banner: e.target.value.slice(0, BANNER_MAX_LENGTH) })}
                maxLength={BANNER_MAX_LENGTH}
                className="w-full px-2 py-1 border rounded text-sm focus:outline-none focus:ring-2 focus:ring-purple-500"
                placeholder="e.g., 7-Day Free Trial • Cancel Anytime"
              />
            </div>

            {/* Features */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-medium text-gray-500">Features</label>
                <button
                  onClick={addPremiumFeature}
                  className="text-xs text-purple-600 hover:text-purple-800"
                >
                  + Add Feature
                </button>
              </div>
              <div className="space-y-2 max-h-80 overflow-y-auto">
                {config.premium_features.map((feature, index) => (
                  <div key={index} className={`p-2 rounded border ${
                    feature.included ? 'bg-purple-50 border-purple-100' : 'bg-gray-50 border-gray-200'
                  }`}>
                    <div className="flex items-start gap-2">
                      <select
                        value={feature.included ? 'included' : 'excluded'}
                        onChange={(e) => updatePremiumFeature(index, 'included', e.target.value === 'included')}
                        className={`mt-0.5 text-sm border rounded px-1 py-0.5 focus:outline-none focus:ring-1 focus:ring-purple-500 ${
                          feature.included ? 'text-yellow-600 bg-yellow-50' : 'text-gray-400 bg-gray-100'
                        }`}
                      >
                        <option value="included">✓</option>
                        <option value="excluded">✗</option>
                      </select>
                      <div className="flex-1 space-y-1">
                        <input
                          type="text"
                          value={feature.title}
                          onChange={(e) => updatePremiumFeature(index, 'title', e.target.value.slice(0, TITLE_MAX_LENGTH))}
                          maxLength={TITLE_MAX_LENGTH}
                          className={`w-full px-1.5 py-0.5 text-sm font-medium border rounded focus:outline-none focus:ring-1 focus:ring-purple-500 ${
                            !feature.included ? 'text-gray-400' : ''
                          }`}
                          placeholder="Feature title"
                        />
                        <div className="flex items-center gap-1">
                          <input
                            type="text"
                            value={feature.subtitle}
                            onChange={(e) => updatePremiumFeature(index, 'subtitle', e.target.value.slice(0, SUBTITLE_MAX_LENGTH))}
                            maxLength={SUBTITLE_MAX_LENGTH}
                            className={`flex-1 px-1.5 py-0.5 text-xs border rounded focus:outline-none focus:ring-1 focus:ring-purple-500 ${
                              !feature.included ? 'text-gray-400' : 'text-gray-600'
                            }`}
                            placeholder="Subtitle"
                          />
                          <span className="text-xs text-gray-400">{feature.title.length}/{TITLE_MAX_LENGTH}</span>
                        </div>
                      </div>
                      <button
                        onClick={() => removePremiumFeature(index)}
                        className="text-red-400 hover:text-red-600 text-xs"
                      >
                        ✕
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Free Tier */}
          <div className="bg-white rounded-lg shadow-sm p-4 space-y-4">
            <div className="flex items-center justify-between border-b pb-2">
              <h2 className="font-bold text-gray-700">Free Tier (Discovery)</h2>
              <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded">Free</span>
            </div>

            {/* Price display */}
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">
                Price
              </label>
              <div className="text-lg font-bold text-gray-700">Free</div>
            </div>

            {/* Features */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-medium text-gray-500">Features</label>
                <button
                  onClick={addFreeFeature}
                  className="text-xs text-gray-600 hover:text-gray-800"
                >
                  + Add Feature
                </button>
              </div>
              <div className="space-y-2 max-h-80 overflow-y-auto">
                {config.free_features.map((feature, index) => (
                  <div
                    key={index}
                    className={`p-2 rounded border ${
                      feature.included
                        ? 'bg-green-50 border-green-100'
                        : 'bg-gray-50 border-gray-200'
                    }`}
                  >
                    <div className="flex items-start gap-2">
                      <select
                        value={feature.included ? 'included' : 'excluded'}
                        onChange={(e) => updateFreeFeature(index, 'included', e.target.value === 'included')}
                        className={`mt-0.5 text-sm border rounded px-1 py-0.5 focus:outline-none focus:ring-1 focus:ring-gray-400 ${
                          feature.included ? 'text-green-600 bg-green-50' : 'text-gray-400 bg-gray-100'
                        }`}
                      >
                        <option value="included">✓</option>
                        <option value="excluded">✗</option>
                      </select>
                      <div className="flex-1 space-y-1">
                        <input
                          type="text"
                          value={feature.title}
                          onChange={(e) => updateFreeFeature(index, 'title', e.target.value.slice(0, TITLE_MAX_LENGTH))}
                          maxLength={TITLE_MAX_LENGTH}
                          className={`w-full px-1.5 py-0.5 text-sm font-medium border rounded focus:outline-none focus:ring-1 focus:ring-gray-400 ${
                            !feature.included ? 'text-gray-400' : ''
                          }`}
                          placeholder="Feature title"
                        />
                        <div className="flex items-center gap-1">
                          <input
                            type="text"
                            value={feature.subtitle}
                            onChange={(e) => updateFreeFeature(index, 'subtitle', e.target.value.slice(0, SUBTITLE_MAX_LENGTH))}
                            maxLength={SUBTITLE_MAX_LENGTH}
                            className={`flex-1 px-1.5 py-0.5 text-xs border rounded focus:outline-none focus:ring-1 focus:ring-gray-400 ${
                              !feature.included ? 'text-gray-400' : 'text-gray-600'
                            }`}
                            placeholder="Subtitle"
                          />
                          <span className="text-xs text-gray-400">{feature.title.length}/{TITLE_MAX_LENGTH}</span>
                        </div>
                      </div>
                      <button
                        onClick={() => removeFreeFeature(index)}
                        className="text-red-400 hover:text-red-600 text-xs"
                      >
                        ✕
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Preview Section */}
        <div className="bg-white rounded-lg shadow-sm p-4">
          <h3 className="font-bold text-gray-700 mb-3">Preview (as shown in app)</h3>
          <div className="grid grid-cols-2 gap-4">
            {/* Free Preview */}
            <div className="border rounded-lg p-3 bg-gray-50">
              <div className="text-lg font-bold mb-1">Discovery</div>
              <div className="text-2xl font-bold text-gray-700 mb-2">Free</div>
              <div className="space-y-1 text-sm">
                {config.free_features.map((f, i) => (
                  <div key={i} className={`flex items-center gap-2 ${!f.included ? 'text-gray-400' : ''}`}>
                    <span>{f.included ? '✓' : '✗'}</span>
                    <span>{f.title}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Premium Preview */}
            <div className="border rounded-lg p-3 bg-gradient-to-br from-purple-600 to-blue-600 text-white">
              <div className="text-lg font-bold mb-1">Premium</div>
              <div className="text-2xl font-bold mb-1">${config.premium_price_usd.toFixed(2)}/mo</div>
              <div className="text-xs bg-white/20 px-2 py-1 rounded-full inline-block mb-2">
                {config.premium_banner}
              </div>
              <div className="space-y-1 text-sm">
                {config.premium_features.map((f, i) => (
                  <div key={i} className={`flex items-center gap-2 ${!f.included ? 'opacity-50' : ''}`}>
                    <span className={f.included ? 'text-yellow-300' : 'text-gray-400'}>
                      {f.included ? '✓' : '✗'}
                    </span>
                    <span>{f.title}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Character limit info */}
        <div className="text-xs text-gray-400 text-center">
          Character limits: Title ({TITLE_MAX_LENGTH}), Subtitle ({SUBTITLE_MAX_LENGTH}), Banner ({BANNER_MAX_LENGTH}) - optimized for iPhone display
        </div>
      </div>
    </div>
  )
}
