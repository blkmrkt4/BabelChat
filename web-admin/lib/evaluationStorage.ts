// Storage for model evaluation results
import { supabase } from './supabase'

export type EvaluationResult = {
  id: string
  timestamp: string
  testInput: string
  sourceLang: string
  targetLang: string

  // Baseline info
  baselineType: 'google' | 'model'  // What was used as baseline
  baselineModelId?: string  // If baseline was a model
  baselineModelName?: string  // If baseline was a model
  googleTranslateOutput: string  // Baseline output (rename kept for compatibility)

  // Model being tested
  modelId: string
  modelName: string
  modelOutput: string
  responseTime?: number  // Response time in seconds

  // Evaluation info
  evaluationModelId: string
  evaluationModelName: string
  modelPrompt?: string  // The prompt template used for the model
  evaluationPrompt?: string  // The evaluation prompt used

  // Scores
  score: number  // Overall score (combinedTotal 0-115)
  scores?: {  // Legacy multi-dimensional scores (for backward compatibility)
    accuracy?: number
    fluency?: number
    grammar?: number
    naturalness?: number
    context?: number
    speed?: number
  }
  // New detailed scoring breakdown
  detailedScores?: {
    translationAccuracy?: { score: number, reason: string }
    assessmentQuality?: { score: number, reason: string }
    scoringConsistency?: { score: number, reason: string }
    feedbackUsefulness?: { score: number, reason: string }
    formatCompliance?: { score: number, reason: string }
    qualityTotal?: number
    responseSpeed?: { score: number, reason: string }
    combinedTotal?: number
  }
  evaluation: string  // Detailed evaluation text
  category: string  // translation, grammar, scoring, or custom

  // Error tracking
  error?: string  // Error message if test failed
  errorType?: 'json_parse' | 'api_error' | 'timeout' | 'unknown'  // Type of error
}

const EVALUATIONS_KEY = 'model_evaluations'

// Helper to create language pair string
export function getLanguagePair(sourceLang: string, targetLang: string): string {
  return `${sourceLang}>${targetLang}`
}

// Helper to get all unique language pairs from evaluations
export function getUniqueLanguagePairs(evaluations: EvaluationResult[]): string[] {
  const pairs = new Set(evaluations.map(e => getLanguagePair(e.sourceLang, e.targetLang)))
  return Array.from(pairs).sort()
}

// Helper to convert camelCase to snake_case for Supabase
function toSnakeCase(obj: any): any {
  if (obj === null || typeof obj !== 'object') return obj
  if (Array.isArray(obj)) return obj.map(toSnakeCase)

  return Object.keys(obj).reduce((acc: any, key: string) => {
    const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`)
    acc[snakeKey] = toSnakeCase(obj[key])
    return acc
  }, {})
}

// Helper to convert snake_case to camelCase from Supabase
function toCamelCase(obj: any): any {
  if (obj === null || typeof obj !== 'object') return obj
  if (Array.isArray(obj)) return obj.map(toCamelCase)

  return Object.keys(obj).reduce((acc: any, key: string) => {
    const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase())
    acc[camelKey] = toCamelCase(obj[key])
    return acc
  }, {})
}

export async function getAllEvaluations(): Promise<EvaluationResult[]> {
  try {
    console.log('🔵 Fetching all evaluations from Supabase...')
    const { data, error } = await supabase
      .from('model_evaluations')
      .select('*')
      .order('timestamp', { ascending: false })

    if (error) {
      console.error('🔴 Supabase error:', error)
      throw error
    }

    console.log('🔵 Fetched', data?.length || 0, 'evaluations from Supabase')
    return data ? data.map(toCamelCase) : []
  } catch (error) {
    console.error('🔴 Error fetching evaluations:', error)
    return []
  }
}

export async function saveEvaluation(result: EvaluationResult) {
  console.log('🔵 saveEvaluation called with:', result)

  try {
    // Convert to snake_case for Supabase
    const dbRecord = toSnakeCase(result)

    console.log('🔵 Inserting new evaluation into Supabase...')
    const { data, error } = await supabase
      .from('model_evaluations')
      .insert([dbRecord])
      .select()

    if (error) {
      console.error('🔴 Supabase insert error:', error)
      throw error
    }

    console.log('🔵 Successfully saved to Supabase:', data)

    return data ? toCamelCase(data[0]) : null
  } catch (error) {
    console.error('🔴 Error saving evaluation:', error)
    throw error
  }
}

export async function getEvaluationsByCategory(category: string): Promise<EvaluationResult[]> {
  try {
    console.log('🔵 Fetching evaluations for category:', category)
    const { data, error } = await supabase
      .from('model_evaluations')
      .select('*')
      .eq('category', category)
      .order('timestamp', { ascending: false })

    if (error) {
      console.error('🔴 Supabase error:', error)
      throw error
    }

    console.log('🔵 Found', data?.length || 0, 'evaluations for category', category)
    return data ? data.map(toCamelCase) : []
  } catch (error) {
    console.error('🔴 Error fetching evaluations by category:', error)
    return []
  }
}

export async function getEvaluationsByModel(modelId: string): Promise<EvaluationResult[]> {
  try {
    const { data, error } = await supabase
      .from('model_evaluations')
      .select('*')
      .eq('model_id', modelId)
      .order('timestamp', { ascending: false })

    if (error) throw error
    return data ? data.map(toCamelCase) : []
  } catch (error) {
    console.error('🔴 Error fetching evaluations by model:', error)
    return []
  }
}

export async function deleteModelEvaluations(modelId: string, category: string) {
  try {
    console.log(`🔵 Deleting evaluations for model ${modelId} in category ${category}`)
    const { error } = await supabase
      .from('model_evaluations')
      .delete()
      .eq('model_id', modelId)
      .eq('category', category)

    if (error) throw error
    console.log('🔵 Model evaluations deleted from Supabase')
  } catch (error) {
    console.error('🔴 Error deleting model evaluations:', error)
    throw error
  }
}

export async function clearEvaluations() {
  try {
    const { error } = await supabase
      .from('model_evaluations')
      .delete()
      .neq('id', '') // Delete all rows

    if (error) throw error
    console.log('🔵 All evaluations cleared from Supabase')
  } catch (error) {
    console.error('🔴 Error clearing evaluations:', error)
    throw error
  }
}

// Get average score for a model in a category
export async function getAverageScore(modelId: string, category: string): Promise<number | null> {
  const evals = await getEvaluationsByCategory(category)
  const filtered = evals.filter(e => e.modelId === modelId)

  if (filtered.length === 0) return null

  const sum = filtered.reduce((acc, e) => acc + e.score, 0)
  return sum / filtered.length
}
