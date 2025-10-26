// OpenRouter API integration
export type OpenRouterModel = {
  id: string
  name: string
  description?: string
  pricing: {
    prompt: string  // Cost per token for input
    completion: string  // Cost per token for output
    image?: string
    internal_reasoning?: string
  }
  context_length: number
  architecture?: {
    modality?: string
    tokenizer?: string
    instruct_type?: string
    input_modalities?: string[]
    output_modalities?: string[]
  }
  top_provider?: {
    max_completion_tokens?: number
  }
}

export type ModelWithScore = OpenRouterModel & {
  userScore?: number
  testCount?: number
  translationScore?: number
  speedScore?: number
}

export async function fetchOpenRouterModels(): Promise<OpenRouterModel[]> {
  try {
    const response = await fetch('https://openrouter.ai/api/v1/models', {
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      throw new Error(`Failed to fetch models: ${response.statusText}`)
    }

    const data = await response.json()
    return data.data || []
  } catch (error) {
    console.error('Error fetching OpenRouter models:', error)
    throw error
  }
}

export async function testModel(
  modelId: string,
  systemPrompt: string,
  userMessage: string,
  apiKey: string
): Promise<string> {
  try {
    const requestBody = {
      model: modelId,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ],
      temperature: 0.7,
      max_tokens: 500,
      // Allow data usage for training (required for free models)
      provider: {
        allow_fallbacks: false,
        data_collection: 'allow'
      }
    }

    console.log('🔵 OpenRouter Request:', {
      model: modelId,
      systemPromptLength: systemPrompt.length,
      userMessageLength: userMessage.length,
    })

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': typeof window !== 'undefined' ? window.location.origin : '',
      },
      body: JSON.stringify(requestBody),
    })

    if (!response.ok) {
      const errorText = await response.text()
      let errorMsg = `HTTP ${response.status}: ${errorText}`

      // Parse error for better messages
      try {
        const errorJson = JSON.parse(errorText)
        console.error('🔴 OpenRouter API Error:', errorJson)

        if (errorJson.error?.message) {
          errorMsg = `${errorJson.error.message}`

          // Add more context if available
          if (errorJson.error?.code) {
            errorMsg = `[${errorJson.error.code}] ${errorMsg}`
          }
          if (errorJson.error?.metadata) {
            errorMsg += ` | Details: ${JSON.stringify(errorJson.error.metadata)}`
          }
        }
      } catch (e) {
        // Keep original error text with status
        console.error('🔴 OpenRouter Error (unparseable):', errorText)
      }

      console.error(`🔴 Model: ${modelId}, Status: ${response.status}, Error: ${errorMsg}`)
      throw new Error(errorMsg)
    }

    const data = await response.json()
    return data.choices[0]?.message?.content || 'No response'
  } catch (error) {
    console.error('Error testing model:', error)
    throw error
  }
}

// Helper function to strip markdown code blocks from JSON responses
export function stripMarkdownJson(text: string): string {
  let cleaned = text.trim()

  // Try multiple patterns to extract JSON

  // Pattern 1: Standard markdown code block with optional language
  const codeBlockRegex = /^```(?:json)?\s*\n?([\s\S]*?)\n?```$/
  const match1 = cleaned.match(codeBlockRegex)
  if (match1) {
    cleaned = match1[1].trim()
  }

  // Pattern 2: Remove any leading text before first { or [
  const firstBrace = cleaned.indexOf('{')
  const firstBracket = cleaned.indexOf('[')

  let startIndex = -1
  if (firstBrace !== -1 && firstBracket !== -1) {
    startIndex = Math.min(firstBrace, firstBracket)
  } else if (firstBrace !== -1) {
    startIndex = firstBrace
  } else if (firstBracket !== -1) {
    startIndex = firstBracket
  }

  if (startIndex !== -1 && startIndex > 0) {
    cleaned = cleaned.substring(startIndex)
  }

  // Pattern 3: Remove any trailing text after last } or ]
  const lastBrace = cleaned.lastIndexOf('}')
  const lastBracket = cleaned.lastIndexOf(']')
  const endIndex = Math.max(lastBrace, lastBracket)
  if (endIndex !== -1 && endIndex < cleaned.length - 1) {
    cleaned = cleaned.substring(0, endIndex + 1)
  }

  return cleaned.trim()
}

export function formatCost(costString: string): string {
  const cost = parseFloat(costString) * 1000 // Convert to per 1K tokens
  if (cost === 0) return 'Free'

  // Show up to 5 decimal places for precision
  if (cost < 0.001) return `$${cost.toFixed(5)}`
  if (cost < 0.01) return `$${cost.toFixed(4)}`
  if (cost < 1) return `$${cost.toFixed(3)}`
  return `$${cost.toFixed(2)}`
}

export function getTotalCost(model: OpenRouterModel, inputTokens: number, outputTokens: number): number {
  const inputCost = parseFloat(model.pricing.prompt) * inputTokens
  const outputCost = parseFloat(model.pricing.completion) * outputTokens
  return inputCost + outputCost
}

export function isTextOnlyModel(model: OpenRouterModel): boolean {
  const arch = model.architecture
  if (!arch) return true // Assume text-only if no architecture info

  // Check for non-text modalities
  if (arch.input_modalities) {
    const hasNonText = arch.input_modalities.some(m => m !== 'text')
    if (hasNonText) return false
  }

  if (arch.output_modalities) {
    const hasNonText = arch.output_modalities.some(m => m !== 'text')
    if (hasNonText) return false
  }

  // Check modality string
  if (arch.modality && arch.modality !== 'text->text') return false

  return true
}

export function hasReasoningCost(model: OpenRouterModel): boolean {
  return model.pricing.internal_reasoning
    ? parseFloat(model.pricing.internal_reasoning) > 0
    : false
}

export function formatContextLength(contextLength: number): string {
  if (contextLength >= 1000000) {
    return `${(contextLength / 1000000).toFixed(1)}M`
  }
  if (contextLength >= 1000) {
    return `${(contextLength / 1000).toFixed(0)}K`
  }
  return `${contextLength}`
}
