import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { createClient } from '@supabase/supabase-js'

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Allow these paths without authentication
  const publicPaths = ['/login', '/_next', '/favicon.ico']
  const isPublicPath = publicPaths.some(path => pathname.startsWith(path))

  // Allow API routes (they use Authorization header)
  if (pathname.startsWith('/api/')) {
    return NextResponse.next()
  }

  if (isPublicPath) {
    return NextResponse.next()
  }

  // Check for Supabase auth token in cookies
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

  if (!supabaseUrl || !supabaseAnonKey) {
    console.error('Missing Supabase environment variables')
    return NextResponse.next()
  }

  // Get all Supabase-related cookies
  const authCookies = request.cookies.getAll().filter(cookie =>
    cookie.name.startsWith('sb-') || cookie.name.includes('auth-token')
  )

  // If there are any auth cookies, assume authenticated
  // This is a simplified check - in production you'd verify the JWT
  if (authCookies.length > 0) {
    return NextResponse.next()
  }

  // No auth cookies found - redirect to login
  const loginUrl = new URL('/login', request.url)
  return NextResponse.redirect(loginUrl)
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
}
