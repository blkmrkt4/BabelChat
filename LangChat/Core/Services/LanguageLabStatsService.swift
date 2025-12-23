import Foundation
import Supabase

/// Service for fetching and managing Language Lab statistics
class LanguageLabStatsService {

    // MARK: - Singleton
    static let shared = LanguageLabStatsService()

    private let supabase = SupabaseService.shared

    // MARK: - Cache
    private var cachedData: LanguageLabData?
    private var lastFetchTime: Date?
    private let cacheValidityInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Current Chat Session
    private var currentSession: ChatSession?
    private var sessionTimer: Timer?

    private init() {}

    // MARK: - Public Methods

    /// Fetch all Language Lab data
    func fetchAllData() async throws -> LanguageLabData {
        // Check cache first
        if let cached = cachedData,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheValidityInterval {
            return cached
        }

        guard let userId = supabase.currentUserId?.uuidString else {
            throw LanguageLabError.notAuthenticated
        }

        // Fetch all data in parallel
        async let streaks = fetchPartnerStreaks(userId: userId)
        async let activity = fetchDailyActivity(userId: userId, days: 30)
        async let wrapped = fetchWrappedStats(userId: userId)

        let streaksResult = try await streaks
        let activityResult = try await activity

        // Calculate fluency heat from activity
        let fluencyHeat = calculateFluencyHeat(from: activityResult)

        // Calculate learning pulse from activity
        let learningPulse = calculateLearningPulse(from: activityResult)

        let data = LanguageLabData(
            partnerStreaks: streaksResult,
            dailyActivity: activityResult,
            fluencyHeat: fluencyHeat,
            learningPulse: learningPulse,
            wrappedStats: try await wrapped,
            isLoading: false,
            error: nil
        )

        // Update cache
        cachedData = data
        lastFetchTime = Date()

        return data
    }

    /// Force refresh (bypasses cache)
    func forceRefresh() async throws -> LanguageLabData {
        cachedData = nil
        lastFetchTime = nil
        return try await fetchAllData()
    }

    /// Clear cache
    func clearCache() {
        cachedData = nil
        lastFetchTime = nil
    }

    // MARK: - Partner Streaks

    private func fetchPartnerStreaks(userId: String) async throws -> [PartnerStreak] {
        // Fetch streaks with partner profile info
        let response: [PartnerStreakWithProfile] = try await supabase.client
            .from("partner_streaks")
            .select("""
                partner_id,
                current_streak,
                longest_streak,
                last_interaction_date,
                total_messages,
                streak_started_at,
                profiles!partner_streaks_partner_id_fkey(
                    display_name,
                    photos
                )
            """)
            .eq("user_id", value: userId)
            .order("current_streak", ascending: false)
            .execute()
            .value

        return response.map { streak in
            PartnerStreak(
                partnerId: streak.partnerId,
                partnerName: streak.profiles?.displayName ?? "Partner",
                partnerPhotoUrl: streak.profiles?.photos?.first,
                currentStreak: streak.currentStreak,
                longestStreak: streak.longestStreak,
                lastInteractionDate: streak.lastInteractionDateParsed,
                totalMessages: streak.totalMessages
            )
        }
    }

    // MARK: - Daily Activity

    private func fetchDailyActivity(userId: String, days: Int) async throws -> [DailyActivity] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let response: [DailyActivity] = try await supabase.client
            .from("user_daily_activity")
            .select()
            .eq("user_id", value: userId)
            .gte("activity_date", value: dateFormatter.string(from: startDate))
            .order("activity_date", ascending: true)
            .execute()
            .value

        return response
    }

    // MARK: - Fluency Heat Calculation

    private func calculateFluencyHeat(from activity: [DailyActivity]) -> FluencyHeatData {
        guard !activity.isEmpty else {
            return .empty
        }

        // Last 7 days for weekly average
        let lastWeek = activity.suffix(7)
        let weeklyMessages = lastWeek.reduce(0) { $0 + $1.messagesSent + $1.messagesReceived }
        let weeklyAverage = Double(weeklyMessages) / 7.0

        // Last 30 days for monthly average
        let monthlyMessages = activity.reduce(0) { $0 + $1.messagesSent + $1.messagesReceived }
        let monthlyAverage = Double(monthlyMessages) / Double(max(1, activity.count))

        // Calculate temperature (0-100 scale based on daily activity)
        // Target: 20+ messages per day = 100 degrees
        let recentActivity = activity.suffix(3)
        let recentDaily = recentActivity.isEmpty ? 0 : recentActivity.reduce(0) { $0 + $1.messagesSent + $1.messagesReceived } / recentActivity.count
        let temperature = min(100, Double(recentDaily) * 5) // 20 messages = 100

        // Determine trend
        let trend: FluencyHeatData.Trend
        if weeklyAverage > monthlyAverage * 1.1 {
            trend = .rising
        } else if weeklyAverage < monthlyAverage * 0.9 {
            trend = .falling
        } else {
            trend = .stable
        }

        return FluencyHeatData(
            currentTemperature: temperature,
            trend: trend,
            weeklyAverage: weeklyAverage,
            monthlyAverage: monthlyAverage,
            dailyActivity: activity
        )
    }

    // MARK: - Learning Pulse Calculation

    private func calculateLearningPulse(from activity: [DailyActivity]) -> [LearningPulsePoint] {
        return activity.suffix(7).map { day in
            let total = day.targetLanguageMessages + day.nativeLanguageMessages
            let targetPercent = total > 0 ? Double(day.targetLanguageMessages) / Double(total) * 100 : 0
            let nativePercent = total > 0 ? Double(day.nativeLanguageMessages) / Double(total) * 100 : 0

            return LearningPulsePoint(
                date: day.activityDate,
                targetLanguagePercent: targetPercent,
                nativeLanguagePercent: nativePercent,
                messageCount: day.messagesSent + day.messagesReceived
            )
        }
    }

    // MARK: - Wrapped Stats (Rolling 12 Months)

    private func fetchWrappedStats(userId: String) async throws -> WrappedStats {
        let now = Date()
        let yearAgo = Calendar.current.date(byAdding: .month, value: -12, to: now) ?? now
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Fetch 12 months of activity
        let activity: [DailyActivity] = try await supabase.client
            .from("user_daily_activity")
            .select()
            .eq("user_id", value: userId)
            .gte("activity_date", value: dateFormatter.string(from: yearAgo))
            .order("activity_date", ascending: true)
            .execute()
            .value

        // Fetch all partner streaks for stats
        let streaks: [PartnerStreakWithProfile] = try await supabase.client
            .from("partner_streaks")
            .select("""
                partner_id,
                current_streak,
                longest_streak,
                last_interaction_date,
                total_messages,
                profiles!partner_streaks_partner_id_fkey(
                    display_name,
                    photos
                )
            """)
            .eq("user_id", value: userId)
            .execute()
            .value

        // Calculate totals
        let totalMessages = activity.reduce(0) { $0 + $1.messagesSent }
        let totalPartners = streaks.count
        let totalPracticeMinutes = activity.reduce(0) { $0 + $1.practiceMinutes }

        // Find longest streak
        let longestStreak = streaks.max(by: { $0.longestStreak < $1.longestStreak })?.longestStreak ?? 0

        // Find current streak (max current streak among partners)
        let currentStreak = streaks.max(by: { $0.currentStreak < $1.currentStreak })?.currentStreak ?? 0

        // Find most active partner
        let mostActiveStreak = streaks.max(by: { $0.totalMessages < $1.totalMessages })
        let mostActivePartner: PartnerStreak? = mostActiveStreak.map {
            PartnerStreak(
                partnerId: $0.partnerId,
                partnerName: $0.profiles?.displayName ?? "Partner",
                partnerPhotoUrl: $0.profiles?.photos?.first,
                currentStreak: $0.currentStreak,
                longestStreak: $0.longestStreak,
                lastInteractionDate: $0.lastInteractionDateParsed,
                totalMessages: $0.totalMessages
            )
        }

        // Determine top language
        let targetMessages = activity.reduce(0) { $0 + $1.targetLanguageMessages }
        let nativeMessages = activity.reduce(0) { $0 + $1.nativeLanguageMessages }
        let topLanguage = targetMessages >= nativeMessages ? "Target Language" : "Native Language"

        // Monthly breakdown
        let monthlyBreakdown = calculateMonthlyBreakdown(from: activity)

        // Calculate achievements
        let achievements = calculateAchievements(
            totalMessages: totalMessages,
            totalPartners: totalPartners,
            totalPracticeMinutes: totalPracticeMinutes,
            longestStreak: longestStreak,
            targetLanguagePercent: Double(targetMessages) / Double(max(1, totalMessages)) * 100
        )

        return WrappedStats(
            totalMessages: totalMessages,
            totalPartners: totalPartners,
            totalPracticeMinutes: totalPracticeMinutes,
            longestStreak: longestStreak,
            currentStreak: currentStreak,
            mostActivePartner: mostActivePartner,
            topLanguage: topLanguage,
            monthlyBreakdown: monthlyBreakdown,
            achievements: achievements,
            periodStart: yearAgo,
            periodEnd: now
        )
    }

    private func calculateMonthlyBreakdown(from activity: [DailyActivity]) -> [WrappedStats.MonthStats] {
        let calendar = Calendar.current

        // Group by month
        var monthlyData: [String: (messages: Int, minutes: Int, target: Int, native: Int)] = [:]
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"

        for day in activity {
            let monthKey = monthFormatter.string(from: day.activityDate)
            var current = monthlyData[monthKey] ?? (0, 0, 0, 0)
            current.messages += day.messagesSent
            current.minutes += day.practiceMinutes
            current.target += day.targetLanguageMessages
            current.native += day.nativeLanguageMessages
            monthlyData[monthKey] = current
        }

        // Convert to MonthStats
        return monthlyData.sorted { $0.key < $1.key }.compactMap { key, value in
            guard let date = monthFormatter.date(from: key) else { return nil }
            return WrappedStats.MonthStats(
                month: date,
                messages: value.messages,
                practiceMinutes: value.minutes,
                targetLanguageMessages: value.target,
                nativeLanguageMessages: value.native
            )
        }
    }

    private func calculateAchievements(
        totalMessages: Int,
        totalPartners: Int,
        totalPracticeMinutes: Int,
        longestStreak: Int,
        targetLanguagePercent: Double
    ) -> [WrappedStats.Achievement] {
        var achievements: [WrappedStats.Achievement] = []
        let now = Date()

        // First message
        achievements.append(WrappedStats.Achievement(
            id: "first_message",
            title: "First Words",
            description: "Sent your first message",
            icon: "bubble.left.fill",
            earnedDate: totalMessages > 0 ? now : nil,
            isEarned: totalMessages > 0
        ))

        // Streak achievements
        achievements.append(WrappedStats.Achievement(
            id: "streak_7",
            title: "Week Warrior",
            description: "7-day streak with a partner",
            icon: "flame.fill",
            earnedDate: longestStreak >= 7 ? now : nil,
            isEarned: longestStreak >= 7
        ))

        achievements.append(WrappedStats.Achievement(
            id: "streak_30",
            title: "Monthly Master",
            description: "30-day streak with a partner",
            icon: "star.fill",
            earnedDate: longestStreak >= 30 ? now : nil,
            isEarned: longestStreak >= 30
        ))

        // Message count achievements
        achievements.append(WrappedStats.Achievement(
            id: "messages_100",
            title: "Centurion",
            description: "Sent 100 messages",
            icon: "100.circle.fill",
            earnedDate: totalMessages >= 100 ? now : nil,
            isEarned: totalMessages >= 100
        ))

        achievements.append(WrappedStats.Achievement(
            id: "messages_500",
            title: "Chatterbox",
            description: "Sent 500 messages",
            icon: "bubble.left.and.bubble.right.fill",
            earnedDate: totalMessages >= 500 ? now : nil,
            isEarned: totalMessages >= 500
        ))

        achievements.append(WrappedStats.Achievement(
            id: "messages_1000",
            title: "Wordsmith",
            description: "Sent 1000 messages",
            icon: "textformat.abc",
            earnedDate: totalMessages >= 1000 ? now : nil,
            isEarned: totalMessages >= 1000
        ))

        // Partner achievements
        achievements.append(WrappedStats.Achievement(
            id: "partners_5",
            title: "Social Butterfly",
            description: "Chatted with 5 partners",
            icon: "person.3.fill",
            earnedDate: totalPartners >= 5 ? now : nil,
            isEarned: totalPartners >= 5
        ))

        // Language immersion
        achievements.append(WrappedStats.Achievement(
            id: "target_language_50",
            title: "Immersion Mode",
            description: "50% messages in target language",
            icon: "globe",
            earnedDate: targetLanguagePercent >= 50 ? now : nil,
            isEarned: targetLanguagePercent >= 50
        ))

        // Practice time achievements
        let practiceHours = totalPracticeMinutes / 60
        achievements.append(WrappedStats.Achievement(
            id: "practice_hours_10",
            title: "Dedicated Learner",
            description: "10 hours of practice",
            icon: "clock.fill",
            earnedDate: practiceHours >= 10 ? now : nil,
            isEarned: practiceHours >= 10
        ))

        achievements.append(WrappedStats.Achievement(
            id: "practice_hours_50",
            title: "Language Enthusiast",
            description: "50 hours of practice",
            icon: "trophy.fill",
            earnedDate: practiceHours >= 50 ? now : nil,
            isEarned: practiceHours >= 50
        ))

        return achievements
    }

    // MARK: - Chat Session Tracking

    /// Start a new chat session for practice time tracking
    func startChatSession(conversationId: String) {
        guard let userId = supabase.currentUserId?.uuidString else { return }

        // End any existing session first
        endChatSession()

        currentSession = ChatSession(
            id: nil,
            userId: userId,
            conversationId: conversationId,
            startedAt: Date(),
            endedAt: nil,
            messagesCount: 0
        )

        print("📊 Started chat session for conversation: \(conversationId)")
    }

    /// Increment message count for current session
    func incrementSessionMessageCount() {
        currentSession?.messagesCount += 1
    }

    /// End the current chat session and save to database
    func endChatSession() {
        guard var session = currentSession else { return }

        session.endedAt = Date()

        // Calculate duration in minutes
        let duration = session.endedAt!.timeIntervalSince(session.startedAt) / 60

        // Only save if session was meaningful (at least 1 minute)
        if duration >= 1 {
            Task {
                await saveSession(session)
            }
        }

        currentSession = nil
        print("📊 Ended chat session")
    }

    private func saveSession(_ session: ChatSession) async {
        do {
            // Insert session
            let sessionInsert = ChatSessionInsert(
                userId: session.userId,
                conversationId: session.conversationId,
                startedAt: ISO8601DateFormatter().string(from: session.startedAt),
                endedAt: ISO8601DateFormatter().string(from: session.endedAt ?? Date()),
                messagesCount: session.messagesCount
            )

            try await supabase.client
                .from("chat_sessions")
                .insert(sessionInsert)
                .execute()

            // Update daily activity practice minutes
            let duration = (session.endedAt ?? Date()).timeIntervalSince(session.startedAt) / 60
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let activityUpsert = DailyActivityUpsert(
                userId: session.userId,
                activityDate: dateFormatter.string(from: session.startedAt),
                practiceMinutes: Int(duration)
            )

            try await supabase.client
                .from("user_daily_activity")
                .upsert(activityUpsert)
                .execute()

            // Clear cache so next fetch gets updated data
            clearCache()

            print("📊 Saved chat session: \(Int(duration)) minutes")
        } catch {
            print("❌ Failed to save chat session: \(error)")
        }
    }
}

// MARK: - Insert Structs

private struct ChatSessionInsert: Encodable {
    let userId: String
    let conversationId: String
    let startedAt: String
    let endedAt: String
    let messagesCount: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case conversationId = "conversation_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case messagesCount = "messages_count"
    }
}

private struct DailyActivityUpsert: Encodable {
    let userId: String
    let activityDate: String
    let practiceMinutes: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case activityDate = "activity_date"
        case practiceMinutes = "practice_minutes"
    }
}

// MARK: - Helper Types

private struct PartnerStreakWithProfile: Codable {
    let partnerId: String
    let currentStreak: Int
    let longestStreak: Int
    let lastInteractionDate: String?
    let totalMessages: Int
    let streakStartedAt: String?
    let profiles: ProfileInfo?

    enum CodingKeys: String, CodingKey {
        case partnerId = "partner_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastInteractionDate = "last_interaction_date"
        case totalMessages = "total_messages"
        case streakStartedAt = "streak_started_at"
        case profiles
    }

    struct ProfileInfo: Codable {
        let displayName: String?
        let photos: [String]?

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case photos
        }
    }

    var lastInteractionDateParsed: Date? {
        guard let dateString = lastInteractionDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

// MARK: - Errors

enum LanguageLabError: Error, LocalizedError {
    case notAuthenticated
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to view stats"
        case .fetchFailed(let reason):
            return "Failed to fetch stats: \(reason)"
        }
    }
}
