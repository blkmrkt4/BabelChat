// Storage for prompt templates in Supabase
import { supabase } from './supabase'

export type PromptTemplate = {
  id: string
  name: string
  category: 'translation' | 'grammar' | 'scoring' | 'chatting'
  system_prompt: string | null
  user_prompt: string | null
  description: string | null
  created_at: string
  updated_at: string
}

export async function getAllPromptTemplates(): Promise<PromptTemplate[]> {
  const { data, error } = await supabase
    .from('prompt_templates')
    .select('*')
    .order('name')

  if (error) {
    console.error('Error fetching prompt templates:', error)
    return []
  }

  return data || []
}

export async function getPromptTemplatesByCategory(category: string): Promise<PromptTemplate[]> {
  const { data, error } = await supabase
    .from('prompt_templates')
    .select('*')
    .eq('category', category)
    .order('name')

  if (error) {
    console.error('Error fetching prompt templates by category:', error)
    return []
  }

  return data || []
}

export async function getPromptTemplate(id: string): Promise<PromptTemplate | null> {
  const { data, error } = await supabase
    .from('prompt_templates')
    .select('*')
    .eq('id', id)
    .single()

  if (error) {
    console.error('Error fetching prompt template:', error)
    return null
  }

  return data
}

export async function savePromptTemplate(template: {
  name: string
  category: 'translation' | 'grammar' | 'scoring' | 'chatting'
  system_prompt?: string | null
  user_prompt?: string | null
  description?: string | null
}): Promise<PromptTemplate | null> {
  const { data, error } = await supabase
    .from('prompt_templates')
    .insert([{
      name: template.name,
      category: template.category,
      system_prompt: template.system_prompt || null,
      user_prompt: template.user_prompt || null,
      description: template.description || null,
    }])
    .select()
    .single()

  if (error) {
    console.error('Error saving prompt template:', error)
    throw error
  }

  return data
}

export async function updatePromptTemplate(
  id: string,
  updates: Partial<Pick<PromptTemplate, 'name' | 'system_prompt' | 'user_prompt' | 'description'>>
): Promise<PromptTemplate | null> {
  const { data, error } = await supabase
    .from('prompt_templates')
    .update(updates)
    .eq('id', id)
    .select()
    .single()

  if (error) {
    console.error('Error updating prompt template:', error)
    throw error
  }

  return data
}

export async function deletePromptTemplate(id: string): Promise<void> {
  const { error } = await supabase
    .from('prompt_templates')
    .delete()
    .eq('id', id)

  if (error) {
    console.error('Error deleting prompt template:', error)
    throw error
  }
}
