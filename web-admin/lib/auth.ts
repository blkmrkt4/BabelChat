import { supabase } from './supabase'

export async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (error) {
    console.error('Sign out error:', error)
    throw error
  }

  // Clear local storage
  localStorage.removeItem('supabase_session')

  // Clear auth cookie
  document.cookie = 'sb-auth-token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT'

  // Redirect to login
  window.location.href = '/login'
}

export async function getCurrentUser() {
  const { data: { user } } = await supabase.auth.getUser()
  return user
}

export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession()
  return session
}

export function isAuthenticated(): boolean {
  // Check if there's a session in localStorage
  const session = localStorage.getItem('supabase_session')
  return session !== null
}
