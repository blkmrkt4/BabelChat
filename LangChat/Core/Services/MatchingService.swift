import Foundation

/// Service responsible for matching users based on language preferences
class MatchingService {

    static let shared = MatchingService()

    private init() {}

    /// Determine if two users are compatible for matching
    /// - Parameters:
    ///   - user1: First user
    ///   - user2: Second user
    /// - Returns: True if users are compatible for matching
    func areUsersCompatible(_ user1: User, _ user2: User) -> Bool {
        // Primary matching: Complementary language pairs
        // User1 native = User2 learning AND User1 learning = User2 native
        if hasPrimaryMatch(user1, user2) {
            return true
        }

        // Secondary matching: Non-native speaker matches
        // Check if both users allow non-native matches and meet proficiency requirements
        if hasSecondaryMatch(user1, user2) {
            return true
        }

        return false
    }

    /// Check for primary (complementary) language match
    /// User A: Native English, Learning French
    /// User B: Native French, Learning English
    /// → Match!
    private func hasPrimaryMatch(_ user1: User, _ user2: User) -> Bool {
        let user1Native = user1.nativeLanguage.language
        let user2Native = user2.nativeLanguage.language

        // Check if user1's native is in user2's learning languages
        let user2LearnsUser1Native = user2.learningLanguages.contains { $0.language == user1Native }

        // Check if user2's native is in user1's learning languages
        let user1LearnsUser2Native = user1.learningLanguages.contains { $0.language == user2Native }

        return user2LearnsUser1Native && user1LearnsUser2Native
    }

    /// Check for secondary (non-native) language match
    /// User A: Native English, Learning French, allows non-native (Intermediate+)
    /// User B: Native Spanish, Learning French (Advanced)
    /// → Match if User B's French proficiency meets User A's requirements!
    private func hasSecondaryMatch(_ user1: User, _ user2: User) -> Bool {
        // Check if either user allows non-native matches
        guard user1.allowNonNativeMatches || user2.allowNonNativeMatches else {
            return false
        }

        // Find common learning languages
        let user1LearningLanguages = Set(user1.learningLanguages.map { $0.language })
        let user2LearningLanguages = Set(user2.learningLanguages.map { $0.language })
        let commonLanguages = user1LearningLanguages.intersection(user2LearningLanguages)

        guard !commonLanguages.isEmpty else {
            return false
        }

        // Check if proficiency levels are compatible for at least one common language
        for language in commonLanguages {
            if let user1Lang = user1.learningLanguages.first(where: { $0.language == language }),
               let user2Lang = user2.learningLanguages.first(where: { $0.language == language }) {

                // If user1 allows non-native matches, check if user2's proficiency is acceptable
                if user1.allowNonNativeMatches {
                    if isProficiencyAcceptable(user2Lang.proficiency,
                                              min: user1.minProficiencyLevel,
                                              max: user1.maxProficiencyLevel) {
                        return true
                    }
                }

                // If user2 allows non-native matches, check if user1's proficiency is acceptable
                if user2.allowNonNativeMatches {
                    if isProficiencyAcceptable(user1Lang.proficiency,
                                              min: user2.minProficiencyLevel,
                                              max: user2.maxProficiencyLevel) {
                        return true
                    }
                }
            }
        }

        return false
    }

    /// Check if a proficiency level falls within an acceptable range
    private func isProficiencyAcceptable(_ proficiency: LanguageProficiency,
                                         min: LanguageProficiency,
                                         max: LanguageProficiency) -> Bool {
        let proficiencyValue = proficiency.ordinalValue
        let minValue = min.ordinalValue
        let maxValue = max.ordinalValue

        return proficiencyValue >= minValue && proficiencyValue <= maxValue
    }

    /// Get potential matches for a user from a list of candidates
    /// - Parameters:
    ///   - user: The user to find matches for
    ///   - candidates: List of potential match candidates
    /// - Returns: Filtered list of compatible users
    func findMatches(for user: User, from candidates: [User]) -> [User] {
        return candidates.filter { candidate in
            // Don't match with self
            guard candidate.id != user.id else { return false }

            // Check compatibility
            return areUsersCompatible(user, candidate)
        }
    }

    /// Calculate match score between two users (higher is better)
    /// - Parameters:
    ///   - user1: First user
    ///   - user2: Second user
    /// - Returns: Match score from 0-100
    func calculateMatchScore(_ user1: User, _ user2: User) -> Int {
        var score = 0

        // Primary match (complementary languages) = 100 points
        if hasPrimaryMatch(user1, user2) {
            score += 100
            return score  // Perfect match, return immediately
        }

        // Secondary match (common learning language) = base 60 points
        if hasSecondaryMatch(user1, user2) {
            score += 60

            // Bonus points for proficiency compatibility
            let user1LearningLanguages = Set(user1.learningLanguages.map { $0.language })
            let user2LearningLanguages = Set(user2.learningLanguages.map { $0.language })
            let commonLanguages = user1LearningLanguages.intersection(user2LearningLanguages)

            if !commonLanguages.isEmpty {
                // Add bonus points based on similar proficiency levels
                for language in commonLanguages {
                    if let user1Lang = user1.learningLanguages.first(where: { $0.language == language }),
                       let user2Lang = user2.learningLanguages.first(where: { $0.language == language }) {
                        let proficiencyDiff = abs(user1Lang.proficiency.ordinalValue - user2Lang.proficiency.ordinalValue)
                        // More similar proficiency = higher score (max +20 points)
                        score += max(0, 20 - (proficiencyDiff * 10))
                    }
                }
            }
        }

        return min(score, 100)  // Cap at 100
    }
}

// MARK: - LanguageProficiency Extension
extension LanguageProficiency {
    /// Ordinal value for proficiency comparison
    var ordinalValue: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .native: return 4
        }
    }
}
