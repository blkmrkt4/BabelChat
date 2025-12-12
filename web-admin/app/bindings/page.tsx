'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'

export default function BindingsRedirect() {
  const router = useRouter()

  useEffect(() => {
    router.replace('/')
  }, [router])

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-xl">Redirecting to AI Model Configuration...</div>
    </div>
  )
}
