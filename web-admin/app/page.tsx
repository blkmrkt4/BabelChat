'use client'

import { useState, useEffect } from 'react'
import { getAIConfig, updateAIConfig, type AIConfig } from '@/lib/supabase'
import { getEvaluationsByCategory, type EvaluationResult } from '@/lib/evaluationStorage'
import { fetchOpenRouterModels, formatCost, type OpenRouterModel } from '@/lib/openrouter'
import {
  getPromptTemplatesByCategory,
  savePromptTemplate,
  deletePromptTemplate,
  type PromptTemplate
} from '@/lib/promptTemplateStorage'

type ModelWithScore = {
  modelId: string
  modelName: string
  score: number
  testCount: number
  openRouterModel?: OpenRouterModel
  evaluations: EvaluationResult[]
  translationScore?: number
  grammarScore?: number
  scoringScore?: number
  [key: string]: any
}

// Categories with sub-levels for grammar
const CATEGORY_OPTIONS = [
  { value: 'translation', label: 'Translation' },
  { value: 'grammar_minimal', label: 'Grammar - Minimal' },
  { value: 'grammar_moderate', label: 'Grammar - Moderate' },
  { value: 'grammar_verbose', label: 'Grammar - Verbose' },
  { value: 'scoring', label: 'Scoring' },
  { value: 'chatting', label: 'Chatting' },
] as const

export default function AIModelConfiguration() {
  // Category state - maps to database category + grammar level
  const [selectedCategory, setSelectedCategory] = useState<string>('translation')

  // Derived values for database operations
  const getDbCategory = () => {
    if (selectedCategory.startsWith('grammar_')) return 'grammar'
    return selectedCategory
  }

  const getGrammarLevel = (): 'minimal' | 'moderate' | 'verbose' | null => {
    if (selectedCategory === 'grammar_minimal') return 'minimal'
    if (selectedCategory === 'grammar_moderate') return 'moderate'
    if (selectedCategory === 'grammar_verbose') return 'verbose'
    return null
  }

  // Model data
  const [modelsWithScores, setModelsWithScores] = useState<ModelWithScore[]>([])
  const [allModels, setAllModels] = useState<OpenRouterModel[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  // Current configuration
  const [primaryModel, setPrimaryModel] = useState<string>('')
  const [fallback1, setFallback1] = useState<string>('')
  const [fallback2, setFallback2] = useState<string>('')
  const [fallback3, setFallback3] = useState<string>('')
  const [fallback4, setFallback4] = useState<string>('')

  // Prompt state
  const [promptTemplate, setPromptTemplate] = useState('')
  const [temperature, setTemperature] = useState(0.7)
  const [maxTokens, setMaxTokens] = useState(1000)

  // Template management
  const [promptTemplates, setPromptTemplates] = useState<PromptTemplate[]>([])
  const [showSaveDialog, setShowSaveDialog] = useState(false)
  const [newTemplateName, setNewTemplateName] = useState('')
  const [templatesLoading, setTemplatesLoading] = useState(false)

  // Cost threshold for comparison
  const [costThreshold, setCostThreshold] = useState<number>(90)

  useEffect(() => {
    loadData()
    loadPromptTemplates()
  }, [selectedCategory])

  const loadPromptTemplates = async () => {
    setTemplatesLoading(true)
    try {
      const templates = await getPromptTemplatesByCategory(getDbCategory())
      setPromptTemplates(templates)
    } catch (error) {
      console.error('Error loading prompt templates:', error)
    } finally {
      setTemplatesLoading(false)
    }
  }

  const loadData = async () => {
    setLoading(true)
    try {
      const dbCategory = getDbCategory()
      const grammarLevel = getGrammarLevel()

      // Load current configuration from Supabase
      const config = await getAIConfig(dbCategory)
      if (config) {
        setPrimaryModel(config.model_id)
        setFallback1(config.fallback_model_1_id || '')
        setFallback2(config.fallback_model_2_id || '')
        setFallback3(config.fallback_model_3_id || '')
        // Note: fallback_model_4 may not exist in DB yet
        setFallback4('')
        setTemperature(config.temperature)
        setMaxTokens(config.max_tokens)

        // Set prompt based on grammar level or main prompt
        if (grammarLevel === 'minimal' && config.grammar_level_1_prompt) {
          setPromptTemplate(config.grammar_level_1_prompt)
        } else if (grammarLevel === 'moderate' && config.grammar_level_2_prompt) {
          setPromptTemplate(config.grammar_level_2_prompt)
        } else if (grammarLevel === 'verbose' && config.grammar_level_3_prompt) {
          setPromptTemplate(config.grammar_level_3_prompt)
        } else {
          setPromptTemplate(config.prompt_template)
        }
      } else {
        // Reset if no config found
        setPrimaryModel('')
        setFallback1('')
        setFallback2('')
        setFallback3('')
        setFallback4('')
        setPromptTemplate('')
      }

      // Load all OpenRouter models
      const models = await fetchOpenRouterModels()
      setAllModels(models)

      // Load evaluation results
      const evaluations = await getEvaluationsByCategory(dbCategory)

      // Build models with scores
      const allModelIds = new Set<string>()
      evaluations.forEach(e => allModelIds.add(e.modelId))
      models.forEach(m => allModelIds.add(m.id))

      const getAvgScore = (modelId: string, evals: EvaluationResult[]) => {
        const modelEvals = evals.filter(e => e.modelId === modelId)
        if (modelEvals.length === 0) return undefined
        const sum = modelEvals.reduce((acc, e) => acc + e.score, 0)
        return sum / modelEvals.length
      }

      const summary = Array.from(allModelIds).map(modelId => {
        const modelEvals = evaluations.filter(e => e.modelId === modelId)
        const avgScore = getAvgScore(modelId, evaluations)
        const modelName = modelEvals[0]?.modelName ||
          models.find(m => m.id === modelId)?.name ||
          modelId
        const openRouterModel = models.find(m => m.id === modelId)

        // Calculate total cost for sorting
        let totalCost = Infinity
        if (openRouterModel) {
          totalCost = parseFloat(openRouterModel.pricing.prompt) + parseFloat(openRouterModel.pricing.completion)
        }

        return {
          modelId,
          modelName,
          score: avgScore || 0,
          testCount: modelEvals.length,
          openRouterModel,
          evaluations: modelEvals,
          totalCost,
        }
      })

      setModelsWithScores(summary)
    } catch (error) {
      console.error('Error loading data:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSave = async () => {
    if (!primaryModel) {
      alert('Please select a primary model')
      return
    }

    setSaving(true)
    try {
      const dbCategory = getDbCategory()
      const grammarLevel = getGrammarLevel()

      const primaryModelData = modelsWithScores.find(m => m.modelId === primaryModel)
      const fallback1Data = modelsWithScores.find(m => m.modelId === fallback1)
      const fallback2Data = modelsWithScores.find(m => m.modelId === fallback2)
      const fallback3Data = modelsWithScores.find(m => m.modelId === fallback3)

      const updates: Partial<AIConfig> = {
        model_id: primaryModel,
        model_name: primaryModelData?.modelName || primaryModel,
        model_provider: primaryModel.split('/')[0] || 'openrouter',
        fallback_model_1_id: fallback1 || null,
        fallback_model_1_name: fallback1Data?.modelName || null,
        fallback_model_2_id: fallback2 || null,
        fallback_model_2_name: fallback2Data?.modelName || null,
        fallback_model_3_id: fallback3 || null,
        fallback_model_3_name: fallback3Data?.modelName || null,
        temperature,
        max_tokens: maxTokens,
      }

      // Handle prompt based on grammar level
      if (grammarLevel === 'minimal') {
        updates.grammar_level_1_prompt = promptTemplate
      } else if (grammarLevel === 'moderate') {
        updates.grammar_level_2_prompt = promptTemplate
      } else if (grammarLevel === 'verbose') {
        updates.grammar_level_3_prompt = promptTemplate
      } else {
        updates.prompt_template = promptTemplate
      }

      await updateAIConfig(dbCategory, updates)
      alert('Configuration saved successfully!')
      await loadData()
    } catch (error) {
      console.error('Error saving configuration:', error)
      alert('Failed to save configuration. Check console for details.')
    } finally {
      setSaving(false)
    }
  }

  const handleLoadTemplate = (templateId: string) => {
    const template = promptTemplates.find(t => t.id === templateId)
    if (template) {
      // Load system_prompt into the prompt template field
      setPromptTemplate(template.system_prompt || '')
    }
  }

  const handleSaveTemplate = async () => {
    if (!newTemplateName.trim()) {
      alert('Please enter a template name')
      return
    }

    try {
      await savePromptTemplate({
        name: newTemplateName.trim(),
        category: getDbCategory() as 'translation' | 'grammar' | 'scoring' | 'chatting',
        system_prompt: promptTemplate,
        user_prompt: null,  // Could be extended to support user prompts
        description: null,
      })

      await loadPromptTemplates()
      setShowSaveDialog(false)
      setNewTemplateName('')
    } catch (error) {
      console.error('Error saving template:', error)
      alert('Failed to save template. It may already exist with that name.')
    }
  }

  const handleDeleteTemplate = async (templateId: string) => {
    if (confirm('Are you sure you want to delete this template?')) {
      try {
        await deletePromptTemplate(templateId)
        await loadPromptTemplates()
      } catch (error) {
        console.error('Error deleting template:', error)
        alert('Failed to delete template.')
      }
    }
  }

  const getScoreColor = (score: number) => {
    if (score >= 85) return 'text-green-600 font-bold'
    if (score >= 70) return 'text-blue-600 font-semibold'
    if (score >= 50) return 'text-orange-600'
    return 'text-red-600'
  }

  const getCostComparison = (modelId: string, score: number) => {
    const model = allModels.find(m => m.id === modelId)
    if (!model) return null

    const totalCost = parseFloat(model.pricing.prompt) + parseFloat(model.pricing.completion)

    const eligibleModels = modelsWithScores
      .filter(m => m.score >= costThreshold)
      .map(m => {
        const model = allModels.find(om => om.id === m.modelId)
        if (!model) return null
        return {
          modelId: m.modelId,
          score: m.score,
          totalCost: parseFloat(model.pricing.prompt) + parseFloat(model.pricing.completion)
        }
      })
      .filter(m => m !== null && m.totalCost > 0) as Array<{ modelId: string, score: number, totalCost: number }>

    if (eligibleModels.length === 0) {
      return { isBaseline: false, totalCost, costMultiple: null, baselineCost: null }
    }

    const baselineModel = eligibleModels.reduce((min, current) =>
      current.totalCost < min.totalCost ? current : min
    )

    const isBaseline = modelId === baselineModel.modelId
    const costMultiple = totalCost / baselineModel.totalCost

    return { isBaseline, totalCost, costMultiple, baselineCost: baselineModel.totalCost }
  }

  const getModelName = (modelId: string) => {
    if (!modelId) return 'Not assigned'
    const model = modelsWithScores.find(m => m.modelId === modelId)
    return model?.modelName || modelId
  }

  // Sort models: threshold-meeting models first (by cost, cheapest first, free last), then others
  const sortedModels = [...modelsWithScores].sort((a, b) => {
    const aAboveThreshold = a.score >= costThreshold
    const bAboveThreshold = b.score >= costThreshold
    const aIsFree = a.totalCost === 0
    const bIsFree = b.totalCost === 0

    // Both above threshold - sort by cost (free models last among threshold models)
    if (aAboveThreshold && bAboveThreshold) {
      if (aIsFree && !bIsFree) return 1  // a is free, put it after b
      if (!aIsFree && bIsFree) return -1 // b is free, put it after a
      return a.totalCost - b.totalCost   // both non-free, sort by cost
    }

    // Only a is above threshold - a comes first
    if (aAboveThreshold && !bAboveThreshold) return -1

    // Only b is above threshold - b comes first
    if (!aAboveThreshold && bAboveThreshold) return 1

    // Both below threshold - sort by cost (cheapest first, free last)
    if (aIsFree && !bIsFree) return 1
    if (!aIsFree && bIsFree) return -1
    return a.totalCost - b.totalCost
  })

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl">Loading configuration...</div>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* Header with Save Button */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">AI Model/Prompt Bindings</h1>
        <button
          onClick={handleSave}
          disabled={saving || !primaryModel}
          className="px-8 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed font-bold text-lg"
        >
          {saving ? 'Saving...' : 'Save Configuration'}
        </button>
      </div>

      {/* 1. Category Selector */}
      <div className="bg-white rounded-lg shadow p-6">
        <label className="block text-sm font-semibold text-gray-700 mb-3">
          1. Select Category
        </label>
        <div className="flex flex-wrap gap-2">
          {CATEGORY_OPTIONS.map(option => (
            <button
              key={option.value}
              onClick={() => setSelectedCategory(option.value)}
              className={`px-5 py-2.5 rounded-lg font-medium transition-colors ${
                selectedCategory === option.value
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {option.label}
            </button>
          ))}
        </div>
      </div>

      {/* 2. Master Prompt with Template Loader */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <div className="flex items-center justify-between">
          <label className="block text-sm font-semibold text-gray-700">
            2. Master Prompt
          </label>
          <div className="flex gap-2">
            <select
              onChange={(e) => {
                if (e.target.value) {
                  handleLoadTemplate(e.target.value)
                  e.target.value = ''
                }
              }}
              className="px-3 py-1.5 text-sm border rounded-lg focus:border-blue-500 focus:outline-none"
              defaultValue=""
              disabled={templatesLoading}
            >
              <option value="">{templatesLoading ? 'Loading...' : 'Load Template...'}</option>
              {promptTemplates.map(template => (
                <option key={template.id} value={template.id}>
                  {template.name}
                </option>
              ))}
            </select>
            <button
              onClick={() => setShowSaveDialog(true)}
              className="px-3 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Save as Template
            </button>
          </div>
        </div>

        <p className="text-xs text-gray-500">
          Available variables: {'{learning_language}'}, {'{native_language}'}, {'{explanation_language}'}
        </p>

        <textarea
          value={promptTemplate}
          onChange={(e) => setPromptTemplate(e.target.value)}
          className="w-full h-40 px-3 py-2 border rounded-lg font-mono text-sm focus:border-blue-500 focus:outline-none"
          placeholder="Enter the master prompt template..."
        />

        {/* Saved Templates */}
        {promptTemplates.length > 0 && (
          <div className="flex flex-wrap gap-2 pt-2 border-t">
            <span className="text-xs text-gray-500 py-1">Saved templates:</span>
            {promptTemplates.map(template => (
              <div key={template.id} className="flex items-center gap-1 bg-gray-100 px-2 py-1 rounded text-xs">
                <button
                  onClick={() => handleLoadTemplate(template.id)}
                  className="hover:text-blue-600"
                >
                  {template.name}
                </button>
                <button
                  onClick={() => handleDeleteTemplate(template.id)}
                  className="text-red-500 hover:text-red-700 ml-1"
                >
                  ×
                </button>
              </div>
            ))}
          </div>
        )}

        {/* Temperature and Max Tokens */}
        <div className="grid grid-cols-2 gap-4 pt-4 border-t">
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

      {/* 3. Current Model Selection Summary */}
      <div className="bg-blue-50 rounded-lg shadow p-6">
        <label className="block text-sm font-semibold text-gray-700 mb-3">
          3. Current Model Selection
        </label>
        <div className="flex flex-wrap gap-3">
          <div className="flex items-center gap-2 bg-white px-4 py-2 rounded-lg border-2 border-green-500">
            <span className="text-xs font-bold text-green-700 uppercase">Primary</span>
            <span className="font-medium">{getModelName(primaryModel)}</span>
          </div>
          <div className={`flex items-center gap-2 bg-white px-4 py-2 rounded-lg border ${fallback1 ? 'border-blue-400' : 'border-gray-200'}`}>
            <span className="text-xs font-bold text-blue-600 uppercase">FB1</span>
            <span className={fallback1 ? 'font-medium' : 'text-gray-400 italic'}>{getModelName(fallback1)}</span>
          </div>
          <div className={`flex items-center gap-2 bg-white px-4 py-2 rounded-lg border ${fallback2 ? 'border-blue-400' : 'border-gray-200'}`}>
            <span className="text-xs font-bold text-blue-600 uppercase">FB2</span>
            <span className={fallback2 ? 'font-medium' : 'text-gray-400 italic'}>{getModelName(fallback2)}</span>
          </div>
          <div className={`flex items-center gap-2 bg-white px-4 py-2 rounded-lg border ${fallback3 ? 'border-blue-400' : 'border-gray-200'}`}>
            <span className="text-xs font-bold text-blue-600 uppercase">FB3</span>
            <span className={fallback3 ? 'font-medium' : 'text-gray-400 italic'}>{getModelName(fallback3)}</span>
          </div>
          <div className={`flex items-center gap-2 bg-white px-4 py-2 rounded-lg border ${fallback4 ? 'border-blue-400' : 'border-gray-200'}`}>
            <span className="text-xs font-bold text-blue-600 uppercase">FB4</span>
            <span className={fallback4 ? 'font-medium' : 'text-gray-400 italic'}>{getModelName(fallback4)}</span>
          </div>
        </div>
      </div>

      {/* 4. Model Selection Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="p-4 bg-gray-50 border-b">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold">
                4. Select Models for {CATEGORY_OPTIONS.find(c => c.value === selectedCategory)?.label}
              </h2>
              <p className="text-sm text-gray-600 mt-1">
                Choose 1 primary model and up to 4 fallback models
              </p>
            </div>
            <div className="flex items-center gap-3">
              <label className="text-sm font-medium text-gray-700">Cost Threshold:</label>
              <input
                type="number"
                min="0"
                max="100"
                value={costThreshold}
                onChange={(e) => setCostThreshold(Number(e.target.value))}
                className="w-20 px-3 py-1 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none text-center"
              />
            </div>
          </div>
        </div>

        {sortedModels.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            <p className="mb-2">No models available.</p>
            <p className="text-sm">Check your OpenRouter API connection.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600 uppercase">
                    Primary
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600 uppercase">
                    FB 1
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600 uppercase">
                    FB 2
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600 uppercase">
                    FB 3
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600 uppercase">
                    FB 4
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600 uppercase">
                    Model Name
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold text-gray-600 uppercase">
                    Score
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold text-gray-600 uppercase">
                    Cost
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold text-gray-600 uppercase">
                    Tests
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {sortedModels.map((model) => (
                  <tr key={model.modelId} className="hover:bg-gray-50">
                    {/* Primary Radio */}
                    <td className="px-4 py-3 text-center">
                      <input
                        type="radio"
                        name="primary"
                        checked={primaryModel === model.modelId}
                        onChange={() => setPrimaryModel(model.modelId)}
                        className="w-4 h-4 text-green-600"
                      />
                    </td>

                    {/* Fallback 1 */}
                    <td className="px-4 py-3 text-center">
                      <input
                        type="checkbox"
                        checked={fallback1 === model.modelId}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setFallback1(model.modelId)
                          } else if (fallback1 === model.modelId) {
                            setFallback1('')
                          }
                        }}
                        disabled={primaryModel === model.modelId || fallback2 === model.modelId || fallback3 === model.modelId || fallback4 === model.modelId}
                        className="w-4 h-4 text-blue-600"
                      />
                    </td>

                    {/* Fallback 2 */}
                    <td className="px-4 py-3 text-center">
                      <input
                        type="checkbox"
                        checked={fallback2 === model.modelId}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setFallback2(model.modelId)
                          } else if (fallback2 === model.modelId) {
                            setFallback2('')
                          }
                        }}
                        disabled={primaryModel === model.modelId || fallback1 === model.modelId || fallback3 === model.modelId || fallback4 === model.modelId}
                        className="w-4 h-4 text-blue-600"
                      />
                    </td>

                    {/* Fallback 3 */}
                    <td className="px-4 py-3 text-center">
                      <input
                        type="checkbox"
                        checked={fallback3 === model.modelId}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setFallback3(model.modelId)
                          } else if (fallback3 === model.modelId) {
                            setFallback3('')
                          }
                        }}
                        disabled={primaryModel === model.modelId || fallback1 === model.modelId || fallback2 === model.modelId || fallback4 === model.modelId}
                        className="w-4 h-4 text-blue-600"
                      />
                    </td>

                    {/* Fallback 4 */}
                    <td className="px-4 py-3 text-center">
                      <input
                        type="checkbox"
                        checked={fallback4 === model.modelId}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setFallback4(model.modelId)
                          } else if (fallback4 === model.modelId) {
                            setFallback4('')
                          }
                        }}
                        disabled={primaryModel === model.modelId || fallback1 === model.modelId || fallback2 === model.modelId || fallback3 === model.modelId}
                        className="w-4 h-4 text-blue-600"
                      />
                    </td>

                    {/* Model Name */}
                    <td className="px-4 py-3">
                      <div className="font-medium text-gray-900">{model.modelName}</div>
                      <div className="text-xs text-gray-500 truncate max-w-xs">
                        {model.modelId}
                      </div>
                    </td>

                    {/* Score */}
                    <td className="px-4 py-3 text-right">
                      {model.score > 0 ? (
                        <span className={`text-sm font-semibold ${getScoreColor(model.score)}`}>
                          {model.score.toFixed(0)}
                        </span>
                      ) : (
                        <span className="text-sm text-gray-400">—</span>
                      )}
                    </td>

                    {/* Cost */}
                    <td className="px-4 py-3 text-right text-sm">
                      {(() => {
                        const costComp = getCostComparison(model.modelId, model.score)
                        if (!costComp) return <span className="text-gray-400">N/A</span>

                        if (costComp.totalCost === 0) {
                          return <div className="font-medium text-blue-600">Free</div>
                        }

                        if (costComp.isBaseline) {
                          return (
                            <div>
                              <div className="font-semibold text-green-600">Baseline</div>
                              <div className="text-xs text-gray-600">
                                ${(costComp.totalCost * 1000).toFixed(4)}/1K
                              </div>
                            </div>
                          )
                        } else if (costComp.costMultiple !== null) {
                          return (
                            <div>
                              <div className="font-medium">{costComp.costMultiple.toFixed(1)}x</div>
                              <div className="text-xs text-gray-600">
                                ${(costComp.totalCost * 1000).toFixed(4)}/1K
                              </div>
                            </div>
                          )
                        } else {
                          return (
                            <div className="text-gray-500 text-xs">
                              ${(costComp.totalCost * 1000).toFixed(4)}/1K
                            </div>
                          )
                        }
                      })()}
                    </td>

                    {/* Test Count */}
                    <td className="px-4 py-3 text-right text-sm">
                      {model.testCount > 0 ? (
                        <span className="text-blue-600 font-medium">{model.testCount}</span>
                      ) : (
                        <span className="text-gray-400">0</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Save Template Dialog */}
      {showSaveDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-semibold mb-4">Save Prompt Template</h3>
            <input
              type="text"
              value={newTemplateName}
              onChange={(e) => setNewTemplateName(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleSaveTemplate()}
              placeholder="Enter template name..."
              className="w-full px-3 py-2 border rounded-lg mb-4"
              autoFocus
            />
            <div className="flex gap-2 justify-end">
              <button
                onClick={() => {
                  setShowSaveDialog(false)
                  setNewTemplateName('')
                }}
                className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveTemplate}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
