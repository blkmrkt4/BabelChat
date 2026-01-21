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

// Supported languages for Fluenca (22 languages)
const SUPPORTED_LANGUAGES = [
  { code: 'en', name: 'English' },
  { code: 'es', name: 'Spanish' },
  { code: 'fr', name: 'French' },
  { code: 'de', name: 'German' },
  { code: 'it', name: 'Italian' },
  { code: 'pt-BR', name: 'Portuguese (Brazil)' },
  { code: 'pt-PT', name: 'Portuguese (Portugal)' },
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
  const [englishStrings, setEnglishStrings] = useState<Translation[]>([])
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

  // Translation state
  const [showTranslateModal, setShowTranslateModal] = useState(false)
  const [translateTarget, setTranslateTarget] = useState<string>('')
  const [translating, setTranslating] = useState(false)
  const [retranslateAll, setRetranslateAll] = useState(false)
  const [translateProgress, setTranslateProgress] = useState<{
    status: string
    successful?: number
    failed?: number
    skipped?: number
    total?: number
  } | null>(null)

  useEffect(() => {
    loadStats()
    loadEnglishStrings()
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

  async function loadEnglishStrings() {
    try {
      const response = await fetch('/api/localization?language_code=en')
      const result = await response.json()
      if (response.ok) {
        setEnglishStrings(result.data || [])
      }
    } catch (error) {
      console.error('Failed to load English strings:', error)
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
      loadEnglishStrings()
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

  async function handleTranslate(targetLang: string) {
    if (englishStrings.length === 0) {
      alert('No English source strings found. Please import English strings first.')
      return
    }

    setTranslateTarget(targetLang)
    setShowTranslateModal(true)
  }

  async function runTranslation() {
    if (!translateTarget || englishStrings.length === 0) return

    setTranslating(true)
    setTranslateProgress({ status: 'Starting translation...' })

    try {
      const strings = englishStrings.map(s => ({
        string_key: s.string_key,
        value: s.value,
        context: s.context,
      }))

      const targetLangName = SUPPORTED_LANGUAGES.find(l => l.code === translateTarget)?.name
      setTranslateProgress({
        status: retranslateAll
          ? `Re-translating all ${strings.length} strings to ${targetLangName}...`
          : `Translating missing strings to ${targetLangName}...`,
        total: strings.length,
      })

      const response = await fetch('/api/localization/translate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          strings,
          targetLanguage: translateTarget,
          retranslateAll,
        }),
      })

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Translation failed')
      }

      const statusParts = []
      if (result.skipped > 0) statusParts.push(`${result.skipped} already translated`)
      if (result.successful > 0) statusParts.push(`${result.successful} new translations`)
      if (result.failed > 0) statusParts.push(`${result.failed} failed`)

      setTranslateProgress({
        status: result.message || `Translation complete! ${statusParts.join(', ')}`,
        successful: result.successful,
        failed: result.failed,
        skipped: result.skipped,
        total: result.total,
      })

      // Refresh data
      loadStats()
      if (selectedLanguage === translateTarget) {
        loadTranslations(translateTarget)
      }
    } catch (error) {
      console.error('Translation error:', error)
      setTranslateProgress({
        status: `Error: ${error instanceof Error ? error.message : 'Translation failed'}`,
      })
    } finally {
      setTranslating(false)
    }
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

  const englishStats = languageCompletion.find(l => l.code === 'en')

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">App Localization</h2>
          <p className="text-gray-600 mt-1">
            Manage UI string translations for the Fluenca iOS app.
            {englishStats && ` ${englishStats.total} source strings.`}
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

      {/* Quick Start Guide */}
      {englishStrings.length === 0 && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <h3 className="font-semibold text-blue-900 mb-2">Getting Started</h3>
          <ol className="list-decimal list-inside space-y-1 text-sm text-blue-800">
            <li>Click <strong>Import</strong> and add your English source strings</li>
            <li>Format: <code className="bg-blue-100 px-1 rounded">{`[{"string_key": "welcome", "value": "Welcome", "language_code": "en", "context": "Home screen"}]`}</code></li>
            <li>Once imported, click <strong>Translate</strong> on any language to auto-translate using AI</li>
          </ol>
        </div>
      )}

      {/* Language Grid */}
      <div className="bg-gray-50 rounded-lg p-4">
        <div className="flex justify-between items-center mb-3">
          <h3 className="text-lg font-semibold">Translation Coverage</h3>
          {englishStrings.length > 0 && (
            <span className="text-sm text-gray-500">
              Click a language card to view, or click Translate to generate translations
            </span>
          )}
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-2">
          {languageCompletion.map(lang => (
            <div
              key={lang.code}
              className={`p-3 rounded-lg transition-all ${
                selectedLanguage === lang.code
                  ? 'bg-blue-600 text-white ring-2 ring-blue-400'
                  : 'bg-white border'
              }`}
            >
              <button
                onClick={() => setSelectedLanguage(lang.code)}
                className="w-full text-left"
              >
                <div className="font-medium text-sm truncate">{lang.name}</div>
                <div className={`text-xs ${selectedLanguage === lang.code ? 'text-blue-100' : 'text-gray-500'}`}>
                  {lang.code.toUpperCase()}
                </div>
                <div className="mt-1">
                  <div className={`text-xs ${selectedLanguage === lang.code ? 'text-blue-100' : 'text-gray-500'}`}>
                    {lang.total} / {englishStats?.total || 0}
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
              {/* Translate button for non-English languages */}
              {lang.code !== 'en' && englishStrings.length > 0 && (
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    handleTranslate(lang.code)
                  }}
                  className={`mt-2 w-full text-xs px-2 py-1 rounded font-medium ${
                    selectedLanguage === lang.code
                      ? 'bg-white/20 text-white hover:bg-white/30'
                      : lang.percentage === 100
                        ? 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                        : 'bg-purple-100 text-purple-700 hover:bg-purple-200'
                  }`}
                >
                  {lang.percentage === 100 ? 'Re-translate' : 'Translate'}
                </button>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Legend */}
      <div className="flex items-center gap-4 text-sm text-gray-600 flex-wrap">
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
        <div className="flex items-center gap-1">
          <span className="bg-purple-100 text-purple-700 text-xs px-2 py-0.5 rounded">llm</span> AI-translated
        </div>
        <div className="flex items-center gap-1">
          <span className="bg-blue-100 text-blue-700 text-xs px-2 py-0.5 rounded">human</span> Human-edited
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
            ? selectedLanguage === 'en'
              ? 'No English source strings yet. Click Import to add them.'
              : `No translations for ${SUPPORTED_LANGUAGES.find(l => l.code === selectedLanguage)?.name} yet. Click Translate to generate them.`
            : 'No strings match your search.'}
        </div>
      ) : (
        <div className="bg-white border rounded-lg overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-700">Key</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-gray-700">
                  {selectedLanguage === 'en' ? 'Source Text' : 'Translation'}
                </th>
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
            <h3 className="text-xl font-bold mb-4">Import Source Strings</h3>

            <div className="space-y-4">
              {/* Excel Upload - Primary Option */}
              <div className="bg-green-50 border-2 border-green-200 rounded-lg p-4">
                <label className="block text-sm font-semibold text-green-800 mb-2">
                  Upload Excel File (Recommended)
                </label>
                <p className="text-xs text-green-700 mb-2">
                  Upload your localization spreadsheet. Must have "String Key" and "English" columns.
                </p>
                <input
                  type="file"
                  accept=".xlsx,.xls"
                  onChange={async (e) => {
                    const file = e.target.files?.[0]
                    if (!file) return

                    setSaving(true)
                    setImportResult(null)

                    try {
                      const formData = new FormData()
                      formData.append('file', file)

                      const parseResponse = await fetch('/api/localization/parse-excel', {
                        method: 'POST',
                        body: formData,
                      })

                      const parseResult = await parseResponse.json()

                      if (!parseResponse.ok) {
                        alert(`Failed to parse Excel: ${parseResult.error}`)
                        setSaving(false)
                        return
                      }

                      // Now import the parsed translations
                      const importResponse = await fetch('/api/localization/import', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                          translations: parseResult.translations,
                          overwrite: importOverwrite
                        }),
                      })

                      const importResult = await importResponse.json()

                      if (!importResponse.ok) {
                        throw new Error(importResult.error || 'Failed to import')
                      }

                      setImportResult({
                        imported: importResult.imported,
                        skipped: importResult.skipped,
                        errors: importResult.errors
                      })

                      loadStats()
                      loadEnglishStrings()
                      loadTranslations(selectedLanguage)
                    } catch (error) {
                      console.error('Excel import error:', error)
                      alert('Failed to import Excel file')
                    } finally {
                      setSaving(false)
                    }
                  }}
                  className="w-full border border-green-300 rounded px-3 py-2 bg-white"
                  disabled={saving}
                />
              </div>

              {/* Divider */}
              <div className="flex items-center gap-4">
                <div className="flex-1 border-t border-gray-300" />
                <span className="text-sm text-gray-500">or</span>
                <div className="flex-1 border-t border-gray-300" />
              </div>

              {/* JSON Upload - Secondary Option */}
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
                  rows={6}
                  placeholder={`[{"string_key": "welcome", "value": "Welcome", "language_code": "en", "context": "Home screen"}]`}
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
                {saving ? 'Importing...' : 'Import JSON'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Translate Modal */}
      {showTranslateModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl p-6 w-full max-w-md">
            <h3 className="text-xl font-bold mb-4">
              Translate to {SUPPORTED_LANGUAGES.find(l => l.code === translateTarget)?.name}
            </h3>

            <div className="space-y-4">
              {(() => {
                const targetStats = stats?.languageStats[translateTarget]
                const existingCount = targetStats?.total || 0
                const missingCount = englishStrings.length - existingCount
                return (
                  <div className="bg-purple-50 border border-purple-200 rounded p-3">
                    <div className="text-sm space-y-1">
                      <div><strong>{englishStrings.length}</strong> total English source strings</div>
                      <div className="text-green-700"><strong>{existingCount}</strong> already translated</div>
                      <div className="text-orange-600"><strong>{missingCount}</strong> missing translations</div>
                    </div>
                    <div className="text-xs text-gray-600 mt-2">
                      New translations will be marked as "llm" source and need review.
                    </div>
                  </div>
                )
              })()}

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="retranslateAll"
                  checked={retranslateAll}
                  onChange={(e) => setRetranslateAll(e.target.checked)}
                  disabled={translating}
                />
                <label htmlFor="retranslateAll" className="text-sm">
                  Re-translate all strings (overwrite existing)
                </label>
              </div>
              <p className="text-xs text-gray-500 ml-6 -mt-2">
                Use this when you want to use a better model or improve all translations.
              </p>

              {translateProgress && (
                <div className={`p-3 rounded ${
                  translateProgress.status.includes('Error') ? 'bg-red-50' :
                  translateProgress.status.includes('complete') || translateProgress.status.includes('already') ? 'bg-green-50' : 'bg-blue-50'
                }`}>
                  <div className="font-medium text-sm">{translateProgress.status}</div>
                  {(translateProgress.successful !== undefined || translateProgress.skipped !== undefined) && (
                    <div className="text-sm mt-1 space-y-0.5">
                      {translateProgress.skipped !== undefined && translateProgress.skipped > 0 && (
                        <div className="text-gray-600">Skipped (existing): {translateProgress.skipped}</div>
                      )}
                      {translateProgress.successful !== undefined && translateProgress.successful > 0 && (
                        <div className="text-green-700">Translated: {translateProgress.successful}</div>
                      )}
                      {translateProgress.failed !== undefined && translateProgress.failed > 0 && (
                        <div className="text-red-600">Failed: {translateProgress.failed}</div>
                      )}
                    </div>
                  )}
                </div>
              )}
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <button
                onClick={() => {
                  setShowTranslateModal(false)
                  setTranslateTarget('')
                  setTranslateProgress(null)
                  setRetranslateAll(false)
                }}
                disabled={translating}
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded hover:bg-gray-200 disabled:opacity-50"
              >
                {translateProgress?.status.includes('complete') || translateProgress?.status.includes('already') ? 'Done' : 'Cancel'}
              </button>
              {!translateProgress?.status.includes('complete') && !translateProgress?.status.includes('already') && (
                <button
                  onClick={runTranslation}
                  disabled={translating}
                  className="px-4 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 disabled:bg-purple-400"
                >
                  {translating ? 'Translating...' : retranslateAll ? 'Re-translate All' : 'Translate Missing'}
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
