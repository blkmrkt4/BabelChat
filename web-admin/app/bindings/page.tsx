'use client'

import { useState, useEffect } from 'react'
import { getAIConfig, updateAIConfig, type AIConfig } from '@/lib/supabase'
import { getEvaluationsByCategory, type EvaluationResult } from '@/lib/evaluationStorage'
import { fetchOpenRouterModels, type OpenRouterModel } from '@/lib/openrouter'

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
  [key: string]: any // Support dynamic category scores
}

const DEFAULT_CATEGORIES = ['translation', 'grammar', 'scoring'] as const

export default function AIModelBindings() {
  const [category, setCategory] = useState<string>('translation')
  const [customCategories, setCustomCategories] = useState<string[]>([])
  const [modelsWithScores, setModelsWithScores] = useState<ModelWithScore[]>([])
  const [allModels, setAllModels] = useState<OpenRouterModel[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [selectedModelDetails, setSelectedModelDetails] = useState<ModelWithScore | null>(null)
  const [costThreshold, setCostThreshold] = useState<number>(90)

  // Current configuration
  const [primaryModel, setPrimaryModel] = useState<string>('')
  const [fallback1, setFallback1] = useState<string>('')
  const [fallback2, setFallback2] = useState<string>('')
  const [fallback3, setFallback3] = useState<string>('')

  useEffect(() => {
    loadCustomCategories()
    loadData()
  }, [category])

  const loadCustomCategories = () => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('custom_categories')
      if (saved) {
        try {
          const parsed = JSON.parse(saved)
          setCustomCategories(parsed)
        } catch (e) {
          console.error('Error loading custom categories:', e)
        }
      }
    }
  }

  const getAllCategories = () => {
    return [...DEFAULT_CATEGORIES, ...customCategories]
  }

  const loadData = async () => {
    setLoading(true)
    try {
      // Load current configuration
      const config = await getAIConfig(category)
      if (config) {
        setPrimaryModel(config.model_id)
        setFallback1(config.fallback_model_1_id || '')
        setFallback2(config.fallback_model_2_id || '')
        setFallback3(config.fallback_model_3_id || '')
      }

      // Load all OpenRouter models
      const models = await fetchOpenRouterModels()
      setAllModels(models)

      // Load evaluation results from ALL categories (default + custom)
      const allCategories = getAllCategories()
      const categoryEvaluations: Record<string, EvaluationResult[]> = {}

      for (const cat of allCategories) {
        categoryEvaluations[cat] = await getEvaluationsByCategory(cat)
      }

      // Create a map of all models with their scores across all categories
      const allModelIds = new Set<string>()

      // Add model IDs from all evaluations
      Object.values(categoryEvaluations).forEach(evals => {
        evals.forEach(e => allModelIds.add(e.modelId))
      })

      // Add all OpenRouter models
      models.forEach(m => allModelIds.add(m.id))

      // Helper to calculate average score for a model in a category
      const getAvgScore = (modelId: string, evals: EvaluationResult[]) => {
        const modelEvals = evals.filter(e => e.modelId === modelId)
        if (modelEvals.length === 0) return undefined
        const sum = modelEvals.reduce((acc, e) => acc + e.score, 0)
        return sum / modelEvals.length
      }

      // Build summary for all models
      const summary = Array.from(allModelIds).map(modelId => {
        // Calculate scores for all categories dynamically
        const categoryScores: Record<string, number | undefined> = {}
        allCategories.forEach(cat => {
          const score = getAvgScore(modelId, categoryEvaluations[cat])
          categoryScores[`${cat}Score`] = score
        })

        // Get all evaluations for the current category
        const currentCategoryEvals = categoryEvaluations[category] || []
        const modelEvals = currentCategoryEvals.filter(e => e.modelId === modelId)

        // Use current category score as the primary score, or 0 if not evaluated
        const primaryScore = categoryScores[`${category}Score`]

        // Get model name from evaluations or OpenRouter
        const modelName = modelEvals[0]?.modelName ||
          models.find(m => m.id === modelId)?.name ||
          modelId

        return {
          modelId,
          modelName,
          score: primaryScore || 0,
          testCount: modelEvals.length,
          openRouterModel: models.find(m => m.id === modelId),
          evaluations: modelEvals,
          translationScore: categoryScores['translationScore'],
          grammarScore: categoryScores['grammarScore'],
          scoringScore: categoryScores['scoringScore'],
          ...categoryScores // Include all dynamic category scores
        }
      }).sort((a, b) => {
        // Sort by primary score (current category), then by translation, then grammar, then scoring
        if (b.score !== a.score) return b.score - a.score
        if ((b.translationScore || 0) !== (a.translationScore || 0)) return (b.translationScore || 0) - (a.translationScore || 0)
        if ((b.grammarScore || 0) !== (a.grammarScore || 0)) return (b.grammarScore || 0) - (a.grammarScore || 0)
        return (b.scoringScore || 0) - (a.scoringScore || 0)
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
      const primaryModelData = modelsWithScores.find(m => m.modelId === primaryModel)
      const fallback1Data = modelsWithScores.find(m => m.modelId === fallback1)
      const fallback2Data = modelsWithScores.find(m => m.modelId === fallback2)
      const fallback3Data = modelsWithScores.find(m => m.modelId === fallback3)

      const updates: Partial<AIConfig> = {
        model_id: primaryModel,
        model_name: primaryModelData?.modelName || primaryModel,
        fallback_model_1_id: fallback1 || null,
        fallback_model_1_name: fallback1Data?.modelName || null,
        fallback_model_2_id: fallback2 || null,
        fallback_model_2_name: fallback2Data?.modelName || null,
        fallback_model_3_id: fallback3 || null,
        fallback_model_3_name: fallback3Data?.modelName || null,
      }

      await updateAIConfig(category, updates)
      alert('✅ Configuration saved successfully!')
      await loadData()
    } catch (error) {
      console.error('Error saving configuration:', error)
      alert('❌ Failed to save configuration. Check console for details.')
    } finally {
      setSaving(false)
    }
  }

  const getScoreColor = (score: number) => {
    if (score >= 85) return 'text-green-600 font-bold'
    if (score >= 70) return 'text-blue-600 font-semibold'
    if (score >= 50) return 'text-orange-600'
    return 'text-red-600'
  }

  // Calculate cost baseline and comparisons (same as Round Robin Results)
  const getCostComparison = (modelId: string, score: number) => {
    const model = allModels.find(m => m.id === modelId)
    if (!model) return null

    const totalCost = parseFloat(model.pricing.prompt) + parseFloat(model.pricing.completion)

    // Find baseline: lowest cost model with score >= threshold (excluding free models)
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
      .filter(m => m !== null && m.totalCost > 0) as Array<{ modelId: string, score: number, totalCost: number }>  // Exclude free models

    if (eligibleModels.length === 0) {
      // No baseline, just show total cost
      return {
        isBaseline: false,
        totalCost,
        costMultiple: null,
        baselineCost: null
      }
    }

    // Find the lowest cost among eligible models (all non-free)
    const baselineModel = eligibleModels.reduce((min, current) =>
      current.totalCost < min.totalCost ? current : min
    )

    const isBaseline = modelId === baselineModel.modelId
    const costMultiple = totalCost / baselineModel.totalCost

    return {
      isBaseline,
      totalCost,
      costMultiple,
      baselineCost: baselineModel.totalCost
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl">Loading models and scores...</div>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">AI Model Bindings</h1>
        <button
          onClick={handleSave}
          disabled={saving || !primaryModel}
          className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed font-semibold"
        >
          {saving ? 'Saving...' : '💾 Save Configuration'}
        </button>
      </div>

      {/* Category Selector */}
      <div className="bg-white rounded-lg shadow p-4">
        <label className="block text-sm font-semibold text-gray-700 mb-2">
          Category
        </label>
        <div className="flex flex-wrap gap-2">
          {getAllCategories().map(cat => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`px-4 py-2 rounded-lg font-medium ${
                category === cat
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {cat.charAt(0).toUpperCase() + cat.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {/* Model Selection */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="p-4 bg-gray-50 border-b">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold">
                Select Models for {category.charAt(0).toUpperCase() + category.slice(1)}
              </h2>
              <p className="text-sm text-gray-600 mt-1">
                Choose 1 primary model and up to 3 fallback models. All available models shown with scores across all categories (first letter prefix: T=Translation, G=Grammar, S=Scoring, C=Chatting, etc.).
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

        {modelsWithScores.length === 0 ? (
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
                    Fallback 1
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600 uppercase">
                    Fallback 2
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600 uppercase">
                    Fallback 3
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-600 uppercase">
                    Model Name
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold text-gray-600 uppercase">
                    Scores <span className="text-[10px] font-normal">(T/G/S)</span>
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold text-gray-600 uppercase">
                    Cost
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold text-gray-600 uppercase">
                    Tests <span className="text-[10px] font-normal">({category.charAt(0).toUpperCase()})</span>
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {modelsWithScores.map((model) => (
                  <tr key={model.modelId} className="hover:bg-gray-50">
                    {/* Primary Radio */}
                    <td className="px-4 py-3 text-center">
                      <input
                        type="radio"
                        name="primary"
                        checked={primaryModel === model.modelId}
                        onChange={() => setPrimaryModel(model.modelId)}
                        className="w-4 h-4 text-blue-600"
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
                        disabled={primaryModel === model.modelId || fallback2 === model.modelId || fallback3 === model.modelId}
                        className="w-4 h-4 text-green-600"
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
                        disabled={primaryModel === model.modelId || fallback1 === model.modelId || fallback3 === model.modelId}
                        className="w-4 h-4 text-yellow-600"
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
                        disabled={primaryModel === model.modelId || fallback1 === model.modelId || fallback2 === model.modelId}
                        className="w-4 h-4 text-orange-600"
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
                      <div className="flex items-center justify-end gap-2 flex-wrap">
                        {(() => {
                          const categories = getAllCategories()
                          const scores = categories
                            .map(cat => {
                              const scoreKey = `${cat}Score`
                              const score = model[scoreKey]
                              if (score !== undefined) {
                                // Use first letter as prefix (T for translation, G for grammar, etc.)
                                const prefix = cat.charAt(0).toUpperCase()
                                return { prefix, score, category: cat }
                              }
                              return null
                            })
                            .filter(Boolean)

                          if (scores.length === 0) {
                            return <span className="text-sm text-gray-400">No scores</span>
                          }

                          return scores.map(({ prefix, score, category }) => (
                            <span
                              key={category}
                              className={`text-sm font-semibold ${getScoreColor(score)}`}
                              title={`${category.charAt(0).toUpperCase() + category.slice(1)}: ${score.toFixed(0)}`}
                            >
                              {prefix}{score.toFixed(0)}
                            </span>
                          ))
                        })()}
                      </div>
                    </td>

                    {/* Cost */}
                    <td className="px-4 py-3 text-right text-sm">
                      {(() => {
                        const costComp = getCostComparison(model.modelId, model.score)
                        if (!costComp) return <span className="text-gray-400">N/A</span>

                        // Check if model is free
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
                              <div className="font-medium">{costComp.costMultiple.toFixed(1)}x baseline</div>
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
                        <button
                          onClick={() => setSelectedModelDetails(model)}
                          className="text-blue-600 hover:text-blue-800 underline font-medium"
                        >
                          {model.testCount}
                        </button>
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

      {/* Current Selection Summary */}
      {primaryModel && (
        <div className="bg-blue-50 rounded-lg p-4">
          <h3 className="font-semibold text-blue-900 mb-2">Current Selection</h3>
          <div className="space-y-1 text-sm">
            <div>
              <span className="font-medium">Primary:</span>{' '}
              {modelsWithScores.find(m => m.modelId === primaryModel)?.modelName || 'None'}
            </div>
            {fallback1 && (
              <div>
                <span className="font-medium">Fallback 1:</span>{' '}
                {modelsWithScores.find(m => m.modelId === fallback1)?.modelName}
              </div>
            )}
            {fallback2 && (
              <div>
                <span className="font-medium">Fallback 2:</span>{' '}
                {modelsWithScores.find(m => m.modelId === fallback2)?.modelName}
              </div>
            )}
            {fallback3 && (
              <div>
                <span className="font-medium">Fallback 3:</span>{' '}
                {modelsWithScores.find(m => m.modelId === fallback3)?.modelName}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Test Details Modal */}
      {selectedModelDetails && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
          onClick={() => setSelectedModelDetails(null)}
        >
          <div
            className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-6 border-b bg-gray-50">
              <div className="flex justify-between items-start">
                <div>
                  <h2 className="text-xl font-bold text-gray-900">{selectedModelDetails.modelName}</h2>
                  <p className="text-sm text-gray-600 mt-1">
                    {selectedModelDetails.testCount} test{selectedModelDetails.testCount !== 1 ? 's' : ''} •
                    Average Score: <span className={`font-bold ${getScoreColor(selectedModelDetails.score)}`}>
                      {selectedModelDetails.score.toFixed(1)}
                    </span>
                  </p>
                </div>
                <button
                  onClick={() => setSelectedModelDetails(null)}
                  className="text-gray-400 hover:text-gray-600 text-2xl leading-none"
                >
                  ×
                </button>
              </div>
            </div>

            <div className="p-6 overflow-y-auto max-h-[calc(90vh-140px)]">
              <div className="space-y-4">
                {selectedModelDetails.evaluations
                  .sort((a, b) => b.score - a.score)
                  .map((evaluation, index) => (
                  <div key={evaluation.id} className="bg-gray-50 rounded-lg p-4 border">
                    <div className="flex justify-between items-start mb-3">
                      <div>
                        <div className="font-semibold text-gray-900">
                          Test {index + 1}: {evaluation.sourceLang} → {evaluation.targetLang}
                        </div>
                        <div className="text-xs text-gray-500 mt-1">
                          {new Date(evaluation.timestamp).toLocaleString()}
                        </div>
                      </div>
                      <div className={`text-2xl font-bold ${getScoreColor(evaluation.score)}`}>
                        {evaluation.score.toFixed(0)}
                      </div>
                    </div>

                    {evaluation.detailedScores && (
                      <div className="grid grid-cols-2 gap-2 text-sm mb-3">
                        {evaluation.detailedScores.translationAccuracy && (
                          <div className="bg-white p-2 rounded">
                            <div className="text-gray-600 text-xs">Translation Accuracy</div>
                            <div className="font-semibold">{evaluation.detailedScores.translationAccuracy.score.toFixed(1)}</div>
                          </div>
                        )}
                        {evaluation.detailedScores.responseSpeed && (
                          <div className="bg-white p-2 rounded">
                            <div className="text-gray-600 text-xs">Response Speed</div>
                            <div className="font-semibold">{evaluation.detailedScores.responseSpeed.score.toFixed(1)}</div>
                          </div>
                        )}
                      </div>
                    )}

                    <div className="text-sm">
                      <div className="font-medium text-gray-700 mb-1">Test Input:</div>
                      <div className="bg-white p-2 rounded text-gray-900 border">{evaluation.testInput}</div>
                    </div>

                    {evaluation.error && (
                      <div className="mt-2 text-sm">
                        <div className="font-medium text-red-600 mb-1">Error:</div>
                        <div className="bg-red-50 p-2 rounded text-red-900 border border-red-200">{evaluation.error}</div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>

            <div className="p-4 border-t bg-gray-50 flex justify-end">
              <button
                onClick={() => setSelectedModelDetails(null)}
                className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
