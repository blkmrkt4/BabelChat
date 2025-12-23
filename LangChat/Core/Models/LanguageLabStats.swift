import Foundation

// MARK: - Partner Streak

struct PartnerStreak: Codable {
    let partnerId: String
    let partnerName: String
    let partnerPhotoUrl: String?
    let currentStreak: Int
    let longestStreak: Int
    let lastInteractionDate: Date?
    let totalMessages: Int

    enum CodingKeys: String, CodingKey {
        case partnerId = "partner_id"
        case partnerName = "partner_name"
        case partnerPhotoUrl = "partner_photo_url"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastInteractionDate = "last_interaction_date"
        case totalMessages = "total_messages"
    }
}

// MARK: - Daily Activity

struct DailyActivity: Codable {
    let userId: String
    let activityDate: Date
    let messagesSent: Int
    let messagesReceived: Int
    let targetLanguageMessages: Int
    let nativeLanguageMessages: Int
    let practiceMinutes: Int
    let uniquePartners: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case activityDate = "activity_date"
        case messagesSent = "messages_sent"
        case messagesReceived = "messages_received"
        case targetLanguageMessages = "target_language_messages"
        case nativeLanguageMessages = "native_language_messages"
        case practiceMinutes = "practice_minutes"
        case uniquePartners = "unique_partners"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        messagesSent = try container.decodeIfPresent(Int.self, forKey: .messagesSent) ?? 0
        messagesReceived = try container.decodeIfPresent(Int.self, forKey: .messagesReceived) ?? 0
        targetLanguageMessages = try container.decodeIfPresent(Int.self, forKey: .targetLanguageMessages) ?? 0
        nativeLanguageMessages = try container.decodeIfPresent(Int.self, forKey: .nativeLanguageMessages) ?? 0
        practiceMinutes = try container.decodeIfPresent(Int.self, forKey: .practiceMinutes) ?? 0
        uniquePartners = try container.decodeIfPresent(Int.self, forKey: .uniquePartners) ?? 0

        // Parse date string
        let dateString = try container.decode(String.self, forKey: .activityDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        activityDate = formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - Fluency Heat Data

struct FluencyHeatData {
    let currentTemperature: Double  // 0-100 scale
    let trend: Trend
    let weeklyAverage: Double
    let monthlyAverage: Double
    let dailyActivity: [DailyActivity]

    enum Trend: String {
        case rising = "rising"
        case falling = "falling"
        case stable = "stable"

        var emoji: String {
            switch self {
            case .rising: return "🔥"
            case .falling: return "❄️"
            case .stable: return "😊"
            }
        }
    }

    static var empty: FluencyHeatData {
        FluencyHeatData(
            currentTemperature: 0,
            trend: .stable,
            weeklyAverage: 0,
            monthlyAverage: 0,
            dailyActivity: []
        )
    }
}

// MARK: - Learning Pulse Point

struct LearningPulsePoint {
    let date: Date
    let targetLanguagePercent: Double
    let nativeLanguagePercent: Double
    let messageCount: Int

    static var empty: LearningPulsePoint {
        LearningPulsePoint(date: Date(), targetLanguagePercent: 0, nativeLanguagePercent: 0, messageCount: 0)
    }
}

// MARK: - Wrapped Stats (Rolling 12-month)

struct WrappedStats {
    let totalMessages: Int
    let totalPartners: Int
    let totalPracticeMinutes: Int
    let longestStreak: Int
    let currentStreak: Int
    let mostActivePartner: PartnerStreak?
    let topLanguage: String
    let monthlyBreakdown: [MonthStats]
    let achievements: [Achievement]
    let periodStart: Date
    let periodEnd: Date

    struct MonthStats {
        let month: Date
        let messages: Int
        let practiceMinutes: Int
        let targetLanguageMessages: Int
        let nativeLanguageMessages: Int
    }

    struct Achievement: Identifiable {
        let id: String
        let title: String
        let description: String
        let icon: String
        let earnedDate: Date?
        let isEarned: Bool

        static let allAchievements: [Achievement] = [
            Achievement(id: "first_message", title: "First Words", description: "Sent your first message", icon: "bubble.left.fill", earnedDate: nil, isEarned: false),
            Achievement(id: "streak_7", title: "Week Warrior", description: "7-day streak with a partner", icon: "flame.fill", earnedDate: nil, isEarned: false),
            Achievement(id: "streak_30", title: "Monthly Master", description: "30-day streak with a partner", icon: "star.fill", earnedDate: nil, isEarned: false),
            Achievement(id: "messages_100", title: "Centurion", description: "Sent 100 messages", icon: "100.circle.fill", earnedDate: nil, isEarned: false),
            Achievement(id: "messages_500", title: "Chatterbox", description: "Sent 500 messages", icon: "bubble.left.and.bubble.right.fill", earnedDate: nil, isEarned: false),
            Achievement(id: "messages_1000", title: "Wordsmith", description: "Sent 1000 messages", icon: "textformat.abc", earnedDate: nil, isEarned: false),
            Achievement(id: "partners_5", title: "Social Butterfly", description: "Chatted with 5 partners", icon: "person.3.fill", earnedDate: nil, isEarned: false),
            Achievement(id: "target_language_50", title: "Immersion Mode", description: "50% messages in target language", icon: "globe", earnedDate: nil, isEarned: false),
            Achievement(id: "practice_hours_10", title: "Dedicated Learner", description: "10 hours of practice", icon: "clock.fill", earnedDate: nil, isEarned: false),
            Achievement(id: "practice_hours_50", title: "Language Enthusiast", description: "50 hours of practice", icon: "trophy.fill", earnedDate: nil, isEarned: false)
        ]
    }

    static var empty: WrappedStats {
        let now = Date()
        let yearAgo = Calendar.current.date(byAdding: .month, value: -12, to: now) ?? now
        return WrappedStats(
            totalMessages: 0,
            totalPartners: 0,
            totalPracticeMinutes: 0,
            longestStreak: 0,
            currentStreak: 0,
            mostActivePartner: nil,
            topLanguage: "",
            monthlyBreakdown: [],
            achievements: Achievement.allAchievements,
            periodStart: yearAgo,
            periodEnd: now
        )
    }
}

// MARK: - Chat Session (for practice time tracking)

struct ChatSession: Codable {
    let id: String?
    let userId: String
    let conversationId: String
    let startedAt: Date
    var endedAt: Date?
    var messagesCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case conversationId = "conversation_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case messagesCount = "messages_count"
    }
}

// MARK: - Partner Streak Response (from database join)

struct PartnerStreakResponse: Codable {
    let partnerId: String
    let currentStreak: Int
    let longestStreak: Int
    let lastInteractionDate: String?
    let totalMessages: Int
    let streakStartedAt: String?

    enum CodingKeys: String, CodingKey {
        case partnerId = "partner_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastInteractionDate = "last_interaction_date"
        case totalMessages = "total_messages"
        case streakStartedAt = "streak_started_at"
    }
}

// MARK: - Language Lab Data (combined)

struct LanguageLabData {
    var partnerStreaks: [PartnerStreak]
    var dailyActivity: [DailyActivity]
    var fluencyHeat: FluencyHeatData
    var learningPulse: [LearningPulsePoint]
    var wrappedStats: WrappedStats
    var isLoading: Bool
    var error: String?

    static var empty: LanguageLabData {
        LanguageLabData(
            partnerStreaks: [],
            dailyActivity: [],
            fluencyHeat: .empty,
            learningPulse: [],
            wrappedStats: .empty,
            isLoading: false,
            error: nil
        )
    }

    static var loading: LanguageLabData {
        var data = empty
        data.isLoading = true
        return data
    }
}
