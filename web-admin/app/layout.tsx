'use client'

import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import Link from 'next/link'
import { usePathname } from 'next/navigation'

const inter = Inter({ subsets: ['latin'] })

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const pathname = usePathname()

  const links = [
    { href: '/', label: 'AI Model/Prompt Bindings' },
    { href: '/evaluation', label: 'Model/Prompt Testing' },
    { href: '/round-robin', label: 'Round Robin Results' },
    { href: '/monitoring', label: 'Monitoring' },
    { href: '/users', label: 'Users' },
    { href: '/moderation', label: 'Moderation' },
    { href: '/pricing', label: 'Pricing' },
    { href: '/voices', label: 'TTS Voices' },
    { href: '/settings', label: 'Settings' },
  ]

  return (
    <html lang="en">
      <body className={inter.className}>
        <nav className="bg-blue-600 text-white p-4">
          <div className="container mx-auto flex justify-between items-center">
            <h1 className="text-2xl font-bold">ByzyB.ai</h1>
            <div className="flex gap-1">
              {links.map((link) => {
                const isActive = pathname === link.href
                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    className={`px-4 py-2 rounded transition-colors ${
                      isActive
                        ? 'bg-blue-700 font-semibold'
                        : 'hover:bg-blue-500'
                    }`}
                  >
                    {link.label}
                  </Link>
                )
              })}
            </div>
          </div>
        </nav>
        <main className="container mx-auto p-6">
          {children}
        </main>
      </body>
    </html>
  )
}
