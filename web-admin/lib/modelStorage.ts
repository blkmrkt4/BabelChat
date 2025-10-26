// Local storage for model test results and scores (category-specific)
export type ModelTestResult = {
  modelId: string
  score: number
  testCount: number
  lastTested: string
}

export type CategoryConfig = {
  category: string
  primaryModelId: string
  fallbackModelIds: string[]
  position1?: string  // Primary
  position2?: string  // First fallback
  position3?: string  // Second fallback
  position4?: string  // Third fallback
}

const SCORES_KEY = 'model_scores_v2' // v2 to support category-specific scores
const CONFIGS_KEY = 'category_configs'

// Model Scores (Category-Specific)
export function getModelScores(category: string): Record<string, ModelTestResult> {
  if (typeof window === 'undefined') return {}
  const allScores = localStorage.getItem(SCORES_KEY)
  const scoresByCategory: Record<string, Record<string, ModelTestResult>> = allScores ? JSON.parse(allScores) : {}
  return scoresByCategory[category] || {}
}

export function saveModelScore(modelId: string, category: string, score: number) {
  const allScores = localStorage.getItem(SCORES_KEY)
  const scoresByCategory: Record<string, Record<string, ModelTestResult>> = allScores ? JSON.parse(allScores) : {}

  if (!scoresByCategory[category]) {
    scoresByCategory[category] = {}
  }

  const existing = scoresByCategory[category][modelId]

  scoresByCategory[category][modelId] = {
    modelId,
    score,
    testCount: (existing?.testCount || 0) + 1,
    lastTested: new Date().toISOString(),
  }

  localStorage.setItem(SCORES_KEY, JSON.stringify(scoresByCategory))
}

export function getModelScore(modelId: string, category: string): ModelTestResult | undefined {
  const scores = getModelScores(category)
  return scores[modelId]
}

// Category Configurations (Primary + Fallbacks)
export function getCategoryConfigs(): Record<string, CategoryConfig> {
  if (typeof window === 'undefined') return {}
  const data = localStorage.getItem(CONFIGS_KEY)
  return data ? JSON.parse(data) : {}
}

export function saveCategoryConfig(category: string, primaryModelId: string, fallbackModelIds: string[]) {
  const configs = getCategoryConfigs()
  configs[category] = {
    category,
    primaryModelId,
    fallbackModelIds,
  }
  localStorage.setItem(CONFIGS_KEY, JSON.stringify(configs))
}

export function saveModelToPosition(category: string, modelId: string, position: 1 | 2 | 3 | 4) {
  const configs = getCategoryConfigs()

  if (!configs[category]) {
    configs[category] = {
      category,
      primaryModelId: '',
      fallbackModelIds: [],
    }
  }

  const positionKey = `position${position}` as 'position1' | 'position2' | 'position3' | 'position4'
  configs[category][positionKey] = modelId

  // Update primaryModelId and fallbackModelIds for backwards compatibility
  if (position === 1) {
    configs[category].primaryModelId = modelId
  }

  // Build fallbackModelIds from positions 2-4
  const fallbacks = [
    configs[category].position2,
    configs[category].position3,
    configs[category].position4,
  ].filter(Boolean) as string[]

  configs[category].fallbackModelIds = fallbacks

  localStorage.setItem(CONFIGS_KEY, JSON.stringify(configs))
}

export function getCategoryConfig(category: string): CategoryConfig | undefined {
  const configs = getCategoryConfigs()
  return configs[category]
}
