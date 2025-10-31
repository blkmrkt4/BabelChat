import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export type AIConfig = {
  id: string
  category: 'translation' | 'grammar' | 'scoring'
  model_id: string
  model_name: string
  model_provider: string
  prompt_template: string
  grammar_level_1_prompt?: string | null
  grammar_level_2_prompt?: string | null
  grammar_level_3_prompt?: string | null
  temperature: number
  max_tokens: number
  is_active: boolean
  // Fallback models for resilience
  fallback_model_1_id?: string | null
  fallback_model_1_name?: string | null
  fallback_model_2_id?: string | null
  fallback_model_2_name?: string | null
  fallback_model_3_id?: string | null
  fallback_model_3_name?: string | null
  created_at: string
  updated_at: string
}

export async function getAIConfigs(): Promise<AIConfig[]> {
  const { data, error } = await supabase
    .from('ai_config')
    .select('*')
    .order('category')

  if (error) throw error
  return data || []
}

export async function getAIConfig(category: string): Promise<AIConfig | null> {
  const { data, error } = await supabase
    .from('ai_config')
    .select('*')
    .eq('category', category)
    .single()

  if (error) throw error
  return data
}

export async function updateAIConfig(
  category: string,
  updates: Partial<AIConfig>
): Promise<AIConfig> {
  const { data, error } = await supabase
    .from('ai_config')
    .update(updates)
    .eq('category', category)
    .select()
    .single()

  if (error) throw error
  return data
}

export async function createAIConfig(
  category: string,
  config: {
    model_id: string
    model_name: string
    model_provider: string
    prompt_template: string
    temperature?: number
    max_tokens?: number
    grammar_level_1_prompt?: string
    grammar_level_2_prompt?: string
    grammar_level_3_prompt?: string
    fallback_model_1_id?: string
    fallback_model_1_name?: string
    fallback_model_2_id?: string
    fallback_model_2_name?: string
    fallback_model_3_id?: string
    fallback_model_3_name?: string
  }
): Promise<AIConfig> {
  const { data, error } = await supabase
    .from('ai_config')
    .insert([{
      category,
      model_id: config.model_id,
      model_name: config.model_name,
      model_provider: config.model_provider,
      prompt_template: config.prompt_template,
      temperature: config.temperature ?? 0.7,
      max_tokens: config.max_tokens ?? 1000,
      grammar_level_1_prompt: config.grammar_level_1_prompt,
      grammar_level_2_prompt: config.grammar_level_2_prompt,
      grammar_level_3_prompt: config.grammar_level_3_prompt,
      fallback_model_1_id: config.fallback_model_1_id,
      fallback_model_1_name: config.fallback_model_1_name,
      fallback_model_2_id: config.fallback_model_2_id,
      fallback_model_2_name: config.fallback_model_2_name,
      fallback_model_3_id: config.fallback_model_3_id,
      fallback_model_3_name: config.fallback_model_3_name,
      is_active: true,
    }])
    .select()
    .single()

  if (error) throw error
  return data
}
