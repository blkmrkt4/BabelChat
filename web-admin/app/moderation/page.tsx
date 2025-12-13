'use client'

import { useEffect, useState } from 'react'
import { ReportWithProfiles } from '@/lib/supabase'
import Image from 'next/image'

type StatusFilter = 'all' | 'pending' | 'reviewed' | 'resolved'
type TabType = 'reports' | 'feedback'

interface Feedback {
  id: string
  user_id: string | null
  type: string
  message: string
  app_version: string | null
  device_info: string | null
  status: string
  admin_notes: string | null
  reviewed_at: string | null
  created_at: string
  user?: {
    id: string
    first_name: string
    last_name: string
    profile_photos: string[]
  }
}

export default function ModerationPage() {
  const [activeTab, setActiveTab] = useState<TabType>('reports')
  const [reports, setReports] = useState<ReportWithProfiles[]>([])
  const [filteredReports, setFilteredReports] = useState<ReportWithProfiles[]>([])
  const [feedback, setFeedback] = useState<Feedback[]>([])
  const [filteredFeedback, setFilteredFeedback] = useState<Feedback[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
  const [updatingId, setUpdatingId] = useState<string | null>(null)
  const [deletingId, setDeletingId] = useState<string | null>(null)

  useEffect(() => {
    loadReports()
    loadFeedback()
  }, [])

  useEffect(() => {
    if (statusFilter === 'all') {
      setFilteredReports(reports)
      setFilteredFeedback(feedback)
    } else {
      setFilteredReports(reports.filter(r => r.status === statusFilter))
      setFilteredFeedback(feedback.filter(f => f.status === statusFilter))
    }
  }, [statusFilter, reports, feedback])

  async function loadReports() {
    try {
      setLoading(true)
      const response = await fetch('/api/reports')
      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to load reports')
      }

      setReports(result.data || [])
      setFilteredReports(result.data || [])
    } catch (error) {
      console.error('Failed to load reports:', error)
    } finally {
      setLoading(false)
    }
  }

  async function loadFeedback() {
    try {
      const response = await fetch('/api/feedback')
      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to load feedback')
      }

      setFeedback(result.data || [])
      setFilteredFeedback(result.data || [])
    } catch (error) {
      console.error('Failed to load feedback:', error)
    }
  }

  async function handleStatusUpdate(reportId: string, newStatus: 'pending' | 'reviewed' | 'resolved') {
    try {
      setUpdatingId(reportId)

      const response = await fetch('/api/reports', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reportId, status: newStatus })
      })

      if (!response.ok) {
        const result = await response.json()
        throw new Error(result.error || 'Failed to update status')
      }

      setReports(prev => prev.map(r =>
        r.id === reportId
          ? { ...r, status: newStatus, reviewed_at: new Date().toISOString() }
          : r
      ))
    } catch (error) {
      console.error('Failed to update report status:', error)
      alert('Failed to update report status')
    } finally {
      setUpdatingId(null)
    }
  }

  async function handleFeedbackStatusUpdate(feedbackId: string, newStatus: string) {
    try {
      setUpdatingId(feedbackId)

      const response = await fetch('/api/feedback', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ feedbackId, status: newStatus })
      })

      if (!response.ok) {
        const result = await response.json()
        throw new Error(result.error || 'Failed to update status')
      }

      setFeedback(prev => prev.map(f =>
        f.id === feedbackId
          ? { ...f, status: newStatus, reviewed_at: new Date().toISOString() }
          : f
      ))
    } catch (error) {
      console.error('Failed to update feedback status:', error)
      alert('Failed to update feedback status')
    } finally {
      setUpdatingId(null)
    }
  }

  async function handleDeletePhoto(report: ReportWithProfiles) {
    if (!confirm(`Delete this photo from ${report.reported?.first_name}'s profile? This cannot be undone.`)) {
      return
    }

    try {
      setDeletingId(report.id)

      const response = await fetch('/api/reports', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          reportId: report.id,
          userId: report.reported_id,
          photoUrl: report.photo_url
        })
      })

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Failed to delete photo')
      }

      // Update local state - mark as resolved and clear photo_url
      setReports(prev => prev.map(r =>
        r.id === report.id
          ? { ...r, status: 'resolved', reviewed_at: new Date().toISOString(), photo_url: null }
          : r
      ))

      alert(`Photo deleted. User has ${result.remainingPhotos} photo(s) remaining.`)
    } catch (error) {
      console.error('Failed to delete photo:', error)
      alert('Failed to delete photo')
    } finally {
      setDeletingId(null)
    }
  }

  const reportStats = {
    total: reports.length,
    pending: reports.filter(r => r.status === 'pending').length,
    reviewed: reports.filter(r => r.status === 'reviewed').length,
    resolved: reports.filter(r => r.status === 'resolved').length,
  }

  const feedbackStats = {
    total: feedback.length,
    pending: feedback.filter(f => f.status === 'pending').length,
    reviewed: feedback.filter(f => f.status === 'reviewed').length,
    featureRequests: feedback.filter(f => f.type === 'feature_request').length,
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-lg text-gray-600">Loading...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <div className="max-w-6xl mx-auto space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <h1 className="text-xl font-bold">Content Moderation</h1>
            {/* Main Tabs */}
            <div className="flex gap-1 bg-gray-100 p-1 rounded-lg">
              <button
                onClick={() => setActiveTab('reports')}
                className={`px-3 py-1 text-sm rounded transition ${
                  activeTab === 'reports'
                    ? 'bg-white shadow text-gray-900 font-medium'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                Reports ({reportStats.total})
              </button>
              <button
                onClick={() => setActiveTab('feedback')}
                className={`px-3 py-1 text-sm rounded transition ${
                  activeTab === 'feedback'
                    ? 'bg-white shadow text-gray-900 font-medium'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                Feedback ({feedbackStats.total})
              </button>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {activeTab === 'reports' ? (
              <div className="flex gap-2 text-xs">
                <span className="px-2 py-1 bg-yellow-100 text-yellow-700 rounded">{reportStats.pending} pending</span>
                <span className="px-2 py-1 bg-purple-100 text-purple-700 rounded">{reportStats.reviewed} reviewed</span>
                <span className="px-2 py-1 bg-green-100 text-green-700 rounded">{reportStats.resolved} resolved</span>
              </div>
            ) : (
              <div className="flex gap-2 text-xs">
                <span className="px-2 py-1 bg-yellow-100 text-yellow-700 rounded">{feedbackStats.pending} pending</span>
                <span className="px-2 py-1 bg-blue-100 text-blue-700 rounded">{feedbackStats.featureRequests} features</span>
              </div>
            )}
            <button
              onClick={() => { loadReports(); loadFeedback(); }}
              className="px-3 py-1.5 text-sm bg-gray-200 text-gray-700 rounded hover:bg-gray-300 transition"
            >
              Refresh
            </button>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-1 bg-gray-100 p-1 rounded-lg w-fit">
          {(['all', 'pending', 'reviewed', 'resolved'] as StatusFilter[]).map((filter) => (
            <button
              key={filter}
              onClick={() => setStatusFilter(filter)}
              className={`px-3 py-1 text-sm rounded transition ${
                statusFilter === filter
                  ? 'bg-white shadow text-gray-900 font-medium'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              {filter.charAt(0).toUpperCase() + filter.slice(1)}
            </button>
          ))}
        </div>

        {/* Reports Table */}
        {activeTab === 'reports' && (filteredReports.length === 0 ? (
          <div className="bg-white rounded-lg shadow-sm p-8 text-center text-gray-500">
            No reports found
          </div>
        ) : (
          <div className="bg-white rounded-lg shadow-sm overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-xs text-gray-500 uppercase border-b">
                <tr>
                  <th className="px-3 py-2 text-left">Photo</th>
                  <th className="px-3 py-2 text-left">Reason</th>
                  <th className="px-3 py-2 text-left">Reported User</th>
                  <th className="px-3 py-2 text-left">Reporter</th>
                  <th className="px-3 py-2 text-left">Status</th>
                  <th className="px-3 py-2 text-left">Date</th>
                  <th className="px-3 py-2 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredReports.map((report) => (
                  <tr key={report.id} className="hover:bg-gray-50">
                    {/* Photo */}
                    <td className="px-3 py-2">
                      {report.photo_url ? (
                        <div className="relative w-12 h-12 bg-gray-200 rounded overflow-hidden">
                          <Image
                            src={report.photo_url}
                            alt="Reported"
                            fill
                            className="object-cover"
                            unoptimized
                          />
                        </div>
                      ) : (
                        <div className="w-12 h-12 bg-gray-100 rounded flex items-center justify-center text-gray-400 text-xs">
                          N/A
                        </div>
                      )}
                    </td>

                    {/* Reason */}
                    <td className="px-3 py-2">
                      <div className="font-medium text-gray-900">{report.reason}</div>
                      {report.description && (
                        <div className="text-xs text-gray-500 truncate max-w-xs" title={report.description}>
                          {report.description}
                        </div>
                      )}
                    </td>

                    {/* Reported User */}
                    <td className="px-3 py-2">
                      <div className="font-medium">{report.reported?.first_name} {report.reported?.last_name}</div>
                      <div className="text-xs text-gray-400 font-mono">{report.reported_id?.slice(0, 8)}...</div>
                    </td>

                    {/* Reporter */}
                    <td className="px-3 py-2">
                      <div className="font-medium">{report.reporter?.first_name} {report.reporter?.last_name}</div>
                      <div className="text-xs text-gray-400 font-mono">{report.reporter_id?.slice(0, 8)}...</div>
                    </td>

                    {/* Status */}
                    <td className="px-3 py-2">
                      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium ${
                        report.status === 'pending' ? 'bg-yellow-100 text-yellow-700' :
                        report.status === 'reviewed' ? 'bg-purple-100 text-purple-700' :
                        'bg-green-100 text-green-700'
                      }`}>
                        <span className={
                          report.status === 'pending' ? 'text-yellow-500' :
                          report.status === 'reviewed' ? 'text-purple-500' :
                          'text-green-500'
                        }>●</span>
                        {report.status}
                      </span>
                    </td>

                    {/* Date */}
                    <td className="px-3 py-2 text-gray-500 text-xs">
                      <div>{new Date(report.created_at).toLocaleDateString()}</div>
                      <div>{new Date(report.created_at).toLocaleTimeString()}</div>
                    </td>

                    {/* Actions */}
                    <td className="px-3 py-2">
                      <div className="flex gap-1 justify-end">
                        {report.status !== 'reviewed' && (
                          <button
                            onClick={() => handleStatusUpdate(report.id, 'reviewed')}
                            disabled={updatingId === report.id}
                            className="px-2 py-1 text-xs bg-purple-100 text-purple-700 rounded hover:bg-purple-200 disabled:opacity-50"
                            title="Mark as Reviewed"
                          >
                            Review
                          </button>
                        )}
                        {report.status !== 'resolved' && (
                          <button
                            onClick={() => handleStatusUpdate(report.id, 'resolved')}
                            disabled={updatingId === report.id}
                            className="px-2 py-1 text-xs bg-green-100 text-green-700 rounded hover:bg-green-200 disabled:opacity-50"
                            title="Mark as Resolved"
                          >
                            Resolve
                          </button>
                        )}
                        {report.photo_url && (
                          <button
                            onClick={() => handleDeletePhoto(report)}
                            disabled={deletingId === report.id}
                            className="px-2 py-1 text-xs bg-red-100 text-red-700 rounded hover:bg-red-200 disabled:opacity-50"
                            title="Delete photo from user's profile"
                          >
                            {deletingId === report.id ? '...' : 'Delete'}
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ))}

        {/* Feedback Table */}
        {activeTab === 'feedback' && (filteredFeedback.length === 0 ? (
          <div className="bg-white rounded-lg shadow-sm p-8 text-center text-gray-500">
            No feedback found
          </div>
        ) : (
          <div className="bg-white rounded-lg shadow-sm overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-xs text-gray-500 uppercase border-b">
                <tr>
                  <th className="px-3 py-2 text-left">Type</th>
                  <th className="px-3 py-2 text-left">Message</th>
                  <th className="px-3 py-2 text-left">User</th>
                  <th className="px-3 py-2 text-left">Status</th>
                  <th className="px-3 py-2 text-left">Date</th>
                  <th className="px-3 py-2 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredFeedback.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50">
                    {/* Type */}
                    <td className="px-3 py-2">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                        item.type === 'feature_request' ? 'bg-blue-100 text-blue-700' :
                        item.type === 'bug_report' ? 'bg-red-100 text-red-700' :
                        item.type === 'contact_support' ? 'bg-orange-100 text-orange-700' :
                        'bg-gray-100 text-gray-700'
                      }`}>
                        {item.type === 'feature_request' ? 'Feature' :
                         item.type === 'bug_report' ? 'Bug' :
                         item.type === 'contact_support' ? 'Support' :
                         'General'}
                      </span>
                    </td>

                    {/* Message */}
                    <td className="px-3 py-2">
                      <div className="max-w-md">
                        <div className="text-gray-900 line-clamp-2">{item.message}</div>
                        {item.app_version && (
                          <div className="text-xs text-gray-400 mt-1">v{item.app_version}</div>
                        )}
                      </div>
                    </td>

                    {/* User */}
                    <td className="px-3 py-2">
                      {item.user ? (
                        <>
                          <div className="font-medium">{item.user.first_name} {item.user.last_name}</div>
                          <div className="text-xs text-gray-400 font-mono">{item.user_id?.slice(0, 8)}...</div>
                        </>
                      ) : (
                        <span className="text-gray-400">Anonymous</span>
                      )}
                    </td>

                    {/* Status */}
                    <td className="px-3 py-2">
                      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium ${
                        item.status === 'pending' ? 'bg-yellow-100 text-yellow-700' :
                        item.status === 'reviewed' ? 'bg-purple-100 text-purple-700' :
                        item.status === 'planned' ? 'bg-blue-100 text-blue-700' :
                        item.status === 'completed' ? 'bg-green-100 text-green-700' :
                        'bg-gray-100 text-gray-700'
                      }`}>
                        <span className={
                          item.status === 'pending' ? 'text-yellow-500' :
                          item.status === 'reviewed' ? 'text-purple-500' :
                          item.status === 'planned' ? 'text-blue-500' :
                          item.status === 'completed' ? 'text-green-500' :
                          'text-gray-500'
                        }>●</span>
                        {item.status}
                      </span>
                    </td>

                    {/* Date */}
                    <td className="px-3 py-2 text-gray-500 text-xs">
                      <div>{new Date(item.created_at).toLocaleDateString()}</div>
                      <div>{new Date(item.created_at).toLocaleTimeString()}</div>
                    </td>

                    {/* Actions */}
                    <td className="px-3 py-2">
                      <div className="flex gap-1 justify-end">
                        {item.status !== 'reviewed' && (
                          <button
                            onClick={() => handleFeedbackStatusUpdate(item.id, 'reviewed')}
                            disabled={updatingId === item.id}
                            className="px-2 py-1 text-xs bg-purple-100 text-purple-700 rounded hover:bg-purple-200 disabled:opacity-50"
                          >
                            Review
                          </button>
                        )}
                        {item.type === 'feature_request' && item.status !== 'planned' && (
                          <button
                            onClick={() => handleFeedbackStatusUpdate(item.id, 'planned')}
                            disabled={updatingId === item.id}
                            className="px-2 py-1 text-xs bg-blue-100 text-blue-700 rounded hover:bg-blue-200 disabled:opacity-50"
                          >
                            Plan
                          </button>
                        )}
                        {item.status !== 'completed' && (
                          <button
                            onClick={() => handleFeedbackStatusUpdate(item.id, 'completed')}
                            disabled={updatingId === item.id}
                            className="px-2 py-1 text-xs bg-green-100 text-green-700 rounded hover:bg-green-200 disabled:opacity-50"
                          >
                            Complete
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ))}

        {/* Footer */}
        <div className="text-xs text-gray-400 text-center">
          {activeTab === 'reports'
            ? `${filteredReports.length} report${filteredReports.length !== 1 ? 's' : ''} shown`
            : `${filteredFeedback.length} feedback item${filteredFeedback.length !== 1 ? 's' : ''} shown`}
        </div>
      </div>
    </div>
  )
}
