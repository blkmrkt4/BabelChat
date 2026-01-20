'use client'

import { useState, useEffect, useRef } from 'react'

interface Translation {
  id: string
  string_key: string
  context?: string
  language_code: string
  value: string
  source: string
  verified: boolean
  created_at: string
  updated_at: string
}

interface LanguageStats {
  total: number
  verified: number
}

interface SupportedLanguage {
  language_code: string
  language_name: string
}

// Supported languages for Fluenca (21 languages)
const SUPPORTED_LANGUAGES = [
  { code: 'en', name: 'English' },
  { code: 'es', name: 'Spanish' },
  { code: 'fr', name: 'French' },
  { code: 'de', name: 'German' },
  { code: 'it', name: 'Italian' },
  { code: 'pt', name: 'Portuguese' },
  { code: 'ja', name: 'Japanese' },
  { code: 'ko', name: 'Korean' },
  { code: 'zh', name: 'Chinese' },
  { code: 'ru', name: 'Russian' },
  { code: 'ar', name: 'Arabic' },
  { code: 'hi', name: 'Hindi' },
  { code: 'nl', name: 'Dutch' },
  { code: 'sv', name: 'Swedish' },
  { code: 'da', name: 'Danish' },
  { code: 'fi', name: 'Finnish' },
  { code: 'no', name: 'Norwegian' },
  { code: 'pl', name: 'Polish' },
  { code: 'id', name: 'Indonesian' },
  { code: 'tl', name: 'Filipino' },
  { code: 'th', name: 'Thai' },
]

export default function LocalizationPage() {
  const [translations, setTranslations] = useState<Translation[]>([])
  const [stats, setStats] = useState<{
    totalStrings: number
    languageStats: Record<string, LanguageStats>
    supportedLanguages: SupportedLanguage[]
  } | null>(null)
  const [loading, setLoading] = useState(true)
  const [selectedLanguage, setSelectedLanguage] = useState<string>('en')
  const [filter, setFilter] = useState('')
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editValue, setEditValue] = useState('')
  const [saving, setSaving] = useState(false)
  const [showImportModal, setShowImportModal] = useState(false)
  const [importText, setImportText] = useState('')
  const [importOverwrite, setImportOverwrite] = useState(false)
  const [importResult, setImportResult] = useState<{ imported: number; skipped: number; errors?: string[] } | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    loadStats()
  }, [])

  useEffect(() => {
    if (selectedLanguage) {
      loadTranslations(selectedLanguage)
    }
  }, [selectedLanguage])

  async function loadStats() {
    try {
      const response = await fetch('/api/localization/stats')
      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to load stats')
      }

      setStats(result)
    } catch (error) {
      console.error('Failed to load stats:', error)
    }
  }

  async function loadTranslations(languageCode: string) {
    try {
      setLoading(true)
      const response = await fetch(`/api/localization?language_code=${languageCode}`)
      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to load translations')
      }

      setTranslations(result.data || [])
    } catch (error) {
      console.error('Failed to load translations:', error)
    } finally {
      setLoading(false)
    }
  }

  async function saveTranslation(id: string, value: string, verified: boolean) {
    try {
      setSaving(true)
      const response = await fetch('/api/localization', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id, value, verified, source: 'human' }),
      })

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to save translation')
      }

      // Update local state
      setTranslations(prev =>
        prev.map(t => (t.id === id ? { ...t, value, verified, source: 'human' } : t))
      )
      setEditingId(null)
      loadStats() // Refresh stats
    } catch (error) {
      console.error('Failed to save translation:', error)
      alert('Failed to save translation')
    } finally {
      setSaving(false)
    }
  }

  async function toggleVerified(translation: Translation) {
    await saveTranslation(translation.id, translation.value, !translation.verified)
  }

  async function handleImport() {
    try {
      setSaving(true)
      setImportResult(null)

      let translations: any[]
      try {
        translations = JSON.parse(importText)
        if (!Array.isArray(translations)) {
          throw new Error('Must be an array')
        }
      } catch {
        alert('Invalid JSON format. Must be an array of translation objects.')
        setSaving(false)
        return
      }

      const response = await fetch('/api/localization/import', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ translations, overwrite: importOverwrite }),
      })

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to import translations')
      }

      setImportResult(result)
      loadStats()
      loadTranslations(selectedLanguage)
    } catch (error) {
      console.error('Failed to import:', error)
      alert('Failed to import translations')
    } finally {
      setSaving(false)
    }
  }

  async function handleFileUpload(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (!file) return

    const text = await file.text()
    setImportText(text)
  }

  function exportTranslations(format: 'json' | 'csv' | 'xcstrings') {
    const url = `/api/localization/export?format=${format}${selectedLanguage !== 'all' ? `&language_code=${selectedLanguage}` : ''}`
    window.open(url, '_blank')
  }

  const filteredTranslations = translations.filter(
    t =>
      t.string_key.toLowerCase().includes(filter.toLowerCase()) ||
      t.value.toLowerCase().includes(filter.toLowerCase()) ||
      (t.context && t.context.toLowerCase().includes(filter.toLowerCase()))
  )

  // Calculate language completion percentages
  const languageCompletion = SUPPORTED_LANGUAGES.map(lang => {
    const langStats = stats?.languageStats[lang.code]
    const total = langStats?.total || 0
    const verified = langStats?.verified || 0
    const percentage = stats?.totalStrings ? Math.round((total / stats.totalStrings) * 100) : 0
    const verifiedPercentage = total ? Math.round((verified / total) * 100) : 0
    return { ...lang, total, verified, percentage, verifiedPercentage }
  })

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">App Localization</h2>
          <p className="text-gray-600 mt-1">
            Manage UI string translations for the Fluenca iOS app.
            {stats && ` ${stats.totalStrings} unique strings.`}
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setShowImportModal(true)}
            className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
          >
            Import
          </button>
          <div className="relative">
            <select
              onChange={(e) => exportTranslations(e.target.value as any)}
              defaultValue=""
              className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 appearance-none pr-8 cursor-pointer"
            >
              <option value="" disabled>Export...</option>
              <option value="json">JSON</option>
              <option value="csv">CSV</option>
              <option value="xcstrings">String Catalog (.xcstrings)</option>
            </select>
          </div>
        </div>
      </div>

      {/* Language Grid */}
      <div className="bg-gray-50 rounded-lg p-4">
        <h3 className="text-lg font-semibold mb-3">Translation Coverage</h3>
        <div className="grid grid-cols-3 md:grid-cols-5 lg:grid-cols-7 gap-2">
          {languageCompletion.map(lang => (
            <button
              key={lang.code}
              onClick={() => setSelectedLanguage(lang.code)}
              className={`p-3 rounded-lg text-left transition-all ${
                selectedLanguage === lang.code
                  ? 'bg-blue-600 text-white ring-2 ring-blue-400'
                  : 'bg-white hover:bg-gray-100 border'
              }`}
            >
              <div className="font-medium text-sm truncate">{lang.name}</div>
              <div className={`text-xs ${selectedLanguage === lang.code ? 'text-blue-100' : 'text-gray-500'}`}>
                {lang.code.toUpperCase()}
              </div>
              <div className="mt-1">
                <div className={`text-xs ${selectedLanguage === lang.code ? 'text-blue-100' : 'text-gray-500'}`}>
                  {lang.total} / {stats?.totalStrings || 0}
                </div>
                <div className="w-full bg-gray-200 rounded-full h-1.5 mt-1">
                  <div
                    className={`h-1.5 rounded-full ${
                      lang.percentage === 100 ? 'bg-green-500' : lang.percentage > 50 ? 'bg-yellow-500' : 'bg-red-400'
                    }`}
                    style={{ width: `${lang.percentage}%` }}
                  />
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Legend */}
      <div className="flex items-center gap-4 text-sm text-gray-600">
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded bg-green-500" /> 100% translated
        </div>
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded bg-yellow-500" /> 50-99%
        </div>
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded bg-red-400" /> &lt;50%
        </div>
        <div className="flex items-center gap-1 ml-4">
          <span className="text-green-600 font-bold">✓</span> Verified
        </div>
        <div className="flex items-center gap-1">
          <span className="text-yellow-600 font-bold">?</span> Needs Review
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-4 items-center">
        <input
          type="text"
          placeholder="Search strings..."
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="border rounded px-3 py-2 w-64"
        />
        <span className="text-gray-500">
          {filteredTranslations.length} of {translations.length} strings for{' '}
          <strong>{SUPPORTED_LANGUAGES.find(l => l.code === selectedLanguage)?.name}</strong>
        </span>
      </div>

      {/* Translations Table */}
      {loading ? (
        <div className="text-center py-8 text-gray-500">Loading translations...</div>
      ) : filteredTranslations.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          {translations.length === 0
            ? `No translations found for ${selectedLanguage}. Import some translations to get started.`
            : 'No strings match your search.'}
        </div>
      ) : (
        <div className="bg-white border rounded-lg overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-700">Key</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-700">Translation</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-700 w-24">Source</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-700 w-24">Status</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-700 w-32">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {filteredTranslations.map(t => (
                <tr key={t.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <div className="font-mono text-sm text-gray-800">{t.string_key}</div>
                    {t.context && (
                      <div className="text-xs text-gray-500 mt-1">{t.context}</div>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {editingId === t.id ? (
                      <textarea
                        value={editValue}
                        onChange={(e) => setEditValue(e.target.value)}
                        rows={2}
                        className="w-full border rounded px-2 py-1 text-sm"
                        autoFocus
                      />
                    ) : (
                      <div className="text-sm">{t.value}</div>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`text-xs px-2 py-1 rounded ${
                      t.source === 'human' ? 'bg-blue-100 text-blue-700' :
                      t.source === 'llm' ? 'bg-purple-100 text-purple-700' :
                      'bg-gray-100 text-gray-700'
                    }`}>
                      {t.source}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => toggleVerified(t)}
                      className={`text-sm font-medium ${
                        t.verified ? 'text-green-600' : 'text-yellow-600'
                      }`}
                    >
                      {t.verified ? '✓ Verified' : '? Review'}
                    </button>
                  </td>
                  <td className="px-4 py-3">
                    {editingId === t.id ? (
                      <div className="flex gap-1">
                        <button
                          onClick={() => saveTranslation(t.id, editValue, t.verified)}
                          disabled={saving}
                          className="text-sm bg-green-100 text-green-700 px-2 py-1 rounded hover:bg-green-200"
                        >
                          {saving ? '...' : 'Save'}
                        </button>
                        <button
                          onClick={() => setEditingId(null)}
                          className="text-sm bg-gray-100 text-gray-700 px-2 py-1 rounded hover:bg-gray-200"
                        >
                          Cancel
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => {
                          setEditingId(t.id)
                          setEditValue(t.value)
                        }}
                        className="text-sm bg-blue-100 text-blue-700 px-2 py-1 rounded hover:bg-blue-200"
                      >
                        Edit
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Import Modal */}
      {showImportModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl p-6 w-full max-w-2xl max-h-[80vh] overflow-y-auto">
            <h3 className="text-xl font-bold mb-4">Import Translations</h3>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Upload JSON File
                </label>
                <input
                  type="file"
                  accept=".json"
                  ref={fileInputRef}
                  onChange={handleFileUpload}
                  className="w-full border rounded px-3 py-2"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Or Paste JSON
                </label>
                <textarea
                  value={importText}
                  onChange={(e) => setImportText(e.target.value)}
                  rows={10}
                  placeholder={`[
  {
    "string_key": "welcome_title",
    "context": "Main screen title",
    "language_code": "es",
    "value": "Bienvenido",
    "source": "llm",
    "verified": false
  }
]`}
                  className="w-full border rounded px-3 py-2 font-mono text-sm"
                />
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="overwrite"
                  checked={importOverwrite}
                  onChange={(e) => setImportOverwrite(e.target.checked)}
                />
                <label htmlFor="overwrite" className="text-sm">
                  Overwrite existing translations (otherwise skip duplicates)
                </label>
              </div>

              {importResult && (
                <div className={`p-3 rounded ${importResult.errors?.length ? 'bg-yellow-50' : 'bg-green-50'}`}>
                  <div className="font-medium">
                    Imported: {importResult.imported} | Skipped: {importResult.skipped}
                  </div>
                  {importResult.errors && importResult.errors.length > 0 && (
                    <div className="mt-2 text-sm text-red-600">
                      Errors: {importResult.errors.slice(0, 5).join(', ')}
                      {importResult.errors.length > 5 && ` and ${importResult.errors.length - 5} more...`}
                    </div>
                  )}
                </div>
              )}
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <button
                onClick={() => {
                  setShowImportModal(false)
                  setImportText('')
                  setImportResult(null)
                }}
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded hover:bg-gray-200"
              >
                Close
              </button>
              <button
                onClick={handleImport}
                disabled={!importText.trim() || saving}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-blue-400"
              >
                {saving ? 'Importing...' : 'Import'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
