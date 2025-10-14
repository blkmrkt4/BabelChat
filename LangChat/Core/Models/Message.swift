import Foundation

struct Message: Codable {
    let id: String
    let senderId: String
    let recipientId: String
    let text: String
    let timestamp: Date
    let isRead: Bool

    // Language learning features (for demo/fallback)
    let originalLanguage: Language?
    let translatedText: String?
    let grammarSuggestions: [String]?
    let alternatives: [String]?
    let culturalNotes: String?

    // Runtime caching (non-Codable, session only)
    private(set) var cachedTranslation: String?
    private(set) var cachedGrammarResult: String? // JSON string
    private(set) var detectedLanguage: Language?
    private(set) var isTranslating: Bool = false
    private(set) var isCheckingGrammar: Bool = false

    var isSentByCurrentUser: Bool {
        // For demo, assume current user has ID "currentUser"
        return senderId == "currentUser"
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(timestamp) {
            formatter.dateFormat = "Yesterday h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }

        return formatter.string(from: timestamp)
    }

    // MARK: - Codable (exclude runtime caching properties)
    enum CodingKeys: String, CodingKey {
        case id, senderId, recipientId, text, timestamp, isRead
        case originalLanguage, translatedText, grammarSuggestions, alternatives, culturalNotes
    }

    // MARK: - Cache Mutation
    mutating func setCachedTranslation(_ translation: String) {
        cachedTranslation = translation
    }

    mutating func setCachedGrammarResult(_ result: String) {
        cachedGrammarResult = result
    }

    mutating func setDetectedLanguage(_ language: Language) {
        detectedLanguage = language
    }

    mutating func setTranslating(_ translating: Bool) {
        isTranslating = translating
    }

    mutating func setCheckingGrammar(_ checking: Bool) {
        isCheckingGrammar = checking
    }
}