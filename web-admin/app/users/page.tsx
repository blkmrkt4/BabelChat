'use client'

import { useEffect, useState } from 'react'

interface UserDetail {
  id: string
  email: string
  firstName: string
  lastName: string
  subscriptionTier: string
  isPremium: boolean
  createdAt: string
  lastActive: string
  location: string
  nativeLanguage: string
  learningLanguages: string[]
  matchCount: number
  realMessagesSent: number
  realMessagesReceived: number
  museInteractions: number
  ttsPlaysUsed: number
  isActiveToday: boolean
  isActiveWeek: boolean
}

interface Summary {
  totalUsers: number
  activeToday: number
  activeWeek: number
  premiumUsers: number
  totalMatches: number
  totalRealMessages: number
  totalMuseInteractions: number
  totalTTSPlays: number
}

type SortField = 'name' | 'email' | 'lastActive' | 'createdAt' | 'ttsPlays' | 'matchCount' | 'realMessages' | 'museInteractions'

export default function UsersPage() {
  const [users, setUsers] = useState<UserDetail[]>([])
  const [summary, setSummary] = useState<Summary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')
  const [sortBy, setSortBy] = useState<SortField>('lastActive')
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc')
  const [selectedUser, setSelectedUser] = useState<UserDetail | null>(null)

  const fetchUsers = async () => {
    try {
      setLoading(true)
      const params = new URLSearchParams({
        sortBy,
        sortOrder,
        search,
        limit: '100'
      })

      const response = await fetch(`/api/users-detail?${params}`)
      const data = await response.json()

      if (data.success) {
        setUsers(data.data.users)
        setSummary(data.data.summary)
        setError(null)
      } else {
        setError(data.error || 'Failed to fetch users')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch users')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchUsers()
  }, [sortBy, sortOrder])

  useEffect(() => {
    const debounce = setTimeout(() => {
      fetchUsers()
    }, 300)
    return () => clearTimeout(debounce)
  }, [search])

  const handleSort = (field: SortField) => {
    if (sortBy === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')
    } else {
      setSortBy(field)
      setSortOrder('desc')
    }
  }

  const formatDate = (dateString: string) => {
    if (!dateString) return 'Never'
    const date = new Date(dateString)
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)

    if (diffMins < 1) return 'Just now'
    if (diffMins < 60) return `${diffMins}m ago`
    if (diffHours < 24) return `${diffHours}h ago`
    if (diffDays < 7) return `${diffDays}d ago`
    return date.toLocaleDateString()
  }

  const SortIcon = ({ field }: { field: SortField }) => {
    if (sortBy !== field) return <span className="text-gray-400 ml-1">↕</span>
    return <span className="text-blue-500 ml-1">{sortOrder === 'asc' ? '↑' : '↓'}</span>
  }

  // Sort users client-side for fields not in API
  const sortedUsers = [...users].sort((a, b) => {
    let aVal: number | string = 0
    let bVal: number | string = 0

    switch (sortBy) {
      case 'matchCount':
        aVal = a.matchCount
        bVal = b.matchCount
        break
      case 'realMessages':
        aVal = a.realMessagesSent + a.realMessagesReceived
        bVal = b.realMessagesSent + b.realMessagesReceived
        break
      case 'museInteractions':
        aVal = a.museInteractions
        bVal = b.museInteractions
        break
      default:
        return 0 // Already sorted by API
    }

    if (typeof aVal === 'number' && typeof bVal === 'number') {
      return sortOrder === 'asc' ? aVal - bVal : bVal - aVal
    }
    return 0
  })

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Users</h1>
          <p className="text-gray-600 mt-1">View all users and their activity statistics</p>
        </div>

        {/* Summary Cards */}
        {summary && (
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-4 mb-8">
            <div className="bg-white rounded-lg shadow p-4">
              <div className="text-2xl font-bold text-gray-900">{summary.totalUsers}</div>
              <div className="text-sm text-gray-500">Total Users</div>
            </div>
            <div className="bg-white rounded-lg shadow p-4">
              <div className="text-2xl font-bold text-green-600">{summary.activeToday}</div>
              <div className="text-sm text-gray-500">Active Today</div>
            </div>
            <div className="bg-white rounded-lg shadow p-4">
              <div className="text-2xl font-bold text-blue-600">{summary.activeWeek}</div>
              <div className="text-sm text-gray-500">Active Week</div>
            </div>
            <div className="bg-white rounded-lg shadow p-4">
              <div className="text-2xl font-bold text-purple-600">{summary.premiumUsers}</div>
              <div className="text-sm text-gray-500">Premium</div>
            </div>
            <div className="bg-white rounded-lg shadow p-4">
              <div className="text-2xl font-bold text-pink-600">{summary.totalMatches}</div>
              <div className="text-sm text-gray-500">Matches</div>
            </div>
            <div className="bg-white rounded-lg shadow p-4">
              <div className="text-2xl font-bold text-indigo-600">{summary.totalRealMessages}</div>
              <div className="text-sm text-gray-500">Real Msgs</div>
            </div>
            <div className="bg-white rounded-lg shadow p-4">
              <div className="text-2xl font-bold text-orange-600">{summary.totalMuseInteractions}</div>
              <div className="text-sm text-gray-500">Muse Msgs</div>
            </div>
            <div className="bg-white rounded-lg shadow p-4">
              <div className="text-2xl font-bold text-teal-600">{summary.totalTTSPlays}</div>
              <div className="text-sm text-gray-500">TTS Plays</div>
            </div>
          </div>
        )}

        {/* Search and Controls */}
        <div className="bg-white rounded-lg shadow mb-6 p-4">
          <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
            <div className="relative w-full md:w-96">
              <input
                type="text"
                placeholder="Search by name or email..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <svg className="absolute left-3 top-2.5 h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <button
              onClick={fetchUsers}
              disabled={loading}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center gap-2"
            >
              {loading ? (
                <svg className="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
              ) : (
                <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
              )}
              Refresh
            </button>
          </div>
        </div>

        {/* Error State */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <p className="text-red-700">{error}</p>
          </div>
        )}

        {/* Users Table */}
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th
                    className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('name')}
                  >
                    User <SortIcon field="name" />
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Location
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Languages
                  </th>
                  <th
                    className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('matchCount')}
                  >
                    Matches <SortIcon field="matchCount" />
                  </th>
                  <th
                    className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('realMessages')}
                  >
                    Real Msgs <SortIcon field="realMessages" />
                  </th>
                  <th
                    className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('museInteractions')}
                  >
                    Muse Msgs <SortIcon field="museInteractions" />
                  </th>
                  <th
                    className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('ttsPlays')}
                  >
                    TTS <SortIcon field="ttsPlays" />
                  </th>
                  <th
                    className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('lastActive')}
                  >
                    Last Active <SortIcon field="lastActive" />
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {loading && users.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="px-4 py-8 text-center text-gray-500">
                      <svg className="animate-spin h-8 w-8 mx-auto mb-2 text-blue-500" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                      </svg>
                      Loading users...
                    </td>
                  </tr>
                ) : sortedUsers.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="px-4 py-8 text-center text-gray-500">
                      No users found
                    </td>
                  </tr>
                ) : (
                  sortedUsers.map((user) => (
                    <tr
                      key={user.id}
                      className="hover:bg-gray-50 cursor-pointer"
                      onClick={() => setSelectedUser(user)}
                    >
                      <td className="px-4 py-4">
                        <div className="flex items-center">
                          <div className="flex-shrink-0 h-10 w-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-medium">
                            {user.firstName?.[0]?.toUpperCase() || '?'}
                          </div>
                          <div className="ml-3">
                            <div className="text-sm font-medium text-gray-900">
                              {user.firstName} {user.lastName}
                            </div>
                            <div className="text-sm text-gray-500">{user.email}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <div className="text-sm text-gray-900">{user.location || 'N/A'}</div>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex flex-col gap-1">
                          {user.isActiveToday ? (
                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                              Online
                            </span>
                          ) : user.isActiveWeek ? (
                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-yellow-100 text-yellow-800">
                              This week
                            </span>
                          ) : (
                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                              Inactive
                            </span>
                          )}
                          <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                            user.subscriptionTier === 'premium' ? 'bg-purple-100 text-purple-800' :
                            user.subscriptionTier === 'pro' ? 'bg-blue-100 text-blue-800' :
                            'bg-gray-100 text-gray-600'
                          }`}>
                            {user.subscriptionTier}
                          </span>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <div className="text-sm">
                          <div className="text-gray-900">Native: {user.nativeLanguage || 'N/A'}</div>
                          <div className="text-gray-500 text-xs">
                            Learning: {user.learningLanguages?.join(', ') || 'None'}
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-center">
                        <span className={`text-lg font-semibold ${user.matchCount > 0 ? 'text-pink-600' : 'text-gray-400'}`}>
                          {user.matchCount}
                        </span>
                      </td>
                      <td className="px-4 py-4 text-center">
                        <div className="flex flex-col items-center">
                          <span className={`text-lg font-semibold ${(user.realMessagesSent + user.realMessagesReceived) > 0 ? 'text-indigo-600' : 'text-gray-400'}`}>
                            {user.realMessagesSent + user.realMessagesReceived}
                          </span>
                          <span className="text-xs text-gray-400">
                            {user.realMessagesSent}↑ {user.realMessagesReceived}↓
                          </span>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-center">
                        <span className={`text-lg font-semibold ${user.museInteractions > 0 ? 'text-orange-600' : 'text-gray-400'}`}>
                          {user.museInteractions}
                        </span>
                      </td>
                      <td className="px-4 py-4 text-center">
                        <span className={`text-lg font-semibold ${user.ttsPlaysUsed > 0 ? 'text-teal-600' : 'text-gray-400'}`}>
                          {user.ttsPlaysUsed}
                        </span>
                      </td>
                      <td className="px-4 py-4 text-sm text-gray-500">
                        {formatDate(user.lastActive)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* User Detail Modal */}
        {selectedUser && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" onClick={() => setSelectedUser(null)}>
            <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto" onClick={e => e.stopPropagation()}>
              <div className="p-6">
                <div className="flex justify-between items-start mb-6">
                  <div className="flex items-center">
                    <div className="h-16 w-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white text-2xl font-medium">
                      {selectedUser.firstName?.[0]?.toUpperCase() || '?'}
                    </div>
                    <div className="ml-4">
                      <h2 className="text-xl font-bold text-gray-900">
                        {selectedUser.firstName} {selectedUser.lastName}
                      </h2>
                      <p className="text-gray-500">{selectedUser.email}</p>
                    </div>
                  </div>
                  <button
                    onClick={() => setSelectedUser(null)}
                    className="text-gray-400 hover:text-gray-600"
                  >
                    <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>

                <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-6">
                  <div className="bg-gray-50 rounded-lg p-4">
                    <div className="text-sm text-gray-500">Subscription</div>
                    <div className="text-lg font-semibold capitalize">{selectedUser.subscriptionTier}</div>
                  </div>
                  <div className="bg-gray-50 rounded-lg p-4">
                    <div className="text-sm text-gray-500">Member Since</div>
                    <div className="text-lg font-semibold">{new Date(selectedUser.createdAt).toLocaleDateString()}</div>
                  </div>
                  <div className="bg-gray-50 rounded-lg p-4">
                    <div className="text-sm text-gray-500">Location</div>
                    <div className="text-lg font-semibold">{selectedUser.location || 'Not set'}</div>
                  </div>
                  <div className="bg-gray-50 rounded-lg p-4">
                    <div className="text-sm text-gray-500">Native Language</div>
                    <div className="text-lg font-semibold">{selectedUser.nativeLanguage || 'Not set'}</div>
                  </div>
                  <div className="bg-gray-50 rounded-lg p-4 md:col-span-2">
                    <div className="text-sm text-gray-500">Learning</div>
                    <div className="text-lg font-semibold">{selectedUser.learningLanguages?.join(', ') || 'None'}</div>
                  </div>
                </div>

                <h3 className="text-lg font-semibold text-gray-900 mb-4">Activity Statistics</h3>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="bg-pink-50 rounded-lg p-4 text-center">
                    <div className="text-3xl font-bold text-pink-600">{selectedUser.matchCount}</div>
                    <div className="text-sm text-pink-700">Matches</div>
                  </div>
                  <div className="bg-indigo-50 rounded-lg p-4 text-center">
                    <div className="text-3xl font-bold text-indigo-600">{selectedUser.realMessagesSent}</div>
                    <div className="text-sm text-indigo-700">Messages Sent</div>
                  </div>
                  <div className="bg-orange-50 rounded-lg p-4 text-center">
                    <div className="text-3xl font-bold text-orange-600">{selectedUser.museInteractions}</div>
                    <div className="text-sm text-orange-700">Muse Messages</div>
                  </div>
                  <div className="bg-teal-50 rounded-lg p-4 text-center">
                    <div className="text-3xl font-bold text-teal-600">{selectedUser.ttsPlaysUsed}</div>
                    <div className="text-sm text-teal-700">TTS Plays</div>
                  </div>
                </div>

                <div className="mt-6 pt-4 border-t border-gray-200">
                  <div className="flex justify-between text-sm text-gray-500">
                    <span>Last Active: {formatDate(selectedUser.lastActive)}</span>
                    <span>ID: {selectedUser.id.slice(0, 8)}...</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
