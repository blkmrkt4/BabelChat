'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import {
  fetchOpenRouterModels,
  testModel,
  formatCost,
  formatContextLength,
  isTextOnlyModel,
  hasReasoningCost,
  stripMarkdownJson,
  type ModelWithScore
} from '@/lib/openrouter'
import { translateWithGoogle, GOOGLE_LANG_CODES } from '@/lib/googleTranslate'
import { saveEvaluation, getEvaluationsByCategory } from '@/lib/evaluationStorage'
import { getModelScore } from '@/lib/modelStorage'
import {
  getPromptTemplatesByCategory,
  savePromptTemplate,
  deletePromptTemplate,
  type PromptTemplate
} from '@/lib/promptTemplateStorage'
import { createAIConfig, getAIConfigs } from '@/lib/supabase'

const LANGUAGES = Object.keys(GOOGLE_LANG_CODES)

const DEFAULT_CATEGORIES = ['translation', 'grammar', 'scoring'] as const
type DefaultCategory = typeof DEFAULT_CATEGORIES[number]

export default function ModelEvaluation() {
  const [category, setCategory] = useState<string>('translation')
  const [customCategories, setCustomCategories] = useState<string[]>([])
  const [showAddCategory, setShowAddCategory] = useState(false)
  const [newCategoryName, setNewCategoryName] = useState('')
  const [allModels, setAllModels] = useState<ModelWithScore[]>([])
  const [loadingModels, setLoadingModels] = useState(false)

  // Selected models to test
  const [selectedModels, setSelectedModels] = useState<Set<string>>(new Set())

  // Load selected models from localStorage on mount
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const savedModels = localStorage.getItem('selected_models')
      if (savedModels) {
        try {
          const parsed = JSON.parse(savedModels)
          setSelectedModels(new Set(parsed))
        } catch (e) {
          console.error('Error loading selected models:', e)
        }
      }
    }
  }, [])

  // Save selected models when they change
  useEffect(() => {
    if (typeof window !== 'undefined') {
      localStorage.setItem('selected_models', JSON.stringify(Array.from(selectedModels)))
    }
  }, [selectedModels])

  // Evaluation model and fallbacks
  const [evaluationModelId, setEvaluationModelId] = useState('')
  const [evaluationFallback1, setEvaluationFallback1] = useState('')
  const [evaluationFallback2, setEvaluationFallback2] = useState('')

  // Load evaluation models from localStorage on mount
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('evaluation_model_id')
      if (saved) setEvaluationModelId(saved)

      const fallback1 = localStorage.getItem('evaluation_fallback_1')
      if (fallback1) setEvaluationFallback1(fallback1)

      const fallback2 = localStorage.getItem('evaluation_fallback_2')
      if (fallback2) setEvaluationFallback2(fallback2)
    }
  }, [])

  // Save evaluation models when they change
  useEffect(() => {
    if (typeof window !== 'undefined' && evaluationModelId) {
      localStorage.setItem('evaluation_model_id', evaluationModelId)
    }
  }, [evaluationModelId])

  useEffect(() => {
    if (typeof window !== 'undefined') {
      if (evaluationFallback1) {
        localStorage.setItem('evaluation_fallback_1', evaluationFallback1)
      } else {
        localStorage.removeItem('evaluation_fallback_1')
      }
    }
  }, [evaluationFallback1])

  useEffect(() => {
    if (typeof window !== 'undefined') {
      if (evaluationFallback2) {
        localStorage.setItem('evaluation_fallback_2', evaluationFallback2)
      } else {
        localStorage.removeItem('evaluation_fallback_2')
      }
    }
  }, [evaluationFallback2])

  const [evaluationSystemPrompt, setEvaluationSystemPrompt] = useState('')
  const [evaluationPrompt, setEvaluationPrompt] = useState('')

  // Baseline selector and fallbacks (OpenRouter only now)
  const [baselineModelId, setBaselineModelId] = useState('')
  const [baselineFallback1, setBaselineFallback1] = useState('')
  const [baselineFallback2, setBaselineFallback2] = useState('')

  // Load baseline models from localStorage on mount
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('baseline_model_id')
      if (saved) setBaselineModelId(saved)

      const fallback1 = localStorage.getItem('baseline_fallback_1')
      if (fallback1) setBaselineFallback1(fallback1)

      const fallback2 = localStorage.getItem('baseline_fallback_2')
      if (fallback2) setBaselineFallback2(fallback2)
    }
  }, [])

  // Save baseline models when they change
  useEffect(() => {
    if (typeof window !== 'undefined' && baselineModelId) {
      localStorage.setItem('baseline_model_id', baselineModelId)
    }
  }, [baselineModelId])

  useEffect(() => {
    if (typeof window !== 'undefined') {
      if (baselineFallback1) {
        localStorage.setItem('baseline_fallback_1', baselineFallback1)
      } else {
        localStorage.removeItem('baseline_fallback_1')
      }
    }
  }, [baselineFallback1])

  useEffect(() => {
    if (typeof window !== 'undefined') {
      if (baselineFallback2) {
        localStorage.setItem('baseline_fallback_2', baselineFallback2)
      } else {
        localStorage.removeItem('baseline_fallback_2')
      }
    }
  }, [baselineFallback2])

  // Test parameters
  const [testInput, setTestInput] = useState('')
  const [sourceLang, setSourceLang] = useState('English')
  const [targetLang, setTargetLang] = useState('Spanish')
  const [prompt, setPrompt] = useState('')

  // Load source and target languages from localStorage on mount
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const savedSourceLang = localStorage.getItem('source_lang')
      if (savedSourceLang) setSourceLang(savedSourceLang)

      const savedTargetLang = localStorage.getItem('target_lang')
      if (savedTargetLang) setTargetLang(savedTargetLang)
    }
  }, [])

  // Save source language when it changes
  useEffect(() => {
    if (typeof window !== 'undefined' && sourceLang) {
      localStorage.setItem('source_lang', sourceLang)
    }
  }, [sourceLang])

  // Save target language when it changes
  useEffect(() => {
    if (typeof window !== 'undefined' && targetLang) {
      localStorage.setItem('target_lang', targetLang)
    }
  }, [targetLang])

  // API Key
  const [apiKey, setApiKey] = useState('')

  // Testing state
  const [testing, setTesting] = useState(false)
  const [progress, setProgress] = useState('')
  const [results, setResults] = useState<any[]>([])

  // Filters
  const [textOnlyFilter, setTextOnlyFilter] = useState(false)
  const [excludeReasoning, setExcludeReasoning] = useState(false)
  const [excludeFree, setExcludeFree] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [baselineSearchTerm, setBaselineSearchTerm] = useState('')
  const [evaluationSearchTerm, setEvaluationSearchTerm] = useState('')
  const [sortBy, setSortBy] = useState<'name' | 'cost' | 'score'>('name')

  // Template management - now from Supabase
  const [promptTemplates, setPromptTemplates] = useState<PromptTemplate[]>([])
  const [templatesLoading, setTemplatesLoading] = useState(false)
  const [showSaveDialog, setShowSaveDialog] = useState<{ type: 'evaluation' | 'master' | 'testinput', content: string } | null>(null)
  const [newTemplateName, setNewTemplateName] = useState('')
  const [isClient, setIsClient] = useState(false)

  useEffect(() => {
    // Mark that we're now on the client side
    setIsClient(true)
    loadModels()
    loadApiKey()
    loadCustomCategories()
    loadSavedInputs()
    loadPromptTemplates()
    loadCategoryConfig() // Load category-specific config from Supabase
  }, [category])

  const loadPromptTemplates = async () => {
    setTemplatesLoading(true)
    try {
      const templates = await getPromptTemplatesByCategory(category)
      setPromptTemplates(templates)
    } catch (error) {
      console.error('Error loading prompt templates:', error)
    } finally {
      setTemplatesLoading(false)
    }
  }

  const loadSavedInputs = () => {
    if (typeof window !== 'undefined') {
      const savedTestInput = localStorage.getItem('test_input')
      setTestInput(savedTestInput || 'How are you doing today?')

      const savedMasterPrompt = localStorage.getItem('master_prompt')
      setPrompt(savedMasterPrompt || 'You are a professional translator. Translate the following text from {source} to {target}. Provide ONLY the translation, no explanations.')

      const savedEvalSystemPrompt = localStorage.getItem('evaluation_system_prompt')
      setEvaluationSystemPrompt(savedEvalSystemPrompt || 'You are a translation evaluation expert. Always respond in valid JSON format.')

      const savedEvalPrompt = localStorage.getItem('evaluation_prompt')
      setEvaluationPrompt(savedEvalPrompt || `You are an expert translation evaluator. Compare these two translations and score the AI model's translation against the baseline.

IMPORTANT: Provide all evaluation feedback in English, regardless of the languages being translated.

Source Language (Learning Language): {learning_language}
Target Language (Native Language): {native_language}
Original Message: {user_message}
Google Translate Output: {google_translate_output}
Model Being Evaluated: {model_name}
Model's Output: {model_output}
Response Time: {response_time_seconds} seconds

Evaluate the translation quality:
- Translation Accuracy (0-85 points): How accurately the meaning is conveyed

Also provide a speed score based on response time:
- Response Speed (0-15 points): 0-1s = 15, 1-2s = 13, 2-3s = 11, 3-5s = 8, 5-10s = 5, >10s = 2

Respond in EXACTLY this JSON format (all text in English):
{
  "translationAccuracy": {"score": <0-85>, "reason": "<brief reason in English>"},
  "responseSpeed": {"score": <0-15>, "reason": "<brief reason in English based on {response_time_seconds} seconds>"},
  "combinedTotal": <translationAccuracy + responseSpeed, 0-100>,
  "evaluation": "<overall quality assessment in English>"
}`)
    }
  }

  useEffect(() => {
    // Save test input when it changes (only if not empty)
    if (typeof window !== 'undefined' && testInput) {
      localStorage.setItem('test_input', testInput)
    }
  }, [testInput])

  useEffect(() => {
    // Save master prompt when it changes (only if not empty)
    if (typeof window !== 'undefined' && prompt) {
      localStorage.setItem('master_prompt', prompt)
    }
  }, [prompt])

  useEffect(() => {
    // Save evaluation system prompt when it changes (only if not empty)
    if (typeof window !== 'undefined' && evaluationSystemPrompt) {
      localStorage.setItem('evaluation_system_prompt', evaluationSystemPrompt)
    }
  }, [evaluationSystemPrompt])

  useEffect(() => {
    // Save evaluation prompt when it changes (only if not empty)
    if (typeof window !== 'undefined' && evaluationPrompt) {
      localStorage.setItem('evaluation_prompt', evaluationPrompt)
    }
  }, [evaluationPrompt])

  const loadCustomCategories = async () => {
    if (typeof window === 'undefined') return

    try {
      // Load all categories from Supabase
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

  const saveCustomCategories = (categories: string[]) => {
    if (typeof window !== 'undefined') {
      localStorage.setItem('custom_categories', JSON.stringify(categories))
    }
    setCustomCategories(categories)
  }

  const addCustomCategory = async () => {
    const trimmed = newCategoryName.trim().toLowerCase()
    if (!trimmed) {
      alert('Please enter a category name')
      return
    }

    // Check if it already exists (default or custom)
    if ([...DEFAULT_CATEGORIES, ...customCategories].includes(trimmed)) {
      alert('This category already exists')
      return
    }

    try {
      // Create the category in Supabase with default configuration
      await createAIConfig(trimmed, {
        model_id: 'anthropic/claude-3.5-sonnet',
        model_name: 'Claude 3.5 Sonnet',
        model_provider: 'anthropic',
        prompt_template: `You are an AI assistant for ${trimmed}. Provide helpful responses.`,
        temperature: 0.7,
        max_tokens: 1000,
      })

      // After successful Supabase creation, add to localStorage
      const updated = [...customCategories, trimmed]
      saveCustomCategories(updated)
      setNewCategoryName('')
      setShowAddCategory(false)

      alert(`✓ Category "${trimmed}" created successfully! You can now configure it on the main page.`)
    } catch (error) {
      console.error('Error creating category:', error)
      alert('Failed to create category in database. Please try again.')
    }
  }

  const removeCustomCategory = (categoryToRemove: string) => {
    if (confirm(`Are you sure you want to remove the "${categoryToRemove}" category?`)) {
      const updated = customCategories.filter(c => c !== categoryToRemove)
      saveCustomCategories(updated)

      // If we're currently on this category, switch to translation
      if (category === categoryToRemove) {
        setCategory('translation')
      }
    }
  }

  const getAllCategories = () => {
    return [...DEFAULT_CATEGORIES, ...customCategories]
  }

  const loadApiKey = () => {
    const envKey = process.env.NEXT_PUBLIC_OPENROUTER_API_KEY
    if (envKey) {
      setApiKey(envKey)
      return
    }
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('openrouter_api_key')
      if (saved) setApiKey(saved)
    }
  }

  const loadCategoryConfig = async () => {
    try {
      const { getAIConfig } = await import('@/lib/supabase')
      const config = await getAIConfig(category)

      if (config) {
        // Set baseline model from category config
        setBaselineModelId(config.model_id)
        setPrompt(config.prompt_template)

        // Set fallbacks if they exist
        if (config.fallback_model_1_id) {
          setBaselineFallback1(config.fallback_model_1_id)
        }
        if (config.fallback_model_2_id) {
          setBaselineFallback2(config.fallback_model_2_id)
        }

        console.log(`✓ Loaded config for category "${category}":`, {
          model: config.model_name,
          promptLength: config.prompt_template.length
        })
      } else {
        console.log(`No config found for category "${category}"`)
      }
    } catch (error) {
      console.error('Error loading category config:', error)
    }
  }

  const loadModels = async () => {
    setLoadingModels(true)
    try {
      const models = await fetchOpenRouterModels()

      // Fetch evaluations from Supabase to get detailed scores
      const evaluations = await getEvaluationsByCategory(category)

      // Create a map of model ID to its best evaluation
      const modelEvaluations = new Map()
      evaluations.forEach(evaluation => {
        const existing = modelEvaluations.get(evaluation.modelId)
        // Keep the highest scoring evaluation for each model
        if (!existing || evaluation.score > existing.score) {
          modelEvaluations.set(evaluation.modelId, evaluation)
        }
      })

      const modelsWithScores: ModelWithScore[] = models.map(model => {
        const evaluation = modelEvaluations.get(model.id)
        const translationScore = evaluation?.detailedScores?.translationAccuracy?.score
        const speedScore = evaluation?.detailedScores?.responseSpeed?.score

        return {
          ...model,
          userScore: evaluation?.score,
          testCount: evaluations.filter(e => e.modelId === model.id).length,
          translationScore,
          speedScore,
        }
      })
      setAllModels(modelsWithScores)
    } catch (error) {
      console.error('Error loading models:', error)
    } finally {
      setLoadingModels(false)
    }
  }

  const filteredModels = (searchTermOverride?: string) => {
    let filtered = allModels

    if (textOnlyFilter) {
      filtered = filtered.filter(m => isTextOnlyModel(m))
    }

    if (excludeReasoning) {
      filtered = filtered.filter(m => !hasReasoningCost(m))
    }

    if (excludeFree) {
      filtered = filtered.filter(m => {
        const isFree = parseFloat(m.pricing.prompt) === 0 && parseFloat(m.pricing.completion) === 0
        return !isFree
      })
    }

    const searchToUse = searchTermOverride !== undefined ? searchTermOverride : searchTerm
    if (searchToUse.trim()) {
      const search = searchToUse.toLowerCase()
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

  const filteredBaselineModels = () => {
    const filtered = filteredModels(baselineSearchTerm)
    // Always include the selected baseline model even if it doesn't match filters
    if (baselineModelId && !filtered.find(m => m.id === baselineModelId)) {
      const selectedModel = allModels.find(m => m.id === baselineModelId)
      if (selectedModel) {
        return [selectedModel, ...filtered]
      }
    }
    return filtered
  }

  const filteredEvaluationModels = () => {
    const filtered = filteredModels(evaluationSearchTerm)
    // Always include the selected evaluation model even if it doesn't match filters
    if (evaluationModelId && !filtered.find(m => m.id === evaluationModelId)) {
      const selectedModel = allModels.find(m => m.id === evaluationModelId)
      if (selectedModel) {
        return [selectedModel, ...filtered]
      }
    }
    return filtered
  }

  const toggleModelSelection = (modelId: string) => {
    const newSelected = new Set(selectedModels)
    if (newSelected.has(modelId)) {
      newSelected.delete(modelId)
    } else {
      newSelected.add(modelId)
    }
    setSelectedModels(newSelected)
  }

  const handleSaveTemplate = (type: 'evaluation' | 'master' | 'testinput', content: string) => {
    setShowSaveDialog({ type, content })
    setNewTemplateName('')
  }

  const confirmSaveTemplate = async () => {
    if (!newTemplateName.trim()) {
      alert('Please enter a template name')
      return
    }

    if (!showSaveDialog) return

    try {
      // Map template type to appropriate field
      // For now, we store master prompts as system_prompt and test inputs as user_prompt
      const templateData: {
        name: string
        category: 'translation' | 'grammar' | 'scoring' | 'chatting'
        system_prompt?: string | null
        user_prompt?: string | null
        description?: string | null
      } = {
        name: newTemplateName.trim(),
        category: category as 'translation' | 'grammar' | 'scoring' | 'chatting',
        system_prompt: null,
        user_prompt: null,
        description: `Type: ${showSaveDialog.type}`,
      }

      // Store the content based on type
      if (showSaveDialog.type === 'master' || showSaveDialog.type === 'evaluation') {
        templateData.system_prompt = showSaveDialog.content
      } else if (showSaveDialog.type === 'testinput') {
        templateData.user_prompt = showSaveDialog.content
      }

      await savePromptTemplate(templateData)
      await loadPromptTemplates()
      setShowSaveDialog(null)
      setNewTemplateName('')
    } catch (error) {
      console.error('Error saving template:', error)
      alert('Failed to save template. It may already exist with that name.')
    }
  }

  const handleLoadTemplate = (templateId: string, targetField: 'master' | 'evaluation' | 'testinput') => {
    const template = promptTemplates.find(t => t.id === templateId)
    if (!template) return

    // Load from system_prompt for master/evaluation, user_prompt for testinput
    const content = targetField === 'testinput'
      ? (template.user_prompt || template.system_prompt || '')
      : (template.system_prompt || '')

    switch (targetField) {
      case 'evaluation':
        setEvaluationPrompt(content)
        break
      case 'master':
        setPrompt(content)
        break
      case 'testinput':
        setTestInput(content)
        break
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

  // Helper function to try a model with fallbacks
  const testModelWithFallbacks = async (
    primaryModelId: string,
    fallback1: string,
    fallback2: string,
    systemPrompt: string,
    userMessage: string,
    apiKey: string,
    modelType: 'baseline' | 'evaluation'
  ): Promise<{ result: string, usedModelId: string, usedModelName: string }> => {
    const modelsToTry = [
      primaryModelId,
      ...(fallback1 ? [fallback1] : []),
      ...(fallback2 ? [fallback2] : [])
    ].filter(Boolean)

    let lastError: Error | null = null

    for (let i = 0; i < modelsToTry.length; i++) {
      const modelId = modelsToTry[i]
      const modelName = allModels.find(m => m.id === modelId)?.name || modelId
      const isFallback = i > 0

      try {
        console.log(`🔄 ${modelType} - Trying ${isFallback ? `fallback ${i}` : 'primary'}: ${modelName}`)
        const result = await testModel(modelId, systemPrompt, userMessage, apiKey)

        if (isFallback) {
          console.log(`✅ ${modelType} - Fallback ${i} succeeded: ${modelName}`)
          setProgress(prev => prev + `\n⚠️ ${modelType} fallback ${i} used: ${modelName}`)
        }

        return { result, usedModelId: modelId, usedModelName: modelName }
      } catch (error: any) {
        lastError = error
        console.log(`❌ ${modelType} - ${isFallback ? `Fallback ${i}` : 'Primary'} failed: ${error.message}`)

        // If this is not the last model to try, continue to next
        if (i < modelsToTry.length - 1) {
          console.log(`🔄 ${modelType} - Trying next fallback...`)
          continue
        }
      }
    }

    // If we get here, all models failed
    throw new Error(`All ${modelType} models failed. Last error: ${lastError?.message || 'Unknown error'}`)
  }

  const runEvaluations = async () => {
    console.log('🚀 Starting evaluations...')
    console.log('📊 Selected models:', Array.from(selectedModels))
    console.log('📁 Category:', category)

    if (selectedModels.size === 0) {
      alert('Please select at least one model to test')
      return
    }

    if (!evaluationModelId) {
      alert('Please select an evaluation model')
      return
    }

    if (!baselineModelId) {
      alert('Please select a baseline model')
      return
    }

    if (!apiKey) {
      alert('Please enter your OpenRouter API key')
      return
    }

    setTesting(true)
    setResults([])

    try {
      // Step 1: Get baseline result from selected model (with fallbacks)
      setProgress('Getting baseline model result...')

      const processedPrompt = prompt
        .replace(/\{source\}/g, sourceLang)
        .replace(/\{target\}/g, targetLang)
        .replace(/\{learning_language\}/g, sourceLang)
        .replace(/\{native_language\}/g, targetLang)

      const { result: baselineResult, usedModelId: actualBaselineId, usedModelName: baselineLabel } = await testModelWithFallbacks(
        baselineModelId,
        baselineFallback1,
        baselineFallback2,
        processedPrompt,
        testInput,
        apiKey,
        'baseline'
      )

      setProgress(`Baseline (${baselineLabel}): "${baselineResult}"\n\nTesting ${selectedModels.size} models...`)

      // Step 2: Test each selected model
      const testResults: any[] = []
      let count = 0

      for (const modelId of selectedModels) {
        count++
        const model = allModels.find(m => m.id === modelId)

        // If model not found, create an error result
        if (!model) {
          console.error(`Model not found: ${modelId}`)
          setProgress(prev => prev + `\n❌ Model not found: ${modelId}`)

          const errorResult = {
            id: `${Date.now()}_${modelId}_notfound`,
            timestamp: new Date().toISOString(),
            testInput,
            sourceLang,
            targetLang,
            baselineType: 'model' as const,
            baselineModelId: actualBaselineId,
            baselineModelName: baselineLabel,
            googleTranslateOutput: baselineResult,
            modelId: modelId,
            modelName: modelId,
            modelOutput: 'ERROR',
            responseTime: 0,
            evaluationModelId,
            evaluationModelName: allModels.find(m => m.id === evaluationModelId)?.name || evaluationModelId,
            modelPrompt: processedPrompt,
            evaluationPrompt: '',
            score: 0,
            evaluation: 'Model not found in available models list',
            category,
            error: 'Model not found in available models list',
            errorType: 'unknown' as const,
          }

          testResults.push(errorResult)
          try {
            await saveEvaluation(errorResult)
          } catch (e) {
            console.error('Error saving not-found result:', e)
          }
          continue
        }

        setProgress(`Testing ${count}/${selectedModels.size}: ${model.name}...`)

        try {
          // Get model's translation and track response time
          const startTime = Date.now()
          const modelResult = await testModel(modelId, processedPrompt, testInput, apiKey)
          const endTime = Date.now()
          const responseTimeSeconds = ((endTime - startTime) / 1000).toFixed(2)

          // Prepare evaluation prompt with variable substitution
          const processedEvalPrompt = evaluationPrompt
            .replace(/\{user_message\}/g, testInput)
            .replace(/\{learning_language\}/g, sourceLang)
            .replace(/\{native_language\}/g, targetLang)
            .replace(/\{google_translate_output\}/g, baselineResult)
            .replace(/\{model_name\}/g, model.name)
            .replace(/\{model_output\}/g, modelResult)
            .replace(/\{response_time_seconds\}/g, responseTimeSeconds)

          // Use evaluation model to compare against baseline (with fallbacks)
          const { result: evaluationResponse, usedModelId: actualEvaluationId, usedModelName: actualEvaluationName } = await testModelWithFallbacks(
            evaluationModelId,
            evaluationFallback1,
            evaluationFallback2,
            evaluationSystemPrompt,
            processedEvalPrompt,
            apiKey,
            'evaluation'
          )

          // Parse evaluation - strip markdown code blocks first
          const cleanedResponse = stripMarkdownJson(evaluationResponse)
          console.log('🔵 Original response:', evaluationResponse.substring(0, 300))
          console.log('🔵 Cleaned response:', cleanedResponse.substring(0, 300))
          let evalData
          try {
            evalData = JSON.parse(cleanedResponse)
          } catch (parseError: any) {
            console.error('🔴 JSON Parse Error')
            console.error('🔴 Original response:', evaluationResponse)
            console.error('🔴 Cleaned response:', cleanedResponse)
            throw new Error(`JSON Parse Error: ${parseError.message}. Original response: ${evaluationResponse.substring(0, 200)}. Cleaned response: ${cleanedResponse.substring(0, 200)}`)
          }

          const result = {
            id: `${Date.now()}_${modelId}`,
            timestamp: new Date().toISOString(),
            testInput,
            sourceLang,
            targetLang,

            // Baseline info (actual model used after fallbacks)
            baselineType: 'model' as const,
            baselineModelId: actualBaselineId,
            baselineModelName: baselineLabel,
            googleTranslateOutput: baselineResult,

            // Model being tested
            modelId: model.id,
            modelName: model.name,
            modelOutput: modelResult,
            responseTime: parseFloat(responseTimeSeconds),

            // Evaluation info (actual model used after fallbacks)
            evaluationModelId: actualEvaluationId,
            evaluationModelName: actualEvaluationName,
            modelPrompt: processedPrompt,
            evaluationPrompt: processedEvalPrompt,

            // Scores - use combinedTotal as the main score, fallback to old score field
            score: evalData.combinedTotal || evalData.score || 0,
            // Legacy scores for backward compatibility
            scores: evalData.scores || undefined,
            // New detailed scores
            detailedScores: {
              translationAccuracy: evalData.translationAccuracy,
              assessmentQuality: evalData.assessmentQuality,
              scoringConsistency: evalData.scoringConsistency,
              feedbackUsefulness: evalData.feedbackUsefulness,
              formatCompliance: evalData.formatCompliance,
              qualityTotal: evalData.qualityTotal,
              responseSpeed: evalData.responseSpeed,
              combinedTotal: evalData.combinedTotal
            },
            evaluation: evalData.evaluation,
            category,
          }

          console.log('✅ Test successful, about to save result:', result)
          testResults.push(result)
          console.log('📝 Calling saveEvaluation...')
          await saveEvaluation(result)
          console.log('✅ saveEvaluation completed')

          // Update progress to show success
          setProgress(prev => prev + `\n✅ ${model.name}: ${result.score.toFixed(1)}/100`)

        } catch (error: any) {
          console.error(`Error testing ${model.name}:`, error)

          // Update progress to show the error
          setProgress(prev => prev + `\n❌ ${model.name}: ${error.message || 'Unknown error'}`)

          // Determine error type and extract full response if available
          let errorType: 'json_parse' | 'api_error' | 'timeout' | 'unknown' = 'unknown'
          let errorMessage = error.message || 'Unknown error'
          let fullResponse = ''

          // Try to extract the actual response from the error message
          if (errorMessage.includes('Original response:')) {
            const responseMatch = errorMessage.match(/Original response: (.+?)(?:\. Cleaned response:|$)/)
            if (responseMatch) {
              fullResponse = responseMatch[1]
            }
          }

          if (errorMessage.includes('JSON Parse Error')) {
            errorType = 'json_parse'
          } else if (errorMessage.includes('[429]') || errorMessage.includes('rate-limited') || errorMessage.includes('rate limit')) {
            errorType = 'api_error'
            // Make rate limit errors more clear
            if (!errorMessage.includes('rate-limited')) {
              errorMessage = `Rate limited: ${errorMessage}`
            }
          } else if (errorMessage.includes('API Error') || errorMessage.includes('require explicit data policy') || errorMessage.includes('[') && errorMessage.includes(']')) {
            errorType = 'api_error'
          } else if (errorMessage.includes('timeout') || errorMessage.includes('timed out')) {
            errorType = 'timeout'
          }

          // If we have a full response, include it in the error message
          if (fullResponse) {
            errorMessage = `${errorMessage}\n\nFull Response:\n${fullResponse}`
          }

          // Save failed test result
          const errorResult = {
            id: `${Date.now()}_${model.id}_error`,
            timestamp: new Date().toISOString(),
            testInput,
            sourceLang,
            targetLang,

            // Baseline info (actual model used after fallbacks)
            baselineType: 'model' as const,
            baselineModelId: actualBaselineId,
            baselineModelName: baselineLabel,
            googleTranslateOutput: baselineResult,

            // Model being tested
            modelId: model.id,
            modelName: model.name,
            modelOutput: 'ERROR',
            responseTime: 0,

            // Evaluation info (use primary since evaluation might not have been attempted)
            evaluationModelId,
            evaluationModelName: allModels.find(m => m.id === evaluationModelId)?.name || evaluationModelId,
            modelPrompt: processedPrompt,
            evaluationPrompt: '',

            // Error info
            score: 0,
            evaluation: `Test failed: ${errorMessage}`,
            category,
            error: errorMessage,
            errorType,
          }

          console.log('❌ Test failed, about to save error result:', errorResult)
          testResults.push(errorResult)
          console.log('📝 Calling saveEvaluation for error...')
          await saveEvaluation(errorResult)
          console.log('✅ Error result saved')
        }
      }

      console.log('🏁 All tests complete. Total results:', testResults.length)
      setResults(testResults)

      // Count successful vs failed tests
      const successCount = testResults.filter(r => !r.error).length
      const failCount = testResults.filter(r => r.error).length

      setProgress(prev => prev + `\n\n🏁 Complete! ${successCount} successful, ${failCount} failed out of ${testResults.length} total.`)

    } catch (error: any) {
      console.error('🔴 Critical error in runEvaluations:', error)
      setProgress(`Error: ${error.message}`)
    } finally {
      setTesting(false)
      console.log('✅ Testing phase complete')
    }
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <h1 className="text-3xl font-bold">Model/Prompt Testing</h1>

      {/* Category Selector */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold">Evaluation Category</h2>
          <button
            onClick={() => setShowAddCategory(!showAddCategory)}
            className="px-4 py-2 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700"
          >
            + Add Category
          </button>
        </div>

        {showAddCategory && (
          <div className="flex gap-2 p-4 bg-gray-50 rounded-lg border">
            <input
              type="text"
              value={newCategoryName}
              onChange={(e) => setNewCategoryName(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && addCustomCategory()}
              placeholder="Enter category name..."
              className="flex-1 px-3 py-2 border rounded-lg"
            />
            <button
              onClick={addCustomCategory}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Add
            </button>
            <button
              onClick={() => {
                setShowAddCategory(false)
                setNewCategoryName('')
              }}
              className="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400"
            >
              Cancel
            </button>
          </div>
        )}

        <div className="flex flex-wrap gap-2">
          {getAllCategories().map((cat) => {
            const isCustom = !DEFAULT_CATEGORIES.includes(cat as any)
            return (
              <div key={cat} className="relative group">
                <button
                  onClick={() => setCategory(cat)}
                  className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                    category === cat
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                  }`}
                >
                  {cat.charAt(0).toUpperCase() + cat.slice(1)}
                </button>
                {isCustom && (
                  <button
                    onClick={() => removeCustomCategory(cat)}
                    className="absolute -top-2 -right-2 w-5 h-5 bg-red-500 text-white rounded-full text-xs opacity-0 group-hover:opacity-100 transition-opacity"
                    title="Remove category"
                  >
                    ×
                  </button>
                )}
              </div>
            )
          })}
        </div>
      </div>

      {/* Prompt to Test */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <h2 className="text-xl font-semibold">Prompt to Test</h2>
        <p className="text-sm text-gray-600">This is the prompt you are using to test the &apos;Models to Test&apos; below, evaluated against a good known model &apos;Gold Standard&apos; by an &apos;Evaluation Model&apos; also selected below which is prompted to be a good evaluator.</p>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-2">Source Language</label>
            <select
              value={sourceLang}
              onChange={(e) => setSourceLang(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg"
            >
              {LANGUAGES.map(lang => (
                <option key={lang} value={lang}>{lang}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Target Language</label>
            <select
              value={targetLang}
              onChange={(e) => setTargetLang(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg"
            >
              {LANGUAGES.map(lang => (
                <option key={lang} value={lang}>{lang}</option>
              ))}
            </select>
          </div>
        </div>

        <div>
          <div className="flex items-center justify-between mb-2">
            <label className="block text-sm font-medium">Master Prompt (for Models Being Tested)</label>
            <div className="flex gap-2">
              <select
                onChange={(e) => {
                  if (e.target.value) {
                    handleLoadTemplate(e.target.value, 'master')
                    e.target.value = ''
                  }
                }}
                className="px-3 py-1 text-sm border rounded-lg"
                defaultValue=""
                disabled={templatesLoading}
              >
                <option value="">{templatesLoading ? 'Loading...' : '📂 Load Template...'}</option>
                {promptTemplates.map(template => (
                  <option key={template.id} value={template.id}>
                    {template.name}
                  </option>
                ))}
              </select>
              <button
                onClick={() => handleSaveTemplate('master', prompt)}
                className="px-3 py-1 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                💾 Save
              </button>
            </div>
          </div>
          <p className="text-xs text-gray-500 mb-2">
            This prompt is sent as the system prompt to each model being tested (the translation models). Variables: {'{source}'}, {'{target}'}
          </p>
          <textarea
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            className="w-full h-24 px-3 py-2 border rounded-lg font-mono text-sm"
            placeholder="Use {source} and {target} as placeholders"
          />
          {promptTemplates.length > 0 && (
            <div className="mt-2 flex flex-wrap gap-2">
              <span className="text-xs text-gray-500">Saved templates:</span>
              {promptTemplates.map(template => (
                <div key={template.id} className="flex items-center gap-1 bg-gray-100 px-2 py-1 rounded text-xs">
                  <button
                    onClick={() => handleLoadTemplate(template.id, 'master')}
                    className="hover:text-blue-600"
                  >
                    {template.name}
                  </button>
                  <button
                    onClick={() => handleDeleteTemplate(template.id)}
                    className="text-red-600 hover:text-red-700 ml-1"
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        <div>
          <div className="flex items-center justify-between mb-2">
            <label className="block text-sm font-medium">Test Input</label>
            <div className="flex gap-2">
              <select
                onChange={(e) => {
                  if (e.target.value) {
                    handleLoadTemplate(e.target.value, 'testinput')
                    e.target.value = ''
                  }
                }}
                className="px-3 py-1 text-sm border rounded-lg"
                defaultValue=""
                disabled={templatesLoading}
              >
                <option value="">{templatesLoading ? 'Loading...' : '📂 Load Template...'}</option>
                {promptTemplates.map(template => (
                  <option key={template.id} value={template.id}>
                    {template.name}
                  </option>
                ))}
              </select>
              <button
                onClick={() => handleSaveTemplate('testinput', testInput)}
                className="px-3 py-1 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                💾 Save
              </button>
            </div>
          </div>
          <textarea
            value={testInput}
            onChange={(e) => setTestInput(e.target.value)}
            className="w-full h-24 px-3 py-2 border rounded-lg"
          />
          {promptTemplates.length > 0 && (
            <div className="mt-2 flex flex-wrap gap-2">
              <span className="text-xs text-gray-500">Saved templates:</span>
              {promptTemplates.map(template => (
                <div key={template.id} className="flex items-center gap-1 bg-gray-100 px-2 py-1 rounded text-xs">
                  <button
                    onClick={() => handleLoadTemplate(template.id, 'testinput')}
                    className="hover:text-blue-600"
                  >
                    {template.name}
                  </button>
                  <button
                    onClick={() => handleDeleteTemplate(template.id)}
                    className="text-red-600 hover:text-red-700 ml-1"
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Baseline Selection */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <h2 className="text-xl font-semibold">Gold Standard Model</h2>
        <p className="text-sm text-gray-600">
          Select the OpenRouter model to use as the baseline for comparison
        </p>

        {/* Show currently selected baseline */}
        {baselineModelId && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
            <p className="text-sm font-semibold text-blue-900">Currently Selected:</p>
            <p className="text-sm text-blue-700">
              {allModels.find(m => m.id === baselineModelId)?.name || baselineModelId}
            </p>
          </div>
        )}

            {/* Search Bar */}
            <input
              type="text"
              placeholder="🔍 Search baseline models..."
              value={baselineSearchTerm}
              onChange={(e) => setBaselineSearchTerm(e.target.value)}
              className="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none"
            />

            {/* Filters */}
            <div className="flex items-center gap-4 p-3 bg-blue-50 rounded-lg border border-blue-200 flex-wrap">
              <label className="font-medium text-sm">Filters:</label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={textOnlyFilter}
                  onChange={(e) => setTextOnlyFilter(e.target.checked)}
                  className="w-4 h-4"
                />
                <span className="text-sm">Text-only</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={excludeReasoning}
                  onChange={(e) => setExcludeReasoning(e.target.checked)}
                  className="w-4 h-4"
                />
                <span className="text-sm">Exclude reasoning</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={excludeFree}
                  onChange={(e) => setExcludeFree(e.target.checked)}
                  className="w-4 h-4"
                />
                <span className="text-sm">Exclude free</span>
              </label>
            </div>

            {/* Sort Options */}
            <div className="flex items-center gap-2 flex-wrap">
              <label className="font-medium text-sm">Sort by:</label>
              {(['name', 'cost'] as const).map((sort) => (
                <button
                  key={sort}
                  onClick={() => setSortBy(sort)}
                  className={`px-3 py-1 text-sm rounded-lg border-2 transition-colors ${
                    sortBy === sort
                      ? 'bg-blue-100 border-blue-600 text-blue-700'
                      : 'border-gray-300 hover:border-gray-400'
                  }`}
                >
                  {sort.charAt(0).toUpperCase() + sort.slice(1)}
                </button>
              ))}
              <button
                onClick={loadModels}
                disabled={loadingModels}
                className="ml-auto px-3 py-1 text-sm bg-gray-200 rounded-lg hover:bg-gray-300 disabled:bg-gray-100"
              >
                {loadingModels ? 'Loading...' : '🔄 Refresh'}
              </button>
              <span className="text-xs text-gray-600">
                {filteredBaselineModels().length} models
              </span>
            </div>

            {/* Model Dropdown */}
            <div className="space-y-2">
              <label className="block text-sm font-medium">Primary Baseline Model</label>
              <select
                value={baselineModelId}
                onChange={(e) => setBaselineModelId(e.target.value)}
                className="w-full px-3 py-2 border-2 rounded-lg focus:border-blue-500 focus:outline-none"
              >
                <option value="">Select baseline model...</option>
                {filteredBaselineModels().map(model => (
                  <option key={model.id} value={model.id}>
                    {model.name} - Input: {formatCost(model.pricing.prompt)}/1K, Output: {formatCost(model.pricing.completion)}/1K
                  </option>
                ))}
              </select>
            </div>

            {/* Fallback Models */}
            <div className="border-t pt-4 space-y-3">
              <p className="text-sm font-medium text-gray-700">Fallback Models (for resiliency)</p>
              <p className="text-xs text-gray-500">If primary model fails, these will be tried in order</p>

              <div className="space-y-2">
                <label className="block text-xs font-medium text-gray-600">Fallback 1</label>
                <select
                  value={baselineFallback1}
                  onChange={(e) => setBaselineFallback1(e.target.value)}
                  className="w-full px-3 py-2 border rounded-lg focus:border-blue-500 focus:outline-none text-sm"
                >
                  <option value="">No fallback</option>
                  {filteredBaselineModels().map(model => (
                    <option key={model.id} value={model.id}>
                      {model.name} - Input: {formatCost(model.pricing.prompt)}/1K
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-2">
                <label className="block text-xs font-medium text-gray-600">Fallback 2</label>
                <select
                  value={baselineFallback2}
                  onChange={(e) => setBaselineFallback2(e.target.value)}
                  className="w-full px-3 py-2 border rounded-lg focus:border-blue-500 focus:outline-none text-sm"
                >
                  <option value="">No fallback</option>
                  {filteredBaselineModels().map(model => (
                    <option key={model.id} value={model.id}>
                      {model.name} - Input: {formatCost(model.pricing.prompt)}/1K
                    </option>
                  ))}
                </select>
              </div>
            </div>
      </div>

      {/* Evaluation Model & Prompts */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <h2 className="text-xl font-semibold">Evaluation Model & Prompts</h2>
        <p className="text-sm text-gray-600">
          This model will judge and score each model's output against the baseline
        </p>

        {/* Show currently selected evaluation model */}
        {evaluationModelId && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-3">
            <p className="text-sm font-semibold text-green-900">Currently Selected:</p>
            <p className="text-sm text-green-700">
              {allModels.find(m => m.id === evaluationModelId)?.name || evaluationModelId}
            </p>
          </div>
        )}

        {/* Search Bar */}
        <input
          type="text"
          placeholder="🔍 Search evaluation models..."
          value={evaluationSearchTerm}
          onChange={(e) => setEvaluationSearchTerm(e.target.value)}
          className="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none"
        />

        {/* Filters */}
        <div className="flex items-center gap-4 p-3 bg-blue-50 rounded-lg border border-blue-200 flex-wrap">
          <label className="font-medium text-sm">Filters:</label>
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={textOnlyFilter}
              onChange={(e) => setTextOnlyFilter(e.target.checked)}
              className="w-4 h-4"
            />
            <span className="text-sm">Text-only</span>
          </label>
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={excludeReasoning}
              onChange={(e) => setExcludeReasoning(e.target.checked)}
              className="w-4 h-4"
            />
            <span className="text-sm">Exclude reasoning</span>
          </label>
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={excludeFree}
              onChange={(e) => setExcludeFree(e.target.checked)}
              className="w-4 h-4"
            />
            <span className="text-sm">Exclude free</span>
          </label>
        </div>

        {/* Sort Options */}
        <div className="flex items-center gap-2 flex-wrap">
          <label className="font-medium text-sm">Sort by:</label>
          {(['name', 'cost'] as const).map((sort) => (
            <button
              key={sort}
              onClick={() => setSortBy(sort)}
              className={`px-3 py-1 text-sm rounded-lg border-2 transition-colors ${
                sortBy === sort
                  ? 'bg-blue-100 border-blue-600 text-blue-700'
                  : 'border-gray-300 hover:border-gray-400'
              }`}
            >
              {sort.charAt(0).toUpperCase() + sort.slice(1)}
            </button>
          ))}
          <button
            onClick={loadModels}
            disabled={loadingModels}
            className="ml-auto px-3 py-1 text-sm bg-gray-200 rounded-lg hover:bg-gray-300 disabled:bg-gray-100"
          >
            {loadingModels ? 'Loading...' : '🔄 Refresh'}
          </button>
          <span className="text-xs text-gray-600">
            {filteredEvaluationModels().length} models
          </span>
        </div>

        {/* Model Dropdown */}
        <div className="space-y-2">
          <label className="block text-sm font-medium">Primary Evaluation Model</label>
          <select
            value={evaluationModelId}
            onChange={(e) => setEvaluationModelId(e.target.value)}
            className="w-full px-3 py-2 border-2 rounded-lg focus:border-blue-500 focus:outline-none"
          >
            <option value="">Select evaluation model...</option>
            {filteredEvaluationModels().map(model => (
              <option key={model.id} value={model.id}>
                {model.name} - Input: {formatCost(model.pricing.prompt)}/1K, Output: {formatCost(model.pricing.completion)}/1K
              </option>
            ))}
          </select>
        </div>

        {/* Fallback Models */}
        <div className="border-t pt-4 space-y-3">
          <p className="text-sm font-medium text-gray-700">Fallback Models (for resiliency)</p>
          <p className="text-xs text-gray-500">If primary model fails, these will be tried in order</p>

          <div className="space-y-2">
            <label className="block text-xs font-medium text-gray-600">Fallback 1</label>
            <select
              value={evaluationFallback1}
              onChange={(e) => setEvaluationFallback1(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg focus:border-blue-500 focus:outline-none text-sm"
            >
              <option value="">No fallback</option>
              {filteredEvaluationModels().map(model => (
                <option key={model.id} value={model.id}>
                  {model.name} - Input: {formatCost(model.pricing.prompt)}/1K
                </option>
              ))}
            </select>
          </div>

          <div className="space-y-2">
            <label className="block text-xs font-medium text-gray-600">Fallback 2</label>
            <select
              value={evaluationFallback2}
              onChange={(e) => setEvaluationFallback2(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg focus:border-blue-500 focus:outline-none text-sm"
            >
              <option value="">No fallback</option>
              {filteredEvaluationModels().map(model => (
                <option key={model.id} value={model.id}>
                  {model.name} - Input: {formatCost(model.pricing.prompt)}/1K
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Evaluation Prompts */}
        <div className="border-t pt-4">
          <h3 className="text-lg font-semibold mb-4">Prompts</h3>
        </div>

        {/* Evaluation System Prompt */}
        <div>
          <label className="block text-sm font-medium mb-2">System Prompt (for Evaluation Model)</label>
          <p className="text-xs text-gray-500 mb-2">
            This is the system prompt sent to the evaluation model. You control what it says here.
          </p>
          <textarea
            value={evaluationSystemPrompt}
            onChange={(e) => setEvaluationSystemPrompt(e.target.value)}
            className="w-full h-20 px-3 py-2 border rounded-lg font-mono text-sm"
            placeholder="System instructions for the evaluation model..."
          />
        </div>

        {/* Evaluation User Prompt */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <label className="block text-sm font-medium">User Prompt (for Evaluation Model)</label>
            <div className="flex gap-2">
            <select
              onChange={(e) => {
                if (e.target.value) {
                  handleLoadTemplate(e.target.value, 'evaluation')
                  e.target.value = ''
                }
              }}
              className="px-3 py-1 text-sm border rounded-lg"
              defaultValue=""
              disabled={templatesLoading}
            >
              <option value="">{templatesLoading ? 'Loading...' : '📂 Load Template...'}</option>
              {promptTemplates.map(template => (
                <option key={template.id} value={template.id}>
                  {template.name}
                </option>
              ))}
            </select>
            <button
              onClick={() => handleSaveTemplate('evaluation', evaluationPrompt)}
              className="px-3 py-1 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              💾 Save
            </button>
            </div>
          </div>
          <p className="text-sm text-gray-600 mb-2">
          The prompt given to the evaluation model. Available variables:
        </p>
        <div className="bg-blue-50 p-3 rounded text-xs font-mono mb-3">
          <span className="font-semibold">{'{learning_language}'}</span> - Source language, <span className="font-semibold">{'{native_language}'}</span> - Target language, <span className="font-semibold">{'{user_message}'}</span> - Original test input, <span className="font-semibold">{'{google_translate_output}'}</span> - Baseline output, <span className="font-semibold">{'{model_name}'}</span> - Name of model being evaluated, <span className="font-semibold">{'{model_output}'}</span> - Model&apos;s response, <span className="font-semibold">{'{response_time_seconds}'}</span> - Response time in seconds
        </div>
        <textarea
          value={evaluationPrompt}
          onChange={(e) => setEvaluationPrompt(e.target.value)}
          className="w-full h-64 px-3 py-2 border rounded-lg font-mono text-sm"
          placeholder="Enter the evaluation prompt..."
        />
        {promptTemplates.length > 0 && (
          <div className="mt-2 flex flex-wrap gap-2">
            <span className="text-xs text-gray-500">Saved templates:</span>
            {promptTemplates.map(template => (
              <div key={template.id} className="flex items-center gap-1 bg-gray-100 px-2 py-1 rounded text-xs">
                <button
                  onClick={() => handleLoadTemplate(template.id, 'evaluation')}
                  className="hover:text-blue-600"
                >
                  {template.name}
                </button>
                <button
                  onClick={() => handleDeleteTemplate(template.id)}
                  className="text-red-600 hover:text-red-700 ml-1"
                >
                  ×
                </button>
              </div>
            ))}
          </div>
        )}
        </div>
      </div>

      {/* Model Selection */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold">Select Models to Test ({selectedModels.size} selected)</h2>
          <button
            onClick={() => setSelectedModels(new Set())}
            className="px-4 py-2 bg-gray-200 rounded-lg hover:bg-gray-300"
          >
            Clear Selection
          </button>
        </div>

        {/* Search Bar */}
        <input
          type="text"
          placeholder="🔍 Search models by name or ID..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none"
        />

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
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={excludeFree}
              onChange={(e) => setExcludeFree(e.target.checked)}
              className="w-4 h-4"
            />
            <span className="text-sm">Exclude free models</span>
          </label>
          <span className="ml-auto text-sm text-gray-600">
            Showing {filteredModels().length} of {allModels.length} models
          </span>
        </div>

        {/* Sort Options */}
        <div className="flex items-center gap-4">
          <label className="font-medium">Sort by:</label>
          <div className="flex gap-2">
            {(['name', 'cost', 'score'] as const).map((sort) => (
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

        {/* Model List */}
        <div className="max-h-96 overflow-y-auto border rounded-lg">
          {filteredModels().map(model => (
            <div
              key={model.id}
              onClick={() => toggleModelSelection(model.id)}
              className={`p-4 border-b cursor-pointer hover:bg-blue-50 ${
                selectedModels.has(model.id) ? 'bg-blue-100' : ''
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    checked={selectedModels.has(model.id)}
                    onChange={() => {}}
                    className="w-5 h-5"
                  />
                  <div>
                    <p className="font-medium">{model.name}</p>
                    <p className="text-xs text-gray-500">{model.id}</p>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  {model.userScore !== undefined && (
                    <div className="text-right">
                      {model.translationScore !== undefined && model.speedScore !== undefined ? (
                        <p className="text-sm font-medium text-gray-700">
                          Translate({model.translationScore.toFixed(0)}) + Speed({model.speedScore.toFixed(0)}) = <span className={`font-semibold ${
                            model.userScore >= 85 ? 'text-green-600' :
                            model.userScore >= 70 ? 'text-blue-600' :
                            model.userScore >= 50 ? 'text-yellow-600' : 'text-red-600'
                          }`}>{model.userScore.toFixed(0)}</span>
                        </p>
                      ) : (
                        <>
                          <p className={`text-lg font-bold ${
                            model.userScore >= 85 ? 'text-green-600' :
                            model.userScore >= 70 ? 'text-blue-600' :
                            model.userScore >= 50 ? 'text-yellow-600' : 'text-red-600'
                          }`}>
                            {model.userScore.toFixed(1)}
                          </p>
                          <p className="text-xs text-gray-500">
                            {model.testCount} {model.testCount === 1 ? 'test' : 'tests'}
                          </p>
                        </>
                      )}
                    </div>
                  )}
                  <div className="text-sm text-gray-600">
                    {formatCost(model.pricing.prompt)}/1K in • {formatCost(model.pricing.completion)}/1K out
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Run Evaluation */}
      <div className="bg-white rounded-lg shadow p-6 space-y-4">
        <button
          onClick={runEvaluations}
          disabled={testing || selectedModels.size === 0 || !evaluationModelId}
          className="w-full bg-green-600 text-white py-4 rounded-lg font-bold text-lg hover:bg-green-700 disabled:bg-gray-400"
        >
          {testing ? 'Running Evaluations...' : `Run Evaluation (${selectedModels.size} models)`}
        </button>

        {progress && (
          <div className="bg-gray-50 border rounded-lg p-4">
            <pre className="whitespace-pre-wrap text-sm">{progress}</pre>
          </div>
        )}
      </div>

      {/* Results */}
      {results.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6 space-y-4">
          <h2 className="text-xl font-semibold">Results</h2>
          <div className="space-y-4">
            {results.map((result, idx) => (
              <div key={idx} className="border rounded-lg p-4">
                {result.error ? (
                  <div>
                    <p className="font-medium text-red-600">{result.modelName}</p>
                    <p className="text-sm text-red-500">Error: {result.error}</p>
                  </div>
                ) : (
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <p className="font-medium">{result.modelName}</p>
                      <span className={`text-2xl font-bold ${
                        result.score >= 75 ? 'text-green-600' :
                        result.score >= 50 ? 'text-yellow-600' : 'text-red-600'
                      }`}>
                        {result.score}/100
                      </span>
                    </div>
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <p className="font-medium text-gray-600">Model Output:</p>
                        <p className="bg-blue-50 p-2 rounded">{result.modelOutput}</p>
                      </div>
                      <div>
                        <p className="font-medium text-gray-600">Google Translate:</p>
                        <p className="bg-gray-50 p-2 rounded">{result.googleTranslateOutput}</p>
                      </div>
                    </div>
                    <p className="text-sm text-gray-700">
                      <span className="font-medium">Evaluation:</span> {result.evaluation}
                    </p>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Save Template Dialog */}
      {showSaveDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-semibold mb-4">
              Save {showSaveDialog.type === 'evaluation' ? 'Evaluation Prompt' :
                    showSaveDialog.type === 'master' ? 'Model Prompt Template' : 'Test Input'}
            </h3>
            <input
              type="text"
              value={newTemplateName}
              onChange={(e) => setNewTemplateName(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && confirmSaveTemplate()}
              placeholder="Enter template name..."
              className="w-full px-3 py-2 border rounded-lg mb-4"
              autoFocus
            />
            <div className="flex gap-2 justify-end">
              <button
                onClick={() => {
                  setShowSaveDialog(null)
                  setNewTemplateName('')
                }}
                className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Cancel
              </button>
              <button
                onClick={confirmSaveTemplate}
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
