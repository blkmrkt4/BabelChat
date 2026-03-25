import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
const openRouterApiKey = process.env.OPENROUTER_API_KEY!

const supabase = createClient(supabaseUrl, supabaseKey)

const RECOMMENDED_MODELS: Record<string, string> = {
  es: 'anthropic/claude-3.5-sonnet',
  fr: 'anthropic/claude-3.5-sonnet',
  de: 'anthropic/claude-3.5-sonnet',
  it: 'anthropic/claude-3.5-sonnet',
  'pt-BR': 'anthropic/claude-3.5-sonnet',
  'pt-PT': 'anthropic/claude-3.5-sonnet',
  nl: 'anthropic/claude-3.5-sonnet',
  sv: 'anthropic/claude-3.5-sonnet',
  da: 'anthropic/claude-3.5-sonnet',
  fi: 'anthropic/claude-3.5-sonnet',
  no: 'anthropic/claude-3.5-sonnet',
  pl: 'anthropic/claude-3.5-sonnet',
  ru: 'anthropic/claude-3.5-sonnet',
  ja: 'anthropic/claude-3.5-sonnet',
  ko: 'anthropic/claude-3.5-sonnet',
  zh: 'qwen/qwen-2.5-72b-instruct',
  th: 'anthropic/claude-3.5-sonnet',
  id: 'anthropic/claude-3.5-sonnet',
  tl: 'anthropic/claude-3.5-sonnet',
  ar: 'meta-llama/llama-3.3-70b-instruct',
  hi: 'anthropic/claude-3.5-sonnet',
  default: 'anthropic/claude-3.5-sonnet',
}

const LANGUAGE_NAMES: Record<string, string> = {
  en: 'English', es: 'Spanish', fr: 'French', de: 'German', it: 'Italian',
  'pt-BR': 'Brazilian Portuguese', 'pt-PT': 'European Portuguese (Portugal)',
  ja: 'Japanese', ko: 'Korean', zh: 'Chinese (Simplified)', ru: 'Russian',
  ar: 'Arabic', hi: 'Hindi', nl: 'Dutch', sv: 'Swedish', da: 'Danish',
  fi: 'Finnish', no: 'Norwegian', pl: 'Polish', id: 'Indonesian',
  tl: 'Filipino (Tagalog)', th: 'Thai',
}

interface TranslateRequest {
  strings: Array<{
    string_key: string
    value: string
    context?: string
  }>
  targetLanguage: string
  modelId?: string
  retranslateAll?: boolean
  stream?: boolean // If true, use SSE streaming
}

// POST - Translate strings to a target language (supports streaming via SSE)
export async function POST(request: Request) {
  try {
    if (!openRouterApiKey) {
      return NextResponse.json({ error: 'OpenRouter API key not configured' }, { status: 500 })
    }

    const { strings, targetLanguage, modelId, retranslateAll = false, stream = false }: TranslateRequest = await request.json()

    if (!strings || !Array.isArray(strings) || strings.length === 0) {
      return NextResponse.json({ error: 'strings array is required' }, { status: 400 })
    }

    if (!targetLanguage) {
      return NextResponse.json({ error: 'targetLanguage is required' }, { status: 400 })
    }

    const model = modelId || RECOMMENDED_MODELS[targetLanguage] || RECOMMENDED_MODELS.default
    const targetLangName = LANGUAGE_NAMES[targetLanguage] || targetLanguage

    // Filter out strings that already have translations
    let stringsToTranslate = strings
    let skippedCount = 0

    if (!retranslateAll) {
      // Paginate to fetch ALL existing keys (Supabase defaults to 1000 row limit)
      const existingKeys = new Set<string>()
      let from = 0
      const pageSize = 1000
      let hasMore = true
      while (hasMore) {
        const { data: page } = await supabase
          .from('app_translations')
          .select('string_key')
          .eq('language_code', targetLanguage)
          .range(from, from + pageSize - 1)

        if (page && page.length > 0) {
          for (const t of page) existingKeys.add(t.string_key)
          hasMore = page.length === pageSize
          from += pageSize
        } else {
          hasMore = false
        }
      }

      if (existingKeys.size > 0) {
        stringsToTranslate = strings.filter(s => !existingKeys.has(s.string_key))
        skippedCount = strings.length - stringsToTranslate.length
      }
    }

    // If all strings already translated, return early
    if (stringsToTranslate.length === 0) {
      if (stream) {
        const encoder = new TextEncoder()
        const readable = new ReadableStream({
          start(controller) {
            controller.enqueue(encoder.encode(`data: ${JSON.stringify({ type: 'info', message: `${targetLangName}: All ${skippedCount} strings already translated. Nothing to do.` })}\n\n`))
            controller.enqueue(encoder.encode(`data: ${JSON.stringify({ type: 'done', successful: 0, failed: 0, skipped: skippedCount, saved: 0 })}\n\n`))
            controller.close()
          }
        })
        return new Response(readable, { headers: { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', 'Connection': 'keep-alive' } })
      }
      return NextResponse.json({
        success: true, model, targetLanguage, total: strings.length,
        skipped: skippedCount, successful: 0, failed: 0, saved: 0,
        message: 'All strings already have translations.',
        results: [],
      })
    }

    // --- Streaming mode ---
    if (stream) {
      const encoder = new TextEncoder()
      let cancelled = false

      const readable = new ReadableStream({
        async start(controller) {
          function send(data: any) {
            if (cancelled) return
            try {
              controller.enqueue(encoder.encode(`data: ${JSON.stringify(data)}\n\n`))
            } catch {
              cancelled = true
            }
          }

          send({ type: 'info', message: `Starting ${targetLangName} translation using model: ${model}` })
          send({ type: 'info', message: `${stringsToTranslate.length} strings to translate, ${skippedCount} skipped (already exist)` })

          // Separate long strings (e.g. App Store descriptions) for individual translation
          const LONG_STRING_THRESHOLD = 500
          const longStrings = stringsToTranslate.filter(s => s.value.length >= LONG_STRING_THRESHOLD)
          const shortStrings = stringsToTranslate.filter(s => s.value.length < LONG_STRING_THRESHOLD)

          // Build batches: long strings get their own batch of 1, short strings batch by 5
          const batches: Array<typeof stringsToTranslate> = []
          for (const ls of longStrings) {
            batches.push([ls])
          }
          const shortBatchSize = 5
          for (let i = 0; i < shortStrings.length; i += shortBatchSize) {
            batches.push(shortStrings.slice(i, i + shortBatchSize))
          }

          const totalBatches = batches.length
          let successful = 0
          let failed = 0
          let saved = 0
          let processedStrings = 0

          for (let batchIdx = 0; batchIdx < batches.length && !cancelled; batchIdx++) {
            const batchNum = batchIdx + 1
            const batch = batches[batchIdx]
            const batchKeys = batch.map(s => s.string_key).join(', ')

            send({ type: 'batch_start', message: `Batch ${batchNum}/${totalBatches}: Translating ${batch.length} strings...`, detail: batchKeys })

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
6. Any text enclosed in double quotes (e.g. "Language Match") must NOT be translated — keep the original text exactly as-is but REMOVE the surrounding quotes in the translation. For example: © 2025 "Language Match". All rights reserved → © 2025 Language Match. Todos los derechos reservados.
7. CRITICAL: Your response must be valid JSON. Escape any double quotes inside translations with a backslash (\\"). For example: "Are you sure about \\"%@\\"?"

Respond with ONLY a valid JSON array of translations in the same order, like:
["translation1", "translation2", ...]

Do not include any explanation or markdown formatting.`

            const userMessage = `Translate these ${batch.length} UI strings to ${targetLangName}:\n\n${batchPrompt}`

            let batchSuccess = false
            for (let attempt = 1; attempt <= 2 && !batchSuccess && !cancelled; attempt++) {
              try {
                if (attempt > 1) {
                  send({ type: 'warn', message: `  Retry attempt ${attempt} for batch ${batchNum}...` })
                }

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
                    temperature: 0.1,
                    max_tokens: Math.max(1500, Math.ceil(batch.reduce((sum, s) => sum + s.value.length, 0) / 2)),
                  }),
                })

                if (!response.ok) {
                  const errorText = await response.text()
                  send({ type: 'error', message: `  OpenRouter API error (HTTP ${response.status}): ${errorText.substring(0, 200)}` })
                  if (attempt === 2) {
                    failed += batch.length
                    send({ type: 'error', message: `  Batch ${batchNum} FAILED after 2 attempts (${batch.length} strings lost)` })
                  }
                  continue
                }

                const data = await response.json()
                const content = data.choices[0]?.message?.content || ''

                let translations: string[]
                let cleaned = content.trim()

                if (cleaned.startsWith('```')) {
                  cleaned = cleaned.replace(/^```(?:json)?\s*\n?/, '').replace(/\n?```$/, '')
                }

                if (!cleaned.startsWith('[')) {
                  send({ type: 'warn', message: `  Invalid response format (not a JSON array), attempt ${attempt}` })
                  if (attempt < 2) {
                    await new Promise(resolve => setTimeout(resolve, 1000))
                    continue
                  }
                }

                try {
                  translations = JSON.parse(cleaned)
                } catch {
                  // Repair attempt
                  try {
                    const inner = cleaned.replace(/^\[/, '').replace(/\]$/, '').trim()
                    const parts = inner.split(/",\s*"/)
                    translations = parts.map((p: string, idx: number) => {
                      let s = p
                      if (idx === 0) s = s.replace(/^"/, '')
                      if (idx === parts.length - 1) s = s.replace(/"$/, '')
                      return s.trim()
                    })
                    if (translations.length !== batch.length) {
                      throw new Error(`length mismatch: got ${translations.length}, expected ${batch.length}`)
                    }
                    send({ type: 'warn', message: `  Repaired malformed JSON for batch ${batchNum}` })
                  } catch (repairErr) {
                    send({ type: 'error', message: `  JSON parse failed for batch ${batchNum} (attempt ${attempt}): ${String(repairErr).substring(0, 100)}` })
                    if (attempt < 2) {
                      await new Promise(resolve => setTimeout(resolve, 1000))
                      continue
                    }
                    failed += batch.length
                    send({ type: 'error', message: `  Batch ${batchNum} FAILED — could not parse response` })
                    batchSuccess = true
                    continue
                  }
                }

                // Save translations
                let batchSaved = 0
                let batchFailed = 0
                for (let j = 0; j < batch.length; j++) {
                  const translation = (translations[j] || '').trim()
                  if (!translation) {
                    failed++
                    batchFailed++
                    continue
                  }

                  const { error } = await supabase
                    .from('app_translations')
                    .upsert({
                      string_key: batch[j].string_key,
                      language_code: targetLanguage,
                      value: translation,
                      source: 'llm',
                      verified: false,
                      context: batch[j].context || null,
                    }, { onConflict: 'string_key,language_code' })

                  if (error) {
                    failed++
                    batchFailed++
                    send({ type: 'error', message: `  DB save error for "${batch[j].string_key}": ${error.message}` })
                  } else {
                    successful++
                    saved++
                    batchSaved++
                  }
                }

                send({
                  type: 'batch_done',
                  message: `Batch ${batchNum}/${totalBatches} done: ${batchSaved} saved${batchFailed > 0 ? `, ${batchFailed} failed` : ''}`,
                  successful, failed, saved, total: stringsToTranslate.length,
                  progress: Math.round(((processedStrings + batch.length) / stringsToTranslate.length) * 100),
                })
                batchSuccess = true

              } catch (err) {
                send({ type: 'error', message: `  Exception in batch ${batchNum} (attempt ${attempt}): ${String(err).substring(0, 200)}` })
                if (attempt === 2) {
                  failed += batch.length
                  send({ type: 'error', message: `  Batch ${batchNum} FAILED after exception` })
                } else {
                  await new Promise(resolve => setTimeout(resolve, 1000))
                }
              }
            }

            processedStrings += batch.length

            // Rate limit delay
            if (batchIdx + 1 < batches.length && !cancelled) {
              await new Promise(resolve => setTimeout(resolve, 300))
            }
          }

          send({
            type: 'done',
            message: `${targetLangName} complete: ${successful} translated, ${failed} failed, ${skippedCount} skipped, ${saved} saved to DB`,
            successful, failed, skipped: skippedCount, saved,
          })

          try { controller.close() } catch {}
        }
      })

      return new Response(readable, {
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      })
    }

    // --- Non-streaming mode (legacy) ---
    console.log(`🌐 Translating ${stringsToTranslate.length} strings to ${targetLangName} using ${model}${skippedCount > 0 ? ` (skipping ${skippedCount} existing)` : ''}`)

    const results: Array<{ string_key: string; translation: string; success: boolean; error?: string }> = []

    // Build batches: long strings individually, short strings in groups of 5
    const legacyBatches: Array<typeof stringsToTranslate> = []
    const legacyLong = stringsToTranslate.filter(s => s.value.length >= 500)
    const legacyShort = stringsToTranslate.filter(s => s.value.length < 500)
    for (const ls of legacyLong) legacyBatches.push([ls])
    for (let i = 0; i < legacyShort.length; i += 5) legacyBatches.push(legacyShort.slice(i, i + 5))

    for (const batch of legacyBatches) {

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
6. Any text enclosed in double quotes (e.g. "Language Match") must NOT be translated — keep the original text exactly as-is but REMOVE the surrounding quotes in the translation. For example: © 2025 "Language Match". All rights reserved → © 2025 Language Match. Todos los derechos reservados.
7. CRITICAL: Your response must be valid JSON. Escape any double quotes inside translations with a backslash (\\"). For example: "Are you sure about \\"%@\\"?"

Respond with ONLY a valid JSON array of translations in the same order, like:
["translation1", "translation2", ...]

Do not include any explanation or markdown formatting.`

      const userMessage = `Translate these ${batch.length} UI strings to ${targetLangName}:\n\n${batchPrompt}`
      let batchSuccess = false

      for (let attempt = 1; attempt <= 2 && !batchSuccess; attempt++) {
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
              messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: userMessage }],
              temperature: 0.1, max_tokens: Math.max(1500, Math.ceil(batch.reduce((sum, s) => sum + s.value.length, 0) / 2)),
            }),
          })

          if (!response.ok) {
            if (attempt === 2) {
              for (const s of batch) results.push({ string_key: s.string_key, translation: '', success: false, error: `API error: ${response.status}` })
            }
            continue
          }

          const data = await response.json()
          let cleaned = (data.choices[0]?.message?.content || '').trim()
          if (cleaned.startsWith('```')) cleaned = cleaned.replace(/^```(?:json)?\s*\n?/, '').replace(/\n?```$/, '')

          let translations: string[]
          try {
            translations = JSON.parse(cleaned)
          } catch {
            try {
              const inner = cleaned.replace(/^\[/, '').replace(/\]$/, '').trim()
              const parts = inner.split(/",\s*"/)
              translations = parts.map((p: string, idx: number) => {
                let s = p; if (idx === 0) s = s.replace(/^"/, ''); if (idx === parts.length - 1) s = s.replace(/"$/, ''); return s.trim()
              })
            } catch {
              if (attempt === 2) for (const s of batch) results.push({ string_key: s.string_key, translation: '', success: false, error: 'Parse error' })
              continue
            }
          }

          for (let j = 0; j < batch.length; j++) {
            const t = (translations[j] || '').trim()
            results.push({ string_key: batch[j].string_key, translation: t, success: !!t, error: t ? undefined : 'Empty' })
          }
          batchSuccess = true
        } catch (err) {
          if (attempt === 2) for (const s of batch) results.push({ string_key: s.string_key, translation: '', success: false, error: String(err) })
        }
      }
      await new Promise(r => setTimeout(r, 300))
    }

    let saved = 0
    for (const result of results) {
      if (result.success && result.translation) {
        const { error } = await supabase.from('app_translations').upsert({
          string_key: result.string_key, language_code: targetLanguage, value: result.translation,
          source: 'llm', verified: false, context: stringsToTranslate.find(s => s.string_key === result.string_key)?.context || null,
        }, { onConflict: 'string_key,language_code' })
        if (!error) saved++
      }
    }

    return NextResponse.json({
      success: true, model, targetLanguage, total: strings.length,
      skipped: skippedCount, successful: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length, saved, results,
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

  return NextResponse.json({ recommendations: RECOMMENDED_MODELS, languageNames: LANGUAGE_NAMES })
}
