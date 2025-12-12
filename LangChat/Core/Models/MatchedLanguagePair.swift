import Foundation

/// Represents the language pair that caused two users to match
/// Used to provide context when displaying match cards
struct MatchedLanguagePair: Codable, Equatable {
    /// The native language of the partner (what the current user is learning)
    let partnerNativeLanguage: Language

    /// The learning language of the partner (what the partner is learning)
    let partnerLearningLanguage: Language

    /// The match type (classic or secondary)
    let matchType: MatchType

    init(partnerNativeLanguage: Language, partnerLearningLanguage: Language, matchType: MatchType = .classic) {
        self.partnerNativeLanguage = partnerNativeLanguage
        self.partnerLearningLanguage = partnerLearningLanguage
        self.matchType = matchType
    }
}

enum MatchType: String, Codable {
    case classic    // User A native = User B learning, User B native = User A learning
    case secondary  // Both learning the same language
}
