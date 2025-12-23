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
  pro_price_usd: number
  pro_banner: string
  pro_features: Feature[]
  free_features: Feature[]
  weekly_pricing_countries: string[]  // Country codes that show weekly pricing
  updated_at: string
}

// Common country codes for reference
const COUNTRY_OPTIONS = [
  { code: 'IN', name: 'India', flag: '🇮🇳' },
  { code: 'BR', name: 'Brazil', flag: '🇧🇷' },
  { code: 'MX', name: 'Mexico', flag: '🇲🇽' },
  { code: 'ID', name: 'Indonesia', flag: '🇮🇩' },
  { code: 'PH', name: 'Philippines', flag: '🇵🇭' },
  { code: 'VN', name: 'Vietnam', flag: '🇻🇳' },
  { code: 'TH', name: 'Thailand', flag: '🇹🇭' },
  { code: 'MY', name: 'Malaysia', flag: '🇲🇾' },
  { code: 'TR', name: 'Turkey', flag: '🇹🇷' },
  { code: 'EG', name: 'Egypt', flag: '🇪🇬' },
  { code: 'NG', name: 'Nigeria', flag: '🇳🇬' },
  { code: 'ZA', name: 'South Africa', flag: '🇿🇦' },
  { code: 'CO', name: 'Colombia', flag: '🇨🇴' },
  { code: 'PE', name: 'Peru', flag: '🇵🇪' },
  { code: 'PK', name: 'Pakistan', flag: '🇵🇰' },
  { code: 'BD', name: 'Bangladesh', flag: '🇧🇩' },
  { code: 'AR', name: 'Argentina', flag: '🇦🇷' },
  { code: 'CL', name: 'Chile', flag: '🇨🇱' },
]

const TITLE_MAX_LENGTH = 55
const SUBTITLE_MAX_LENGTH = 50
const BANNER_MAX_LENGTH = 45

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
      // Set defaults if table doesn't exist yet (matches gold standard from iOS)
      const defaults: PricingConfig = {
        premium_price_usd: 9.99,
        premium_banner: '7-Day Free Trial • Cancel Anytime',
        premium_features: [
          { title: 'Match with real people worldwide', subtitle: '', included: true },
          { title: 'Unlimited messages', subtitle: '', included: true },
          { title: 'Full translation & grammar insights', subtitle: '', included: true },
          { title: '200 Text-to-Speech plays/month with natural voices', subtitle: '', included: true },
        ],
        pro_price_usd: 19.99,
        pro_banner: 'Best Value for Serious Learners',
        pro_features: [
          { title: 'Everything in Premium', subtitle: '', included: true },
          { title: 'Unlimited Text-to-Speech plays', subtitle: '', included: true },
          { title: 'Natural voices (Google Neural2)', subtitle: '', included: true },
          { title: 'Higher word limit per play - 150 vs 100 for Premium', subtitle: '', included: true },
        ],
        free_features: [
          { title: 'No matching with real people - AI Muse chats only', subtitle: '', included: true },
          { title: '50 messages per month', subtitle: '', included: true },
          { title: 'Full translation & grammar insights', subtitle: '', included: true },
          { title: 'Basic text to speech', subtitle: '', included: true },
        ],
        weekly_pricing_countries: ['IN', 'BR', 'MX', 'ID', 'PH', 'VN', 'TH', 'MY'],
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

  function updateProFeature(index: number, field: 'title' | 'subtitle' | 'included', value: string | boolean) {
    if (!config) return
    const features = [...config.pro_features]
    features[index] = { ...features[index], [field]: value }
    updateConfig({ pro_features: features })
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

  function addProFeature() {
    if (!config) return
    updateConfig({
      pro_features: [...config.pro_features, { title: 'New Feature', subtitle: 'Description', included: true }]
    })
  }

  function removeProFeature(index: number) {
    if (!config) return
    const features = config.pro_features.filter((_, i) => i !== index)
    updateConfig({ pro_features: features })
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

        <div className="grid grid-cols-3 gap-4">
          {/* Free Tier */}
          <div className="bg-white rounded-lg shadow-sm p-4 space-y-4">
            <div className="flex items-center justify-between border-b pb-2">
              <h2 className="font-bold text-gray-700">Free Tier</h2>
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
              <div className="space-y-2 max-h-60 overflow-y-auto">
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

          {/* Premium Tier */}
          <div className="bg-white rounded-lg shadow-sm p-4 space-y-4">
            <div className="flex items-center justify-between border-b pb-2">
              <h2 className="font-bold text-purple-700">Premium Tier</h2>
              <span className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded">$9.99/mo</span>
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
                  className="w-20 px-2 py-1 border rounded text-lg font-bold focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
                <span className="text-gray-500">/mo</span>
              </div>
            </div>

            {/* Banner */}
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">
                Banner ({config.premium_banner.length}/{BANNER_MAX_LENGTH})
              </label>
              <input
                type="text"
                value={config.premium_banner}
                onChange={(e) => updateConfig({ premium_banner: e.target.value.slice(0, BANNER_MAX_LENGTH) })}
                maxLength={BANNER_MAX_LENGTH}
                className="w-full px-2 py-1 border rounded text-sm focus:outline-none focus:ring-2 focus:ring-purple-500"
                placeholder="e.g., 7-Day Free Trial"
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
                  + Add
                </button>
              </div>
              <div className="space-y-2 max-h-60 overflow-y-auto">
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

          {/* Pro Tier */}
          <div className="bg-white rounded-lg shadow-sm p-4 space-y-4">
            <div className="flex items-center justify-between border-b pb-2">
              <h2 className="font-bold text-amber-700">Pro Tier</h2>
              <span className="text-xs bg-amber-100 text-amber-700 px-2 py-1 rounded">$19.99/mo</span>
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
                  value={config.pro_price_usd}
                  onChange={(e) => updateConfig({ pro_price_usd: parseFloat(e.target.value) || 0 })}
                  className="w-20 px-2 py-1 border rounded text-lg font-bold focus:outline-none focus:ring-2 focus:ring-amber-500"
                />
                <span className="text-gray-500">/mo</span>
              </div>
            </div>

            {/* Banner */}
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">
                Banner ({config.pro_banner.length}/{BANNER_MAX_LENGTH})
              </label>
              <input
                type="text"
                value={config.pro_banner}
                onChange={(e) => updateConfig({ pro_banner: e.target.value.slice(0, BANNER_MAX_LENGTH) })}
                maxLength={BANNER_MAX_LENGTH}
                className="w-full px-2 py-1 border rounded text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
                placeholder="e.g., Best Value"
              />
            </div>

            {/* Features */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-medium text-gray-500">Features</label>
                <button
                  onClick={addProFeature}
                  className="text-xs text-amber-600 hover:text-amber-800"
                >
                  + Add
                </button>
              </div>
              <div className="space-y-2 max-h-60 overflow-y-auto">
                {config.pro_features.map((feature, index) => (
                  <div key={index} className={`p-2 rounded border ${
                    feature.included ? 'bg-amber-50 border-amber-100' : 'bg-gray-50 border-gray-200'
                  }`}>
                    <div className="flex items-start gap-2">
                      <select
                        value={feature.included ? 'included' : 'excluded'}
                        onChange={(e) => updateProFeature(index, 'included', e.target.value === 'included')}
                        className={`mt-0.5 text-sm border rounded px-1 py-0.5 focus:outline-none focus:ring-1 focus:ring-amber-500 ${
                          feature.included ? 'text-amber-600 bg-amber-50' : 'text-gray-400 bg-gray-100'
                        }`}
                      >
                        <option value="included">✓</option>
                        <option value="excluded">✗</option>
                      </select>
                      <div className="flex-1 space-y-1">
                        <input
                          type="text"
                          value={feature.title}
                          onChange={(e) => updateProFeature(index, 'title', e.target.value.slice(0, TITLE_MAX_LENGTH))}
                          maxLength={TITLE_MAX_LENGTH}
                          className={`w-full px-1.5 py-0.5 text-sm font-medium border rounded focus:outline-none focus:ring-1 focus:ring-amber-500 ${
                            !feature.included ? 'text-gray-400' : ''
                          }`}
                          placeholder="Feature title"
                        />
                        <div className="flex items-center gap-1">
                          <input
                            type="text"
                            value={feature.subtitle}
                            onChange={(e) => updateProFeature(index, 'subtitle', e.target.value.slice(0, SUBTITLE_MAX_LENGTH))}
                            maxLength={SUBTITLE_MAX_LENGTH}
                            className={`flex-1 px-1.5 py-0.5 text-xs border rounded focus:outline-none focus:ring-1 focus:ring-amber-500 ${
                              !feature.included ? 'text-gray-400' : 'text-gray-600'
                            }`}
                            placeholder="Subtitle"
                          />
                          <span className="text-xs text-gray-400">{feature.title.length}/{TITLE_MAX_LENGTH}</span>
                        </div>
                      </div>
                      <button
                        onClick={() => removeProFeature(index)}
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

        {/* Weekly Pricing Countries */}
        <div className="bg-white rounded-lg shadow-sm p-4">
          <div className="flex items-center justify-between mb-3">
            <div>
              <h3 className="font-bold text-gray-700">Weekly Pricing Display</h3>
              <p className="text-xs text-gray-500">
                Users in these countries see prices as weekly (e.g., "$2.31/wk" instead of "$9.99/mo")
              </p>
            </div>
          </div>

          <div className="flex flex-wrap gap-2 mb-4">
            {config.weekly_pricing_countries.map((code) => {
              const country = COUNTRY_OPTIONS.find(c => c.code === code)
              return (
                <span
                  key={code}
                  className="inline-flex items-center gap-1 px-3 py-1.5 bg-blue-50 text-blue-700 rounded-full text-sm"
                >
                  <span>{country?.flag || '🌍'}</span>
                  <span>{country?.name || code}</span>
                  <button
                    onClick={() => {
                      const updated = config.weekly_pricing_countries.filter(c => c !== code)
                      updateConfig({ weekly_pricing_countries: updated })
                    }}
                    className="ml-1 text-blue-400 hover:text-blue-600"
                  >
                    ×
                  </button>
                </span>
              )
            })}
            {config.weekly_pricing_countries.length === 0 && (
              <span className="text-gray-400 text-sm">No countries selected - all users see monthly pricing</span>
            )}
          </div>

          <div className="flex items-center gap-2">
            <select
              className="flex-1 px-3 py-2 border rounded text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              value=""
              onChange={(e) => {
                if (e.target.value && !config.weekly_pricing_countries.includes(e.target.value)) {
                  updateConfig({
                    weekly_pricing_countries: [...config.weekly_pricing_countries, e.target.value]
                  })
                }
              }}
            >
              <option value="">+ Add country...</option>
              {COUNTRY_OPTIONS.filter(c => !config.weekly_pricing_countries.includes(c.code)).map((country) => (
                <option key={country.code} value={country.code}>
                  {country.flag} {country.name} ({country.code})
                </option>
              ))}
            </select>
          </div>

          <div className="mt-3 p-3 bg-gray-50 rounded text-xs text-gray-600">
            <strong>How it works:</strong> Monthly price is divided by 4.33 to show weekly equivalent.
            Users are still billed monthly - this is just a display format that makes prices feel more accessible in emerging markets.
          </div>
        </div>

        {/* Preview Section */}
        <div className="bg-white rounded-lg shadow-sm p-4">
          <h3 className="font-bold text-gray-700 mb-3">Preview (as shown in app)</h3>
          <div className="grid grid-cols-3 gap-4">
            {/* Free Preview */}
            <div className="border rounded-lg p-3 bg-gray-50">
              <div className="text-lg font-bold mb-1">Free</div>
              <div className="text-2xl font-bold text-gray-700 mb-2">$0</div>
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

            {/* Pro Preview */}
            <div className="border rounded-lg p-3 bg-gradient-to-br from-amber-500 to-orange-600 text-white">
              <div className="text-lg font-bold mb-1">Pro</div>
              <div className="text-2xl font-bold mb-1">${config.pro_price_usd.toFixed(2)}/mo</div>
              <div className="text-xs bg-white/20 px-2 py-1 rounded-full inline-block mb-2">
                {config.pro_banner}
              </div>
              <div className="space-y-1 text-sm">
                {config.pro_features.map((f, i) => (
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
