'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import {
  getAllEvaluations,
  getEvaluationsByCategory,
  getAverageScore,
  clearEvaluations,
  deleteModelEvaluations,
  getLanguagePair,
  getUniqueLanguagePairs,
  type EvaluationResult
} from '@/lib/evaluationStorage'
import { fetchOpenRouterModels, formatContextLength, type OpenRouterModel } from '@/lib/openrouter'

const DEFAULT_CATEGORIES = ['translation', 'grammar', 'scoring'] as const
type SortBy = 'score' | 'name' | 'recent'

export default function RoundRobinResults() {
  const [category, setCategory] = useState<string>('translation')
  const [customCategories, setCustomCategories] = useState<string[]>([])
  const [evaluations, setEvaluations] = useState<EvaluationResult[]>([])
  const [languagePair, setLanguagePair] = useState<string>('all')
  const [sortBy, setSortBy] = useState<SortBy>('score')  // Default to score
  const [selectedEval, setSelectedEval] = useState<EvaluationResult | null>(null)
  const [costThreshold, setCostThreshold] = useState<number>(90)
  const [allModels, setAllModels] = useState<OpenRouterModel[]>([])

  useEffect(() => {
    loadEvaluations()
    loadCustomCategories()
    loadModels()
  }, [category])

  // Refresh evaluations when page becomes visible
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        loadEvaluations()
      }
    }

    document.addEventListener('visibilitychange', handleVisibilityChange)
    return () => document.removeEventListener('visibilitychange', handleVisibilityChange)
  }, [category])

  const loadCustomCategories = () => {
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

  const getAllCategories = () => {
    return [...DEFAULT_CATEGORIES, ...customCategories]
  }

  const loadEvaluations = async () => {
    console.log(`Loading evaluations for category: ${category}`)
    const evals = await getEvaluationsByCategory(category)
    console.log(`Found ${evals.length} evaluations:`, evals)
    const allEvals = await getAllEvaluations()
    console.log(`All evaluations in storage:`, allEvals)
    setEvaluations(evals)
  }

  const loadModels = async () => {
    try {
      const models = await fetchOpenRouterModels()
      setAllModels(models)
    } catch (error) {
      console.error('Error loading models:', error)
    }
  }

  const getModelSummary = () => {
    // Filter evaluations by language pair
    const filteredEvals = languagePair === 'all'
      ? evaluations
      : evaluations.filter(e => getLanguagePair(e.sourceLang, e.targetLang) === languagePair)

    // Group evaluations by model
    const modelMap = new Map<string, {
      modelId: string
      modelName: string
      scores: number[]
      evaluations: EvaluationResult[]
    }>()

    filteredEvals.forEach(evaluation => {
      if (!modelMap.has(evaluation.modelId)) {
        modelMap.set(evaluation.modelId, {
          modelId: evaluation.modelId,
          modelName: evaluation.modelName,
          scores: [],
          evaluations: []
        })
      }

      const model = modelMap.get(evaluation.modelId)!
      model.scores.push(evaluation.score)
      model.evaluations.push(evaluation)
    })

    // Since each model now only has one score (highest), just get that score
    const summary = Array.from(modelMap.values()).map(model => ({
      ...model,
      score: model.scores[0], // Only one score per model now
      testCount: model.scores.length,
    }))

    // Sort
    switch (sortBy) {
      case 'score':
        return summary.sort((a, b) => b.score - a.score)
      case 'name':
        return summary.sort((a, b) => a.modelName.localeCompare(b.modelName))
      case 'recent':
        return summary.sort((a, b) => {
          const aRecent = Math.max(...a.evaluations.map(e => new Date(e.timestamp).getTime()))
          const bRecent = Math.max(...b.evaluations.map(e => new Date(e.timestamp).getTime()))
          return bRecent - aRecent
        })
      default:
        return summary
    }
  }

  // Calculate cost baseline and comparisons
  const getCostComparison = (modelId: string, score: number) => {
    const model = allModels.find(m => m.id === modelId)
    if (!model) return null

    const totalCost = parseFloat(model.pricing.prompt) + parseFloat(model.pricing.completion)

    // Find baseline: lowest cost model with score >= threshold (excluding free models)
    const eligibleModels = getModelSummary()
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
      .filter(m => m !== null && m.totalCost > 0) as Array<{ modelId: string, score: number, totalCost: number }>  // Exclude free models (cost = 0)

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

  const handleClearAll = async () => {
    if (confirm('⚠️ WARNING: This will DELETE ALL evaluation results from Supabase database. All test history will be permanently lost. This cannot be undone.\n\nAre you absolutely sure you want to proceed?')) {
      await clearEvaluations()
      await loadEvaluations()
    }
  }

  const modelSummary = getModelSummary()

  const handleDeleteModel = async (modelId: string, modelName: string) => {
    if (confirm(`⚠️ Delete all evaluations for "${modelName}" in the "${category}" category?\n\nThis cannot be undone.`)) {
      try {
        await deleteModelEvaluations(modelId, category)
        await loadEvaluations()
      } catch (error) {
        console.error('Error deleting model evaluations:', error)
        alert('Failed to delete model evaluations. Check console for details.')
      }
    }
  }

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp)
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)

    // Relative time for recent tests
    if (diffMins < 1) return 'Just now'
    if (diffMins < 60) return `${diffMins}m ago`
    if (diffHours < 24) return `${diffHours}h ago`
    if (diffDays < 7) return `${diffDays}d ago`

    // Absolute date for older tests
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <h1 className="text-3xl font-bold">Round Robin Results</h1>

      {/* Debug Info */}
      <div className="bg-blue-50 border-2 border-blue-400 rounded-lg p-4">
        <p className="text-sm font-semibold text-blue-900 mb-2">🗄️ Supabase Storage Info</p>
        <div className="text-xs space-y-1">
          <p><span className="font-semibold">Current Category:</span> {category}</p>
          <p><span className="font-semibold">Evaluations in Current Category:</span> {evaluations.length}</p>
          <button
            onClick={async () => {
              const all = await getAllEvaluations()
              console.log('All evaluations from Supabase:', all)

              // Group by model to show per-model scores
              const byModel = all.reduce((acc: any, e: any) => {
                if (!acc[e.modelId]) acc[e.modelId] = []
                acc[e.modelId].push(e)
                return acc
              }, {})

              console.log('Scores by model:')
              Object.entries(byModel).forEach(([modelId, evals]: [string, any]) => {
                console.log(`\n${evals[0].modelName} (${modelId}):`)
                evals.forEach((e: any, i: number) => {
                  console.log(`  Test ${i+1}: score=${e.score}, error=${e.error || 'none'}`)
                })
                const scores = evals.map((e: any) => e.score)
                console.log(`  Average: ${(scores.reduce((a: number, b: number) => a + b, 0) / scores.length).toFixed(1)}`)
                console.log(`  Min/Max: ${Math.min(...scores)} - ${Math.max(...scores)}`)
              })

              alert(`Total evaluations: ${all.length}\nCheck console for detailed breakdown`)
            }}
            className="mt-2 px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 text-xs"
          >
            Debug Scores in Console
          </button>
          <button
            onClick={async () => {
              try {
                const { data, error, count } = await supabase
                  .from('model_evaluations')
                  .select('*', { count: 'exact' })
                  .limit(5)

                if (error) {
                  console.error('Supabase error:', error)
                  alert(`Error: ${error.message}`)
                } else {
                  console.log('Sample data:', data)
                  alert(`Found ${count} evaluations in Supabase database.\nShowing first 5 in console.`)
                }
              } catch (err: any) {
                console.error('Error:', err)
                alert(`Error: ${err.message}`)
              }
            }}
            className="ml-2 mt-2 px-3 py-1 bg-green-600 text-white rounded hover:bg-green-700 text-xs"
          >
            Check Supabase Database
          </button>
        </div>
      </div>

      {/* Category and Language Pair Selector */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Category</label>
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
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Language Pair</label>
          <div className="flex flex-wrap gap-2">
            <button
              onClick={() => setLanguagePair('all')}
              className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                languagePair === 'all'
                  ? 'bg-purple-600 text-white'
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              }`}
            >
              All Languages
            </button>
            {getUniqueLanguagePairs(evaluations).map((pair) => (
              <button
                key={pair}
                onClick={() => setLanguagePair(pair)}
                className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                  languagePair === pair
                    ? 'bg-purple-600 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                {pair}
              </button>
            ))}
          </div>
        </div>

        <div className="flex gap-2">
          <button
            onClick={loadEvaluations}
            className="px-4 py-2 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200"
          >
            🔄 Refresh
          </button>
          <button
            onClick={handleClearAll}
            className="px-4 py-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200"
          >
            Clear All Results
          </button>
        </div>
      </div>

      {/* Sort Options */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex gap-2 items-center">
          <label className="font-medium">Sort by:</label>
          {(['score', 'name', 'recent'] as SortBy[]).map((sort) => (
            <button
              key={sort}
              onClick={() => setSortBy(sort)}
              className={`px-4 py-2 rounded-lg border-2 transition-colors ${
                sortBy === sort
                  ? 'bg-blue-100 border-blue-600 text-blue-700'
                  : 'border-gray-300 hover:border-gray-400'
              }`}
            >
              {sort === 'score' ? 'Score' : sort === 'name' ? 'Model Name' : 'Most Recent'}
            </button>
          ))}
        </div>
      </div>

      {/* Summary Stats */}
      {evaluations.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Overall Statistics</h2>
          <div className="grid grid-cols-4 gap-4">
            <div className="bg-blue-50 p-4 rounded-lg">
              <p className="text-sm text-gray-600">Total Tests</p>
              <p className="text-2xl font-bold">{evaluations.length}</p>
            </div>
            <div className="bg-green-50 p-4 rounded-lg">
              <p className="text-sm text-gray-600">Models Tested</p>
              <p className="text-2xl font-bold">{modelSummary.length}</p>
            </div>
            <div className="bg-purple-50 p-4 rounded-lg">
              <p className="text-sm text-gray-600">Avg Score <span className="text-xs">(0-100)</span></p>
              <p className="text-2xl font-bold">
                {evaluations.length > 0 ? (evaluations.reduce((a, b) => a + b.score, 0) / evaluations.length).toFixed(1) : '0.0'}
              </p>
            </div>
            <div className="bg-yellow-50 p-4 rounded-lg">
              <p className="text-sm text-gray-600">Top Model</p>
              <p className="text-lg font-bold truncate">{modelSummary[0]?.modelName || 'N/A'}</p>
            </div>
          </div>
        </div>
      )}

      {/* Model Rankings */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="p-6 flex items-center justify-between">
          <h2 className="text-xl font-semibold">Model Rankings</h2>
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

        {modelSummary.length === 0 ? (
          <div className="p-12 text-center text-gray-500">
            <p className="text-lg mb-2">No evaluation results yet</p>
            <p className="text-sm">Run evaluations to see model performance against Google Translate</p>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-semibold">Rank</th>
                <th className="px-6 py-3 text-left text-sm font-semibold">Model</th>
                <th className="px-6 py-3 text-left text-sm font-semibold">
                  Score
                  <span className="ml-1 text-xs font-normal text-gray-500">(0-100)</span>
                </th>
                <th className="px-6 py-3 text-left text-sm font-semibold">Context</th>
                <th className="px-6 py-3 text-left text-sm font-semibold">Cost</th>
                <th className="px-6 py-3 text-left text-sm font-semibold">Latest Test</th>
                <th className="px-6 py-3 text-left text-sm font-semibold">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {modelSummary.map((model, idx) => (
                <tr key={model.modelId} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <span className={`text-2xl font-bold ${
                      idx === 0 ? 'text-yellow-500' :
                      idx === 1 ? 'text-gray-400' :
                      idx === 2 ? 'text-orange-600' :
                      'text-gray-600'
                    }`}>
                      #{idx + 1}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <p className="font-medium">{model.modelName}</p>
                    <p className="text-xs text-gray-500">{model.modelId}</p>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <span className={`text-2xl font-bold ${
                        model.score >= 85 ? 'text-green-600' :
                        model.score >= 70 ? 'text-blue-600' :
                        model.score >= 50 ? 'text-yellow-600' :
                        'text-red-600'
                      }`}>
                        {model.score.toFixed(1)}
                      </span>
                      <div className="flex-1 bg-gray-200 rounded-full h-2 w-24">
                        <div
                          className={`h-2 rounded-full ${
                            model.score >= 85 ? 'bg-green-600' :
                            model.score >= 70 ? 'bg-blue-600' :
                            model.score >= 50 ? 'bg-yellow-600' :
                            'bg-red-600'
                          }`}
                          style={{ width: `${model.score}%` }}
                        />
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {(() => {
                      const modelData = allModels.find(m => m.id === model.modelId)
                      if (!modelData) return <span className="text-gray-400">N/A</span>
                      return formatContextLength(modelData.context_length)
                    })()}
                  </td>
                  <td className="px-6 py-4 text-sm">
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
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {formatTimestamp(model.evaluations[model.evaluations.length - 1].timestamp)}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <button
                        onClick={() => setSelectedEval(model.evaluations[0])}
                        className="text-sm text-blue-600 hover:text-blue-800"
                      >
                        View Details
                      </button>
                      <button
                        onClick={() => handleDeleteModel(model.modelId, model.modelName)}
                        className="text-sm text-red-600 hover:text-red-800"
                        title="Delete this model's evaluation"
                      >
                        🗑️ Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Individual Test Results */}
      {evaluations.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">All Test Results</h2>
          <div className="space-y-4 max-h-96 overflow-y-auto">
            {evaluations
              .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
              .map((evaluation) => (
              <div
                key={evaluation.id}
                onClick={() => setSelectedEval(evaluation)}
                className={`border rounded-lg p-4 cursor-pointer hover:bg-blue-50 ${
                  evaluation.error ? 'bg-red-50 border-red-300' : ''
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <p className="font-medium">{evaluation.modelName}</p>
                    {evaluation.error && (
                      <span className="px-2 py-1 text-xs bg-red-600 text-white rounded">
                        {evaluation.errorType === 'json_parse' ? '⚠️ JSON Error' :
                         evaluation.errorType === 'api_error' ? '❌ API Error' :
                         evaluation.errorType === 'timeout' ? '⏱️ Timeout' :
                         '❌ Error'}
                      </span>
                    )}
                  </div>
                  <span className={`text-xl font-bold ${
                    evaluation.error ? 'text-red-600' :
                    evaluation.score >= 85 ? 'text-green-600' :
                    evaluation.score >= 70 ? 'text-blue-600' :
                    evaluation.score >= 50 ? 'text-yellow-600' :
                    'text-red-600'
                  }`}>
                    {evaluation.error ? 'FAILED' : `${evaluation.score}/115`}
                  </span>
                </div>
                <div className="text-sm text-gray-600">
                  <p>{evaluation.sourceLang} → {evaluation.targetLang}: "{evaluation.testInput}"</p>
                  {evaluation.error && (
                    <p className="text-xs mt-1 text-red-600">
                      Error: {evaluation.error.substring(0, 100)}{evaluation.error.length > 100 ? '...' : ''}
                    </p>
                  )}
                  <p className="text-xs mt-1">
                    {new Date(evaluation.timestamp).toLocaleString()} • Evaluated by {evaluation.evaluationModelName}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {selectedEval && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-6 z-50">
          <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto p-6">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h2 className="text-2xl font-bold">{selectedEval.modelName}</h2>
                <p className="text-sm text-gray-500 mt-1">
                  Tested {formatTimestamp(selectedEval.timestamp)} • {new Date(selectedEval.timestamp).toLocaleString()}
                </p>
              </div>
              <button
                onClick={() => setSelectedEval(null)}
                className="text-gray-500 hover:text-gray-700 text-2xl"
              >
                ×
              </button>
            </div>

            <div className="space-y-4">
              {selectedEval.error ? (
                <div className="bg-red-100 border-2 border-red-400 rounded-lg p-4">
                  <div className="flex items-start gap-3">
                    <span className="text-4xl">❌</span>
                    <div className="flex-1">
                      <p className="text-lg font-bold text-red-900 mb-2">Test Failed</p>
                      <div className="mb-2">
                        <span className="px-2 py-1 text-xs bg-red-600 text-white rounded">
                          {selectedEval.errorType === 'json_parse' ? '⚠️ JSON Parse Error' :
                           selectedEval.errorType === 'api_error' ? '❌ API Error' :
                           selectedEval.errorType === 'timeout' ? '⏱️ Timeout' :
                           '❌ Unknown Error'}
                        </span>
                      </div>
                      <p className="text-sm text-red-800 whitespace-pre-wrap">{selectedEval.error}</p>
                      {selectedEval.errorType === 'json_parse' && (
                        <p className="text-xs text-red-700 mt-2">
                          💡 Tip: The evaluation model wrapped JSON in markdown code blocks. The system now strips these automatically, but this test may have failed before the fix.
                        </p>
                      )}
                      {selectedEval.errorType === 'api_error' && selectedEval.error.includes('data policy') && (
                        <p className="text-xs text-red-700 mt-2">
                          💡 Tip: Free models require explicit data policy configuration. The system now sets data_collection: 'allow' automatically.
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              ) : (
                <div className="flex items-center gap-4">
                  <span className={`text-4xl font-bold ${
                    selectedEval.score >= 85 ? 'text-green-600' :
                    selectedEval.score >= 70 ? 'text-blue-600' :
                    selectedEval.score >= 50 ? 'text-yellow-600' :
                    'text-red-600'
                  }`}>
                    {selectedEval.score}/100
                  </span>
                  <div className="flex-1">
                    <p className="text-sm text-gray-600">Overall Score & Evaluation</p>
                    <p className="text-gray-800">{selectedEval.evaluation}</p>
                  </div>
                </div>
              )}

              {/* Detailed Score Breakdown */}
              {selectedEval.detailedScores && (
                <div className="bg-gradient-to-r from-blue-50 to-purple-50 p-4 rounded-lg">
                  <p className="text-sm font-semibold text-gray-700 mb-3">Score Breakdown</p>

                  {/* Quality Scores */}
                  <div className="space-y-2 mb-4">
                    {selectedEval.detailedScores.translationAccuracy && (
                      <div className="bg-white p-3 rounded-lg border-l-4 border-blue-500">
                        <div className="flex justify-between items-center mb-1">
                          <span className="text-sm font-semibold text-gray-700">Translation Accuracy</span>
                          <span className="text-lg font-bold text-blue-600">
                            {selectedEval.detailedScores.translationAccuracy.score}/85
                          </span>
                        </div>
                        <p className="text-xs text-gray-600">{selectedEval.detailedScores.translationAccuracy.reason}</p>
                      </div>
                    )}
                    {selectedEval.detailedScores.assessmentQuality && (
                      <div className="bg-white p-3 rounded-lg border-l-4 border-green-500">
                        <div className="flex justify-between items-center mb-1">
                          <span className="text-sm font-semibold text-gray-700">Assessment Quality</span>
                          <span className="text-lg font-bold text-green-600">
                            {selectedEval.detailedScores.assessmentQuality.score}/25
                          </span>
                        </div>
                        <p className="text-xs text-gray-600">{selectedEval.detailedScores.assessmentQuality.reason}</p>
                      </div>
                    )}
                    {selectedEval.detailedScores.scoringConsistency && (
                      <div className="bg-white p-3 rounded-lg border-l-4 border-purple-500">
                        <div className="flex justify-between items-center mb-1">
                          <span className="text-sm font-semibold text-gray-700">Scoring Consistency</span>
                          <span className="text-lg font-bold text-purple-600">
                            {selectedEval.detailedScores.scoringConsistency.score}/20
                          </span>
                        </div>
                        <p className="text-xs text-gray-600">{selectedEval.detailedScores.scoringConsistency.reason}</p>
                      </div>
                    )}
                    {selectedEval.detailedScores.feedbackUsefulness && (
                      <div className="bg-white p-3 rounded-lg border-l-4 border-orange-500">
                        <div className="flex justify-between items-center mb-1">
                          <span className="text-sm font-semibold text-gray-700">Feedback Usefulness</span>
                          <span className="text-lg font-bold text-orange-600">
                            {selectedEval.detailedScores.feedbackUsefulness.score}/15
                          </span>
                        </div>
                        <p className="text-xs text-gray-600">{selectedEval.detailedScores.feedbackUsefulness.reason}</p>
                      </div>
                    )}
                    {selectedEval.detailedScores.formatCompliance && (
                      <div className="bg-white p-3 rounded-lg border-l-4 border-indigo-500">
                        <div className="flex justify-between items-center mb-1">
                          <span className="text-sm font-semibold text-gray-700">Format Compliance</span>
                          <span className="text-lg font-bold text-indigo-600">
                            {selectedEval.detailedScores.formatCompliance.score}/10
                          </span>
                        </div>
                        <p className="text-xs text-gray-600">{selectedEval.detailedScores.formatCompliance.reason}</p>
                      </div>
                    )}
                  </div>

                  {/* Quality Total */}
                  {selectedEval.detailedScores.qualityTotal !== undefined && (
                    <div className="bg-white p-4 rounded-lg border-2 border-gray-300 mb-4">
                      <div className="flex justify-between items-center">
                        <span className="text-base font-bold text-gray-800">Quality Total</span>
                        <span className="text-2xl font-bold text-gray-800">
                          {selectedEval.detailedScores.qualityTotal}/100
                        </span>
                      </div>
                    </div>
                  )}

                  {/* Speed Score */}
                  {selectedEval.detailedScores.responseSpeed && (
                    <div className="mb-4">
                      <p className="text-sm font-semibold text-gray-700 mb-2">SPEED SCORE:</p>
                      <div className="bg-white p-3 rounded-lg border-l-4 border-red-500">
                        <div className="flex justify-between items-center mb-1">
                          <span className="text-sm font-semibold text-gray-700">Response Speed</span>
                          <span className="text-lg font-bold text-red-600">
                            {selectedEval.detailedScores.responseSpeed.score}/15
                          </span>
                        </div>
                        <p className="text-xs text-gray-600">{selectedEval.detailedScores.responseSpeed.reason}</p>
                      </div>
                    </div>
                  )}

                  {/* Combined Total */}
                  {selectedEval.detailedScores.combinedTotal !== undefined && (
                    <div className="bg-gradient-to-r from-yellow-100 to-yellow-200 p-4 rounded-lg border-2 border-yellow-500">
                      <div className="flex justify-between items-center">
                        <span className="text-lg font-bold text-gray-900">COMBINED TOTAL</span>
                        <span className="text-3xl font-bold text-yellow-900">
                          {selectedEval.detailedScores.combinedTotal}/100
                        </span>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* Legacy Score Dimensions (for old data) */}
              {!selectedEval.detailedScores && selectedEval.scores && (
                <div className="bg-gradient-to-r from-blue-50 to-purple-50 p-4 rounded-lg">
                  <p className="text-sm font-semibold text-gray-700 mb-3">Score Breakdown (Legacy)</p>
                  <div className="grid grid-cols-3 gap-3">
                    {selectedEval.scores.accuracy !== undefined && (
                      <div className="bg-white p-3 rounded">
                        <p className="text-xs text-gray-600">Accuracy</p>
                        <p className="text-2xl font-bold text-blue-600">{selectedEval.scores.accuracy}</p>
                      </div>
                    )}
                    {selectedEval.scores.fluency !== undefined && (
                      <div className="bg-white p-3 rounded">
                        <p className="text-xs text-gray-600">Fluency</p>
                        <p className="text-2xl font-bold text-green-600">{selectedEval.scores.fluency}</p>
                      </div>
                    )}
                    {selectedEval.scores.grammar !== undefined && (
                      <div className="bg-white p-3 rounded">
                        <p className="text-xs text-gray-600">Grammar</p>
                        <p className="text-2xl font-bold text-purple-600">{selectedEval.scores.grammar}</p>
                      </div>
                    )}
                    {selectedEval.scores.naturalness !== undefined && (
                      <div className="bg-white p-3 rounded">
                        <p className="text-xs text-gray-600">Naturalness</p>
                        <p className="text-2xl font-bold text-orange-600">{selectedEval.scores.naturalness}</p>
                      </div>
                    )}
                    {selectedEval.scores.context !== undefined && (
                      <div className="bg-white p-3 rounded">
                        <p className="text-xs text-gray-600">Context</p>
                        <p className="text-2xl font-bold text-indigo-600">{selectedEval.scores.context}</p>
                      </div>
                    )}
                    {selectedEval.scores.speed !== undefined && (
                      <div className="bg-white p-3 rounded">
                        <p className="text-xs text-gray-600">Speed</p>
                        <p className="text-2xl font-bold text-red-600">{selectedEval.scores.speed}</p>
                      </div>
                    )}
                  </div>
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-sm font-medium text-gray-600 mb-2">Test Parameters</p>
                  <p className="text-sm"><span className="font-medium">Input:</span> "{selectedEval.testInput}"</p>
                  <p className="text-sm"><span className="font-medium">Languages:</span> {selectedEval.sourceLang} → {selectedEval.targetLang}</p>
                  <p className="text-sm"><span className="font-medium">Timestamp:</span> {new Date(selectedEval.timestamp).toLocaleString()}</p>
                  {selectedEval.responseTime !== undefined && (
                    <p className="text-sm"><span className="font-medium">Response Time:</span> {selectedEval.responseTime.toFixed(2)}s</p>
                  )}
                </div>

                <div className="bg-blue-50 p-4 rounded-lg">
                  <p className="text-sm font-medium text-gray-600 mb-2">Evaluation Info</p>
                  <p className="text-sm"><span className="font-medium">Evaluation Model:</span> {selectedEval.evaluationModelName}</p>
                  <p className="text-sm"><span className="font-medium">Category:</span> {selectedEval.category}</p>
                  <p className="text-sm">
                    <span className="font-medium">Baseline:</span>{' '}
                    {selectedEval.baselineType === 'google'
                      ? 'Google Translate'
                      : (selectedEval.baselineModelName || 'Custom Model')}
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-medium text-gray-600 mb-2">AI Model Output</p>
                  <div className="bg-blue-50 p-4 rounded-lg">
                    <p className="text-gray-800">{selectedEval.modelOutput}</p>
                  </div>
                </div>

                <div>
                  <p className="text-sm font-medium text-gray-600 mb-2">Google Translate (Baseline)</p>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <p className="text-gray-800">{selectedEval.googleTranslateOutput}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
