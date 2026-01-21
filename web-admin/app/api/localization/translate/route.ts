import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
const openRouterApiKey = process.env.OPENROUTER_API_KEY!

const supabase = createClient(supabaseUrl, supabaseKey)

// Recommended models per language (based on quality/cost balance)
// You can override these in the UI
const RECOMMENDED_MODELS: Record<string, string> = {
  // European languages - Claude Sonnet works great
  es: 'anthropic/claude-3.5-sonnet',
  fr: 'anthropic/claude-3.5-sonnet',
  de: 'anthropic/claude-3.5-sonnet',
  it: 'anthropic/claude-3.5-sonnet',
  'pt-BR': 'anthropic/claude-3.5-sonnet', // Brazilian Portuguese
  'pt-PT': 'anthropic/claude-3.5-sonnet', // European Portuguese
  nl: 'anthropic/claude-3.5-sonnet',
  sv: 'anthropic/claude-3.5-sonnet',
  da: 'anthropic/claude-3.5-sonnet',
  fi: 'anthropic/claude-3.5-sonnet',
  no: 'anthropic/claude-3.5-sonnet',
  pl: 'anthropic/claude-3.5-sonnet',
  ru: 'anthropic/claude-3.5-sonnet',

  // Asian languages
  ja: 'anthropic/claude-3.5-sonnet',
  ko: 'anthropic/claude-3.5-sonnet',
  zh: 'qwen/qwen-2.5-72b-instruct', // Qwen excels at Chinese
  th: 'anthropic/claude-3.5-sonnet',
  id: 'anthropic/claude-3.5-sonnet',
  tl: 'anthropic/claude-3.5-sonnet',

  // Other
  ar: 'meta-llama/llama-3.3-70b-instruct', // Top performer for Arabic
  hi: 'anthropic/claude-3.5-sonnet',

  // Default
  default: 'anthropic/claude-3.5-sonnet',
}

// Language names for prompts
const LANGUAGE_NAMES: Record<string, string> = {
  en: 'English',
  es: 'Spanish',
  fr: 'French',
  de: 'German',
  it: 'Italian',
  'pt-BR': 'Brazilian Portuguese',
  'pt-PT': 'European Portuguese (Portugal)',
  ja: 'Japanese',
  ko: 'Korean',
  zh: 'Chinese (Simplified)',
  ru: 'Russian',
  ar: 'Arabic',
  hi: 'Hindi',
  nl: 'Dutch',
  sv: 'Swedish',
  da: 'Danish',
  fi: 'Finnish',
  no: 'Norwegian',
  pl: 'Polish',
  id: 'Indonesian',
  tl: 'Filipino (Tagalog)',
  th: 'Thai',
}

interface TranslateRequest {
  strings: Array<{
    string_key: string
    value: string // English source
    context?: string
  }>
  targetLanguage: string
  modelId?: string // Optional override
  retranslateAll?: boolean // If true, re-translate all strings; if false (default), skip existing
}

// POST - Translate strings to a target language
export async function POST(request: Request) {
  try {
    if (!openRouterApiKey) {
      return NextResponse.json({ error: 'OpenRouter API key not configured' }, { status: 500 })
    }

    const { strings, targetLanguage, modelId, retranslateAll = false }: TranslateRequest = await request.json()

    if (!strings || !Array.isArray(strings) || strings.length === 0) {
      return NextResponse.json({ error: 'strings array is required' }, { status: 400 })
    }

    if (!targetLanguage) {
      return NextResponse.json({ error: 'targetLanguage is required' }, { status: 400 })
    }

    // Select model
    const model = modelId || RECOMMENDED_MODELS[targetLanguage] || RECOMMENDED_MODELS.default
    const targetLangName = LANGUAGE_NAMES[targetLanguage] || targetLanguage

    // Filter out strings that already have translations (unless retranslateAll is true)
    let stringsToTranslate = strings
    let skippedCount = 0

    if (!retranslateAll) {
      // Get existing translations for this language
      const { data: existingTranslations } = await supabase
        .from('app_translations')
        .select('string_key')
        .eq('language_code', targetLanguage)

      if (existingTranslations && existingTranslations.length > 0) {
        const existingKeys = new Set(existingTranslations.map(t => t.string_key))
        stringsToTranslate = strings.filter(s => !existingKeys.has(s.string_key))
        skippedCount = strings.length - stringsToTranslate.length
      }
    }

    // If all strings already have translations, return early
    if (stringsToTranslate.length === 0) {
      return NextResponse.json({
        success: true,
        model,
        targetLanguage,
        total: strings.length,
        skipped: skippedCount,
        successful: 0,
        failed: 0,
        saved: 0,
        message: 'All strings already have translations. Use "Re-translate all" to overwrite.',
        results: [],
      })
    }

    console.log(`🌐 Translating ${stringsToTranslate.length} strings to ${targetLangName} using ${model}${skippedCount > 0 ? ` (skipping ${skippedCount} existing)` : ''}`)

    const results: Array<{
      string_key: string
      translation: string
      success: boolean
      error?: string
    }> = []

    // Process in batches of 5 for more reliable responses
    const batchSize = 5
    for (let i = 0; i < stringsToTranslate.length; i += batchSize) {
      const batch = stringsToTranslate.slice(i, i + batchSize)

      // Build the translation prompt
      const batchPrompt = batch.map((s, idx) => {
        const contextNote = s.context ? ` (Context: ${s.context})` : ''
        return `${idx + 1}. "${s.value}"${contextNote}`
      }).join('\n')

      const systemPrompt = `You are a professional translator specializing in mobile app UI localization.
Translate the following English UI strings to ${targetLangName}.

IMPORTANT RULES:
1. Keep translations concise - UI space is limited
2. Preserve any placeholders like {name}, %d, %@, etc. exactly as they appear
3. Use natural, native-sounding ${targetLangName} - avoid literal translations
4. For button labels and short text, keep it brief
5. Maintain the same tone (formal/informal) as the original

Respond with ONLY a JSON array of translations in the same order, like:
["translation1", "translation2", ...]

Do not include any explanation or markdown formatting.`

      const userMessage = `Translate these ${batch.length} UI strings to ${targetLangName}:\n\n${batchPrompt}`

      // Retry logic for failed batches
      const maxRetries = 2
      let batchSuccess = false

      for (let attempt = 1; attempt <= maxRetries && !batchSuccess; attempt++) {
        try {
          const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${openRouterApiKey}`,
              'Content-Type': 'application/json',
              'HTTP-Referer': process.env.NEXT_PUBLIC_BASE_URL || 'https://admin.silentseer.com',
            },
            body: JSON.stringify({
              model,
              messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user', content: userMessage },
              ],
              temperature: 0.1, // Very low temperature for consistent JSON output
              max_tokens: 1500,
            }),
          })

          if (!response.ok) {
            const errorText = await response.text()
            console.error(`OpenRouter error for batch ${i / batchSize + 1} (attempt ${attempt}):`, errorText)
            if (attempt === maxRetries) {
              for (const s of batch) {
                results.push({
                  string_key: s.string_key,
                  translation: '',
                  success: false,
                  error: `API error: ${response.status}`,
                })
              }
            }
            continue
          }

          const data = await response.json()
          const content = data.choices[0]?.message?.content || ''

          // Parse the JSON array response
          let translations: string[]
          let cleaned = content.trim()

          // Clean up potential markdown formatting
          if (cleaned.startsWith('```')) {
            cleaned = cleaned.replace(/^```(?:json)?\s*\n?/, '').replace(/\n?```$/, '')
          }

          // Check if it looks like valid JSON array
          if (!cleaned.startsWith('[')) {
            console.error(`Invalid response format (attempt ${attempt}):`, cleaned.substring(0, 100))
            if (attempt < maxRetries) {
              await new Promise(resolve => setTimeout(resolve, 1000)) // Wait before retry
              continue
            }
          }

          try {
            translations = JSON.parse(cleaned)
          } catch (parseError) {
            console.error(`Failed to parse JSON (attempt ${attempt}):`, cleaned.substring(0, 100))
            if (attempt < maxRetries) {
              await new Promise(resolve => setTimeout(resolve, 1000))
              continue
            }
            // Final attempt failed - mark batch as failed
            for (const s of batch) {
              results.push({
                string_key: s.string_key,
                translation: '',
                success: false,
                error: 'Invalid response format',
              })
            }
            batchSuccess = true // Exit retry loop
            continue
          }

          // Validate we got the right number of translations
          if (translations.length !== batch.length) {
            console.error(`Mismatch: expected ${batch.length}, got ${translations.length}`)
          }

          // Match translations to original strings
          for (let j = 0; j < batch.length; j++) {
            const translation = translations[j] || ''
            results.push({
              string_key: batch[j].string_key,
              translation: translation.trim(),
              success: !!translation.trim(),
              error: translation.trim() ? undefined : 'Empty translation',
            })
          }
          batchSuccess = true

        } catch (batchError) {
          console.error(`Error processing batch ${i / batchSize + 1} (attempt ${attempt}):`, batchError)
          if (attempt === maxRetries) {
            for (const s of batch) {
              results.push({
                string_key: s.string_key,
                translation: '',
                success: false,
                error: String(batchError),
              })
            }
          }
        }
      }

      // Small delay between batches to avoid rate limiting
      if (i + batchSize < stringsToTranslate.length) {
        await new Promise(resolve => setTimeout(resolve, 300))
      }
    }

    // Save successful translations to database
    let saved = 0
    let saveErrors: string[] = []

    for (const result of results) {
      if (result.success && result.translation) {
        try {
          const { error } = await supabase
            .from('app_translations')
            .upsert({
              string_key: result.string_key,
              language_code: targetLanguage,
              value: result.translation,
              source: 'llm',
              verified: false,
              context: stringsToTranslate.find(s => s.string_key === result.string_key)?.context || null,
            }, {
              onConflict: 'string_key,language_code'
            })

          if (error) {
            saveErrors.push(`${result.string_key}: ${error.message}`)
          } else {
            saved++
          }
        } catch (e) {
          saveErrors.push(`${result.string_key}: ${e}`)
        }
      }
    }

    const successful = results.filter(r => r.success).length
    const failed = results.filter(r => !r.success).length

    console.log(`✅ Translation complete: ${successful} successful, ${failed} failed, ${skippedCount} skipped, ${saved} saved`)

    return NextResponse.json({
      success: true,
      model,
      targetLanguage,
      total: strings.length,
      skipped: skippedCount,
      successful,
      failed,
      saved,
      saveErrors: saveErrors.length > 0 ? saveErrors : undefined,
      results,
    })
  } catch (error) {
    console.error('Translation error:', error)
    return NextResponse.json({ error: 'Failed to translate strings' }, { status: 500 })
  }
}

// GET - Get recommended model for a language
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const languageCode = searchParams.get('language_code')

  if (languageCode) {
    return NextResponse.json({
      languageCode,
      recommendedModel: RECOMMENDED_MODELS[languageCode] || RECOMMENDED_MODELS.default,
      languageName: LANGUAGE_NAMES[languageCode] || languageCode,
    })
  }

  // Return all recommendations
  return NextResponse.json({
    recommendations: RECOMMENDED_MODELS,
    languageNames: LANGUAGE_NAMES,
  })
}
