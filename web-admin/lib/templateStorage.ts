// Storage for saved prompt templates and test inputs

export type SavedTemplate = {
  id: string
  title: string
  content: string
  type: 'evaluation' | 'master' | 'testinput'
  category?: string  // Optional category for filtering (e.g., 'translation', 'grammar', 'scoring')
  createdAt: string
}

const TEMPLATES_KEY = 'saved_templates'

export function getAllTemplates(): SavedTemplate[] {
  if (typeof window === 'undefined') return []
  const data = localStorage.getItem(TEMPLATES_KEY)
  return data ? JSON.parse(data) : []
}

export function getTemplatesByType(type: SavedTemplate['type']): SavedTemplate[] {
  return getAllTemplates().filter(t => t.type === type)
}

export function getTemplatesByTypeAndCategory(type: SavedTemplate['type'], category?: string): SavedTemplate[] {
  return getAllTemplates().filter(t => {
    if (t.type !== type) return false
    // If no category specified, return all of this type
    if (!category) return true
    // If template has no category, show it for all categories (backward compatibility)
    if (!t.category) return true
    // Match category
    return t.category === category
  })
}

export function saveTemplate(template: Omit<SavedTemplate, 'id' | 'createdAt'>): SavedTemplate {
  const newTemplate: SavedTemplate = {
    ...template,
    id: `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    createdAt: new Date().toISOString()
  }

  const templates = getAllTemplates()
  templates.push(newTemplate)
  localStorage.setItem(TEMPLATES_KEY, JSON.stringify(templates))

  return newTemplate
}

export function deleteTemplate(id: string) {
  const templates = getAllTemplates().filter(t => t.id !== id)
  localStorage.setItem(TEMPLATES_KEY, JSON.stringify(templates))
}

export function updateTemplate(id: string, updates: Partial<Pick<SavedTemplate, 'title' | 'content'>>) {
  const templates = getAllTemplates()
  const index = templates.findIndex(t => t.id === id)

  if (index !== -1) {
    templates[index] = { ...templates[index], ...updates }
    localStorage.setItem(TEMPLATES_KEY, JSON.stringify(templates))
    return templates[index]
  }

  return null
}
