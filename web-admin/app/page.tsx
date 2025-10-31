'use client'

import { useState, useEffect } from 'react'
import { getAIConfig, updateAIConfig, type AIConfig } from '@/lib/supabase'
import {
  fetchOpenRouterModels,
  testModel,
  formatCost,
  formatContextLength,
  isTextOnlyModel,
  hasReasoningCost,
  type OpenRouterModel,
  type ModelWithScore
} from '@/lib/openrouter'
import {
  getModelScore,
  saveModelScore,
  getCategoryConfig,
  saveCategoryConfig,
  saveModelToPosition
} from '@/lib/modelStorage'

const DEFAULT_CATEGORIES = ['translation', 'grammar', 'scoring'] as const
type SensitivityLevel = 'minimal' | 'moderate' | 'verbose'
type SortOption = 'name' | 'cost' | 'score'

const LANGUAGES = [
  'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese',
  'Chinese', 'Japanese', 'Korean', 'Arabic', 'Russian', 'Hindi',
  'Dutch', 'Swedish', 'Norwegian', 'Danish', 'Finnish', 'Polish',
  'Turkish', 'Greek', 'Hebrew', 'Thai', 'Vietnamese', 'Indonesian'
]

export default function AIModelSetup() {
  const [category, setCategory] = useState<string>('translation')
  const [customCategories, setCustomCategories] = useState<string[]>([])
  const [config, setConfig] = useState<AIConfig | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  // Models
  const [allModels, setAllModels] = useState<ModelWithScore[]>([])
  const [loadingModels, setLoadingModels] = useState(false)
  const [selectedModel, setSelectedModel] = useState<ModelWithScore | null>(null)
  const [sortBy, setSortBy] = useState<SortOption>('name')
  const [searchTerm, setSearchTerm] = useState('')

  // Modality filters
  const [textOnlyFilter, setTextOnlyFilter] = useState(true)
  const [excludeReasoning, setExcludeReasoning] = useState(true)

  // Form state
  const [promptTemplate, setPromptTemplate] = useState('')
  const [temperature, setTemperature] = useState(0.7)
  const [maxTokens, setMaxTokens] = useState(1000)

  // Grammar-specific
  const [sensitivity, setSensitivity] = useState<SensitivityLevel>('moderate')
  const [grammarLevel1, setGrammarLevel1] = useState('')
  const [grammarLevel2, setGrammarLevel2] = useState('')
  const [grammarLevel3, setGrammarLevel3] = useState('')

  // Testing
  const [testInput, setTestInput] = useState('')
  const [testOutput, setTestOutput] = useState('')
  const [testing, setTesting] = useState(false)
  const [score, setScore] = useState(5)
  const [apiKey, setApiKey] = useState('')

  // Language selection for template variables
  const [learningLanguage, setLearningLanguage] = useState('Spanish')
  const [nativeLanguage, setNativeLanguage] = useState('English')

  // Model position selection
  const [selectedPosition, setSelectedPosition] = useState<1 | 2 | 3 | 4>(1)
  const [currentPositions, setCurrentPositions] = useState<{
    position1?: string
    position2?: string
    position3?: string
    position4?: string
  }>({})

  // Load configuration and models
  useEffect(() => {
    loadConfig()
    loadModels()
    loadApiKey()
    loadCurrentPositions()
    loadCustomCategories()
  }, [category])

  const loadCustomCategories = async () => {
    try {
      // Load all categories from Supabase
      const { getAIConfigs } = await import('@/lib/supabase')
      const allConfigs = await getAIConfigs()

      // Extract custom categories (not in DEFAULT_CATEGORIES)
      const customFromDb = allConfigs
        .map(config => config.category)
        .filter(cat => !DEFAULT_CATEGORIES.includes(cat as any))

      // Merge with localStorage (for backward compatibility)
      const saved = localStorage.getItem('custom_categories')
      let fromLocalStorage: string[] = []
      if (saved) {
        try {
          fromLocalStorage = JSON.parse(saved)
        } catch (e) {
          console.error('Error parsing localStorage:', e)
        }
      }

      // Combine and deduplicate
      const combined = [...new Set([...customFromDb, ...fromLocalStorage])]
      setCustomCategories(combined)

      // Update localStorage to match Supabase
      localStorage.setItem('custom_categories', JSON.stringify(combined))
    } catch (e) {
      console.error('Error loading custom categories:', e)
    }
  }

  const getAllCategories = () => {
    return [...DEFAULT_CATEGORIES, ...customCategories]
  }

  const loadCurrentPositions = () => {
    const config = getCategoryConfig(category)
    if (config) {
      setCurrentPositions({
        position1: config.position1,
        position2: config.position2,
        position3: config.position3,
        position4: config.position4,
      })
    } else {
      setCurrentPositions({})
    }
  }

  const loadApiKey = () => {
    // Try environment variable first
    const envKey = process.env.NEXT_PUBLIC_OPENROUTER_API_KEY
    console.log('Environment API Key:', envKey ? `${envKey.substring(0, 20)}...` : 'NOT FOUND')

    if (envKey) {
      console.log('Using API key from environment')
      setApiKey(envKey)
      return
    }

    // Fall back to localStorage
    const saved = localStorage.getItem('openrouter_api_key')
    if (saved) {
      console.log('Using API key from localStorage')
      setApiKey(saved)
    } else {
      console.log('No API key found')
    }
  }

  const saveApiKey = (key: string) => {
    localStorage.setItem('openrouter_api_key', key)
    setApiKey(key)
  }

  const loadConfig = async () => {
    setLoading(true)
    try {
      const data = await getAIConfig(category)
      if (data) {
        setConfig(data)
        setPromptTemplate(data.prompt_template)
        setTemperature(data.temperature)
        setMaxTokens(data.max_tokens)

        if (category === 'grammar') {
          setGrammarLevel1(data.grammar_level_1_prompt || '')
          setGrammarLevel2(data.grammar_level_2_prompt || '')
          setGrammarLevel3(data.grammar_level_3_prompt || '')
        }
      }
    } catch (error) {
      console.error('Error loading config:', error)
    } finally {
      setLoading(false)
    }
  }

  const loadModels = async () => {
    setLoadingModels(true)
    try {
      const models = await fetchOpenRouterModels()

      // Add scores from localStorage (category-specific)
      const modelsWithScores: ModelWithScore[] = models.map(model => {
        const scoreData = getModelScore(model.id, category)
        return {
          ...model,
          userScore: scoreData?.score,
          testCount: scoreData?.testCount,
        }
      })

      setAllModels(modelsWithScores)
    } catch (error) {
      console.error('Error loading models:', error)
      alert('Failed to load models from OpenRouter')
    } finally {
      setLoadingModels(false)
    }
  }

  const sortedModels = () => {
    // Apply filters
    let filtered = allModels

    // Modality filters
    if (textOnlyFilter) {
      filtered = filtered.filter(m => isTextOnlyModel(m))
    }

    if (excludeReasoning) {
      filtered = filtered.filter(m => !hasReasoningCost(m))
    }

    // Search filter
    if (searchTerm.trim()) {
      const search = searchTerm.toLowerCase()
      filtered = filtered.filter(m =>
        m.name.toLowerCase().includes(search) ||
        m.id.toLowerCase().includes(search)
      )
    }

    // Sort
    return [...filtered].sort((a, b) => {
      switch (sortBy) {
        case 'name':
          return a.name.localeCompare(b.name)
        case 'cost':
          const costA = parseFloat(a.pricing.prompt) + parseFloat(a.pricing.completion)
          const costB = parseFloat(b.pricing.prompt) + parseFloat(b.pricing.completion)
          return costA - costB
        case 'score':
          const scoreA = a.userScore || 0
          const scoreB = b.userScore || 0
          if (scoreB !== scoreA) return scoreB - scoreA
          return a.name.localeCompare(b.name)
        default:
          return 0
      }
    })
  }

  const getCurrentPrompt = () => {
    if (category !== 'grammar') return promptTemplate

    switch (sensitivity) {
      case 'minimal':
        return grammarLevel1 || promptTemplate
      case 'verbose':
        return grammarLevel3 || promptTemplate
      case 'moderate':
      default:
        return grammarLevel2 || promptTemplate
    }
  }

  const replaceTemplateVariables = (text: string): string => {
    return text
      .replace(/\{learning_language\}/g, learningLanguage)
      .replace(/\{native_language\}/g, nativeLanguage)
  }

  const extractTemplateVariables = (text: string): string[] => {
    const matches = text.match(/\{[^}]+\}/g)
    return matches ? [...new Set(matches)] : []
  }

  const setCurrentPrompt = (value: string) => {
    if (category !== 'grammar') {
      setPromptTemplate(value)
      return
    }

    switch (sensitivity) {
      case 'minimal':
        setGrammarLevel1(value)
        break
      case 'verbose':
        setGrammarLevel3(value)
        break
      case 'moderate':
      default:
        setGrammarLevel2(value)
        break
    }
  }

  const handleTestModel = async () => {
    if (!selectedModel) {
      alert('Please select a model first')
      return
    }
    if (!testInput.trim()) {
      alert('Please enter test input')
      return
    }
    if (!apiKey || apiKey.trim() === '') {
      alert('Please enter your OpenRouter API key')
      return
    }

    console.log('Testing model with API key:', apiKey.substring(0, 20) + '...')

    setTesting(true)
    setTestOutput('Testing model...')

    try {
      // Get prompt and replace template variables
      const rawPrompt = getCurrentPrompt()
      const prompt = replaceTemplateVariables(rawPrompt)

      console.log('Prompt with variables replaced:', prompt)

      const response = await testModel(selectedModel.id, prompt, testInput, apiKey)
      setTestOutput(response)
    } catch (error: any) {
      setTestOutput(`Error: ${error.message}`)
    } finally {
      setTesting(false)
    }
  }

  const handleSaveScore = () => {
    if (!selectedModel) {
      alert('Please select a model first')
      return
    }

    saveModelScore(selectedModel.id, category, score)
    alert(`Score ${score}/10 saved for ${selectedModel.name} (${category})`)

    // Reload models to update scores
    loadModels()
  }

  const handleSaveToPosition = async () => {
    if (!selectedModel) {
      alert('Please select a model first')
      return
    }

    setSaving(true)
    try {
      // Save model to selected position
      saveModelToPosition(category, selectedModel.id, selectedPosition)

      // If saving to position 1, also update Supabase
      if (selectedPosition === 1) {
        const updates: Partial<AIConfig> = {
          model_id: selectedModel.id,
          model_name: selectedModel.name,
          model_provider: selectedModel.id.split('/')[0] || 'openrouter',
          prompt_template: promptTemplate,
          temperature,
          max_tokens: maxTokens,
        }

        if (category === 'grammar') {
          updates.grammar_level_1_prompt = grammarLevel1
          updates.grammar_level_2_prompt = grammarLevel2
          updates.grammar_level_3_prompt = grammarLevel3
        }

        await updateAIConfig(category, updates)
      }

      const positionName = selectedPosition === 1 ? 'Primary' : `Fallback ${selectedPosition - 1}`
      alert(`${selectedModel.name} set as ${positionName} for ${category}!`)

      loadCurrentPositions()
      if (selectedPosition === 1) {
        await loadConfig()
      }
    } catch (error) {
      console.error('Error saving:', error)
      alert('Failed to save configuration')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl">Loading...</div>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <h1 className="text-3xl font-bold">AI Model Bindings</h1>

      {/* API Key Status */}
      {apiKey ? (
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-green-800">✓ OpenRouter API Key Configured</p>
              <p className="text-xs text-green-600 mt-1">Key: {apiKey.substring(0, 20)}...</p>
            </div>
            <button
              onClick={() => {
                localStorage.removeItem('openrouter_api_key')
                setApiKey('')
              }}
              className="text-xs px-3 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200"
            >
              Clear Key
            </button>
          </div>
        </div>
      ) : (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <label className="block text-sm font-medium mb-2">OpenRouter API Key (Required for Testing)</label>
          <input
            type="password"
            placeholder="sk-or-v1-..."
            onChange={(e) => saveApiKey(e.target.value)}
            className="w-full px-3 py-2 border rounded-lg"
          />
        </div>
      )}

      {/* Category Selector */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex flex-wrap gap-2">
          {getAllCategories().map((cat) => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                category === cat
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              }`}
            >
              {cat.charAt(0).toUpperCase() + cat.slice(1)}
            </button>
          ))}
        </div>

        {config && (
          <div className="mt-4 text-sm">
            <span className="text-green-600 font-semibold">✓ PRIMARY: {config.model_name}</span>
          </div>
        )}
      </div>

      {/* Search and Sort Options */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        {/* Search Bar */}
        <div>
          <input
            type="text"
            placeholder="🔍 Search models by name or ID..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none"
          />
        </div>

        {/* Modality Filters */}
        <div className="flex items-center gap-4 p-4 bg-blue-50 rounded-lg border border-blue-200">
          <label className="font-medium">Filters:</label>
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={textOnlyFilter}
              onChange={(e) => setTextOnlyFilter(e.target.checked)}
              className="w-4 h-4"
            />
            <span className="text-sm">Text-only (exclude vision/audio)</span>
          </label>
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={excludeReasoning}
              onChange={(e) => setExcludeReasoning(e.target.checked)}
              className="w-4 h-4"
            />
            <span className="text-sm">Exclude reasoning models</span>
          </label>
          <span className="ml-auto text-sm text-gray-600">
            Showing {sortedModels().length} of {allModels.length} models
          </span>
        </div>

        {/* Sort Options */}
        <div className="flex items-center gap-4">
          <label className="font-medium">Sort by:</label>
          <div className="flex gap-2">
            {(['name', 'cost', 'score'] as SortOption[]).map((sort) => (
              <button
                key={sort}
                onClick={() => setSortBy(sort)}
                className={`px-4 py-2 rounded-lg border-2 transition-colors ${
                  sortBy === sort
                    ? 'bg-blue-100 border-blue-600 text-blue-700'
                    : 'border-gray-300 hover:border-gray-400'
                }`}
              >
                {sort.charAt(0).toUpperCase() + sort.slice(1)}
              </button>
            ))}
          </div>
          <button
            onClick={loadModels}
            disabled={loadingModels}
            className="ml-auto px-4 py-2 bg-gray-200 rounded-lg hover:bg-gray-300 disabled:bg-gray-100"
          >
            {loadingModels ? 'Loading...' : '🔄 Refresh Models'}
          </button>
        </div>
      </div>

      {/* Model List */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="max-h-64 overflow-y-auto">
          <table className="w-full">
            <thead className="bg-gray-50 sticky top-0">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-semibold">Model</th>
                <th className="px-4 py-3 text-left text-sm font-semibold">Context</th>
                <th className="px-4 py-3 text-left text-sm font-semibold">Input Cost</th>
                <th className="px-4 py-3 text-left text-sm font-semibold">Output Cost</th>
                <th className="px-4 py-3 text-left text-sm font-semibold">Score</th>
                <th className="px-4 py-3 text-left text-sm font-semibold">Tests</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {loadingModels ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-gray-500">
                    Loading models from OpenRouter...
                  </td>
                </tr>
              ) : sortedModels().length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-gray-500">
                    No models found
                  </td>
                </tr>
              ) : (
                sortedModels().map((model) => {
                  const isMultimodal = !isTextOnlyModel(model)
                  const hasReasoning = hasReasoningCost(model)

                  return (
                    <tr
                      key={model.id}
                      onClick={() => setSelectedModel(model)}
                      className={`cursor-pointer hover:bg-blue-50 ${
                        selectedModel?.id === model.id ? 'bg-blue-100' : ''
                      }`}
                    >
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <div>
                            <div className="font-medium">{model.name}</div>
                            <div className="text-xs text-gray-500">{model.id}</div>
                          </div>
                        </div>
                        <div className="flex gap-1 mt-1">
                          {isMultimodal && (
                            <span className="px-2 py-0.5 text-xs bg-purple-100 text-purple-700 rounded">
                              🖼️ Multimodal
                            </span>
                          )}
                          {hasReasoning && (
                            <span className="px-2 py-0.5 text-xs bg-orange-100 text-orange-700 rounded">
                              🧠 Reasoning
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm font-mono text-gray-700">
                        {formatContextLength(model.context_length)}
                      </td>
                      <td className="px-4 py-3 text-sm">{formatCost(model.pricing.prompt)}/1K</td>
                      <td className="px-4 py-3 text-sm">{formatCost(model.pricing.completion)}/1K</td>
                      <td className="px-4 py-3">
                        {model.userScore ? (
                          <span className="font-semibold text-blue-600">{model.userScore}/10</span>
                        ) : (
                          <span className="text-gray-400">—</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-600">
                        {model.testCount || 0}
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Selected Model Card */}
      {selectedModel && (
        <div className="bg-blue-50 border-2 border-blue-600 rounded-lg p-6">
          <div className="flex justify-between items-start">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <h3 className="text-xl font-bold">{selectedModel.name}</h3>
                {!isTextOnlyModel(selectedModel) && (
                  <span className="px-2 py-1 text-xs bg-purple-100 text-purple-700 rounded">
                    🖼️ Multimodal
                  </span>
                )}
                {hasReasoningCost(selectedModel) && (
                  <span className="px-2 py-1 text-xs bg-orange-100 text-orange-700 rounded">
                    🧠 Reasoning
                  </span>
                )}
              </div>
              <p className="text-sm text-gray-600">{selectedModel.id}</p>
              <div className="text-sm mt-2 space-y-1">
                <p>
                  <span className="font-medium">Context:</span> {formatContextLength(selectedModel.context_length)}
                </p>
                <p>
                  <span className="font-medium">Input:</span> {formatCost(selectedModel.pricing.prompt)}/1K |
                  <span className="font-medium ml-2">Output:</span> {formatCost(selectedModel.pricing.completion)}/1K
                </p>
              </div>
            </div>
            {selectedModel.userScore && (
              <div className="text-3xl font-bold text-blue-600">
                {selectedModel.userScore}/10
              </div>
            )}
          </div>
        </div>
      )}

      {/* Grammar Sensitivity (only for grammar category) */}
      {category === 'grammar' && (
        <div className="bg-white rounded-lg shadow p-6 space-y-4">
          <h2 className="text-xl font-semibold">Sensitivity Level</h2>
          <div className="flex gap-2">
            {(['minimal', 'moderate', 'verbose'] as SensitivityLevel[]).map((level) => (
              <button
                key={level}
                onClick={() => setSensitivity(level)}
                className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                  sensitivity === level
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                {level.charAt(0).toUpperCase() + level.slice(1)}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Master Prompt Editor */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <h2 className="text-xl font-semibold">
          Master Prompt {category === 'grammar' && `(${sensitivity})`}
        </h2>
        <textarea
          value={getCurrentPrompt()}
          onChange={(e) => setCurrentPrompt(e.target.value)}
          className="w-full h-40 px-3 py-2 border rounded-lg font-mono text-sm"
          placeholder="Enter the master prompt template..."
        />
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Temperature ({temperature})</label>
            <input
              type="range"
              min="0"
              max="1"
              step="0.1"
              value={temperature}
              onChange={(e) => setTemperature(parseFloat(e.target.value))}
              className="w-full"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Max Tokens</label>
            <input
              type="number"
              value={maxTokens}
              onChange={(e) => setMaxTokens(parseInt(e.target.value))}
              className="w-full px-3 py-2 border rounded-lg"
            />
          </div>
        </div>
      </div>

      {/* Language Selection */}
      {getCurrentPrompt() && extractTemplateVariables(getCurrentPrompt()).length > 0 && (
        <div className="bg-white rounded-lg shadow p-6 space-y-4">
          <h2 className="text-xl font-semibold">Language Settings</h2>
          <p className="text-sm text-gray-600">
            Select languages to replace template variables: {extractTemplateVariables(getCurrentPrompt()).join(', ')}
          </p>
          <div className="grid grid-cols-2 gap-4">
            {extractTemplateVariables(getCurrentPrompt()).includes('{learning_language}') && (
              <div>
                <label className="block text-sm font-medium mb-2">Learning Language</label>
                <select
                  value={learningLanguage}
                  onChange={(e) => setLearningLanguage(e.target.value)}
                  className="w-full px-3 py-2 border rounded-lg"
                >
                  {LANGUAGES.map(lang => (
                    <option key={lang} value={lang}>{lang}</option>
                  ))}
                </select>
              </div>
            )}
            {extractTemplateVariables(getCurrentPrompt()).includes('{native_language}') && (
              <div>
                <label className="block text-sm font-medium mb-2">Native Language</label>
                <select
                  value={nativeLanguage}
                  onChange={(e) => setNativeLanguage(e.target.value)}
                  className="w-full px-3 py-2 border rounded-lg"
                >
                  {LANGUAGES.map(lang => (
                    <option key={lang} value={lang}>{lang}</option>
                  ))}
                </select>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Test Interface */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <h2 className="text-xl font-semibold">Test Model</h2>
        <div>
          <label className="block text-sm font-medium mb-1">Test Input</label>
          <textarea
            value={testInput}
            onChange={(e) => setTestInput(e.target.value)}
            className="w-full h-24 px-3 py-2 border rounded-lg"
            placeholder="Enter text to test..."
          />
        </div>
        <button
          onClick={handleTestModel}
          disabled={testing || !selectedModel}
          className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 disabled:bg-gray-400"
        >
          {testing ? 'Testing...' : 'Test Model'}
        </button>
        {testOutput && (
          <div>
            <label className="block text-sm font-medium mb-1">Response</label>
            <div className="bg-gray-50 border rounded-lg p-4 whitespace-pre-wrap">
              {testOutput}
            </div>
          </div>
        )}
      </div>

      {/* Scoring */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <div>
          <h2 className="text-xl font-semibold">Rate Model (1-10)</h2>
          <p className="text-sm text-gray-600 mt-1">
            Score this model specifically for <span className="font-semibold text-blue-600">{category}</span>
          </p>
        </div>
        <div className="flex items-center gap-4">
          <input
            type="range"
            min="1"
            max="10"
            value={score}
            onChange={(e) => setScore(parseInt(e.target.value))}
            className="flex-1"
          />
          <span className="text-2xl font-bold text-blue-600 w-16">{score}/10</span>
        </div>
        <button
          onClick={handleSaveScore}
          disabled={!selectedModel}
          className="w-full bg-green-600 text-white py-3 rounded-lg font-semibold hover:bg-green-700 disabled:bg-gray-400"
        >
          Save Score for {category.charAt(0).toUpperCase() + category.slice(1)}
        </button>
      </div>

      {/* Current Model Assignments */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <h2 className="text-xl font-semibold">Current Model Assignments for {category.charAt(0).toUpperCase() + category.slice(1)}</h2>
        <div className="grid grid-cols-1 gap-3">
          {[1, 2, 3, 4].map((pos) => {
            const posKey = `position${pos}` as 'position1' | 'position2' | 'position3' | 'position4'
            const modelId = currentPositions[posKey]
            const model = allModels.find(m => m.id === modelId)
            const label = pos === 1 ? 'Primary' : `Fallback ${pos - 1}`

            return (
              <div key={pos} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg border">
                <div className="flex items-center gap-3">
                  <span className={`px-3 py-1 rounded font-semibold text-sm ${
                    pos === 1 ? 'bg-green-600 text-white' : 'bg-blue-100 text-blue-700'
                  }`}>
                    {label}
                  </span>
                  <div>
                    {model ? (
                      <>
                        <p className="font-medium">{model.name}</p>
                        <p className="text-xs text-gray-500">{model.id}</p>
                      </>
                    ) : (
                      <p className="text-gray-400 italic">Not assigned</p>
                    )}
                  </div>
                </div>
                {model && model.userScore && (
                  <span className="text-sm font-semibold text-blue-600">{model.userScore}/10</span>
                )}
              </div>
            )
          })}
        </div>
      </div>

      {/* Save Model to Position */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <div>
          <h2 className="text-xl font-semibold">Assign Selected Model</h2>
          <p className="text-sm text-gray-600 mt-1">
            Choose which position to assign this model to
          </p>
        </div>

        {/* Position Selector */}
        <div>
          <label className="block text-sm font-medium mb-2">Select Position</label>
          <div className="grid grid-cols-4 gap-2">
            {[1, 2, 3, 4].map((pos) => {
              const label = pos === 1 ? 'Primary' : `Fallback ${pos - 1}`
              return (
                <button
                  key={pos}
                  onClick={() => setSelectedPosition(pos as 1 | 2 | 3 | 4)}
                  className={`px-4 py-3 rounded-lg border-2 font-semibold transition-colors ${
                    selectedPosition === pos
                      ? 'bg-blue-600 text-white border-blue-600'
                      : 'bg-white text-gray-700 border-gray-300 hover:border-blue-400'
                  }`}
                >
                  {label}
                </button>
              )
            })}
          </div>
        </div>

        <button
          onClick={handleSaveToPosition}
          disabled={saving || !selectedModel}
          className="w-full bg-green-600 text-white py-4 rounded-lg font-bold text-lg hover:bg-green-700 disabled:bg-gray-400"
        >
          {saving ? 'Saving...' : `Save to ${selectedPosition === 1 ? 'Primary' : `Fallback ${selectedPosition - 1}`}`}
        </button>
      </div>
    </div>
  )
}
