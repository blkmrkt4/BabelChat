import Foundation

/// Service responsible for matching users based on language preferences
class MatchingService {

    static let shared = MatchingService()

    private init() {}

    /// Determine if two users can match (hard filters that must pass)
    /// These are dealbreaker criteria - if any fail, users won't be shown as potential matches
    /// - Parameters:
    ///   - user1: First user
    ///   - user2: Second user
    /// - Returns: True if users meet all hard filter requirements
    func canMatch(_ user1: User, _ user2: User) -> Bool {
        // HARD FILTER 1: Language compatibility (existing logic)
        guard areUsersCompatible(user1, user2) else { return false }

        // HARD FILTER 2: Age within acceptable range
        guard isAgeAcceptable(user1, user2) else { return false }

        // HARD FILTER 3: Gender preference match
        guard isGenderPreferenceMatch(user1, user2) else { return false }

        // HARD FILTER 4: Location within acceptable range
        guard isLocationAcceptable(user1, user2) else { return false }

        // HARD FILTER 5: Relationship intent compatibility
        guard hasRelationshipIntentOverlap(user1, user2) else { return false }

        return true
    }

    // MARK: - Hard Filter Functions

    /// Check if ages are mutually acceptable
    private func isAgeAcceptable(_ user1: User, _ user2: User) -> Bool {
        guard let age1 = user1.age, let age2 = user2.age else {
            return true // If age unknown, don't filter out
        }

        let prefs1 = user1.matchingPreferences
        let prefs2 = user2.matchingPreferences

        // Both users must accept each other's age
        let user1AcceptsUser2 = age2 >= prefs1.minAge && age2 <= prefs1.maxAge
        let user2AcceptsUser1 = age1 >= prefs2.minAge && age1 <= prefs2.maxAge

        return user1AcceptsUser2 && user2AcceptsUser1
    }

    /// Check if gender preferences match
    private func isGenderPreferenceMatch(_ user1: User, _ user2: User) -> Bool {
        let prefs1 = user1.matchingPreferences
        let prefs2 = user2.matchingPreferences

        let user1Gender = prefs1.gender
        let user2Gender = prefs2.gender

        // Check if both users' gender preferences accept each other
        let user1AcceptsUser2 = matchesGenderPreference(prefs1.genderPreference, userGender: user1Gender, otherGender: user2Gender)
        let user2AcceptsUser1 = matchesGenderPreference(prefs2.genderPreference, userGender: user2Gender, otherGender: user1Gender)

        return user1AcceptsUser2 && user2AcceptsUser1
    }

    /// Check if location is acceptable based on preferences
    private func isLocationAcceptable(_ user1: User, _ user2: User) -> Bool {
        let prefs1 = user1.matchingPreferences
        let prefs2 = user2.matchingPreferences

        // If either user prefers "anywhere", location is acceptable
        if prefs1.locationPreference == .anywhere || prefs2.locationPreference == .anywhere {
            return true
        }

        // Calculate distance if both have location data
        if let distanceKm = prefs1.distanceKm(to: prefs2) {
            // Check if distance is within both users' max acceptable distance
            if let maxDist1 = prefs1.maxDistanceKm {
                if distanceKm > Double(maxDist1) {
                    return false
                }
            }

            if let maxDist2 = prefs2.maxDistanceKm {
                if distanceKm > Double(maxDist2) {
                    return false
                }
            }
        }

        // Check specific country preferences
        if prefs1.locationPreference == .specificCountries,
           let preferredCountries1 = prefs1.preferredCountries,
           let user2Location = user2.location {
            var matchesCountry = false
            for countryCode in preferredCountries1 {
                if let countryName = Locale.current.localizedString(forRegionCode: countryCode),
                   user2Location.lowercased().contains(countryName.lowercased()) {
                    matchesCountry = true
                    break
                }
            }
            if !matchesCountry {
                return false
            }
        }

        if prefs2.locationPreference == .specificCountries,
           let preferredCountries2 = prefs2.preferredCountries,
           let user1Location = user1.location {
            var matchesCountry = false
            for countryCode in preferredCountries2 {
                if let countryName = Locale.current.localizedString(forRegionCode: countryCode),
                   user1Location.lowercased().contains(countryName.lowercased()) {
                    matchesCountry = true
                    break
                }
            }
            if !matchesCountry {
                return false
            }
        }

        return true
    }

    /// Check if relationship intents have any overlap
    private func hasRelationshipIntentOverlap(_ user1: User, _ user2: User) -> Bool {
        let intents1 = Set(user1.matchingPreferences.relationshipIntents)
        let intents2 = Set(user2.matchingPreferences.relationshipIntents)

        // Must have at least one intent in common
        return !intents1.intersection(intents2).isEmpty
    }

    /// Determine if two users are compatible for matching (language-based)
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
    /// Filters by hard requirements and sorts by match score
    /// - Parameters:
    ///   - user: The user to find matches for
    ///   - candidates: List of potential match candidates
    /// - Returns: Filtered and sorted list of compatible users with scores
    func findMatches(for user: User, from candidates: [User]) -> [(user: User, score: Int, reasons: [String])] {
        // Filter candidates using hard filters
        let compatible = candidates.filter { candidate in
            // Don't match with self
            guard candidate.id != user.id else { return false }

            // Check all hard filters
            return canMatch(user, candidate)
        }

        // Calculate scores for compatible matches
        var scoredMatches: [(user: User, score: Int, reasons: [String])] = []
        for candidate in compatible {
            let result = calculateMatchScore(user, candidate)
            scoredMatches.append((user: candidate, score: result.score, reasons: result.reasons))
        }

        // Sort by score (highest first), then by online status
        return scoredMatches.sorted { match1, match2 in
            if match1.score != match2.score {
                return match1.score > match2.score
            }
            // If scores are equal, prioritize online users
            return match1.user.isOnline && !match2.user.isOnline
        }
    }

    /// Simple version of findMatches that returns just users (for backwards compatibility)
    /// - Parameters:
    ///   - user: The user to find matches for
    ///   - candidates: List of potential match candidates
    /// - Returns: Filtered and sorted list of compatible users
    func findMatchesSimple(for user: User, from candidates: [User]) -> [User] {
        return findMatches(for: user, from: candidates).map { $0.user }
    }

    /// Calculate comprehensive match score between two users using 8-factor system
    /// - Parameters:
    ///   - user1: First user
    ///   - user2: Second user
    /// - Returns: Match score from 0-100 and match reasons
    func calculateMatchScore(_ user1: User, _ user2: User) -> (score: Int, reasons: [String]) {
        var score = 0
        var reasons: [String] = []

        // 1. Language Compatibility (40 points) - HIGHEST PRIORITY
        let languageScore = calculateLanguageScore(user1, user2, reasons: &reasons)
        score += languageScore

        // 2. Proficiency Match (15 points)
        let proficiencyScore = calculateProficiencyScore(user1, user2, reasons: &reasons)
        score += proficiencyScore

        // 3. Age Compatibility (10 points)
        let ageScore = calculateAgeScore(user1, user2, reasons: &reasons)
        score += ageScore

        // 4. Distance/Location (10 points)
        let distanceScore = calculateDistanceScore(user1, user2, reasons: &reasons)
        score += distanceScore

        // 5. Relationship Intent (10 points)
        let intentScore = calculateIntentScore(user1, user2, reasons: &reasons)
        score += intentScore

        // 6. Gender Preference (5 points)
        let genderScore = calculateGenderScore(user1, user2, reasons: &reasons)
        score += genderScore

        // 7. Travel Destination Match (5 points)
        let travelScore = calculateTravelScore(user1, user2, reasons: &reasons)
        score += travelScore

        // 8. Regional/Cultural Preference (5 points)
        let regionalScore = calculateRegionalScore(user1, user2, reasons: &reasons)
        score += regionalScore

        return (min(score, 100), reasons)
    }

    // MARK: - Individual Scoring Functions

    /// 1. Language Compatibility Score (0-40 points)
    private func calculateLanguageScore(_ user1: User, _ user2: User, reasons: inout [String]) -> Int {
        if hasPrimaryMatch(user1, user2) {
            reasons.append("Perfect language exchange match!")
            return 40
        }
        if hasSecondaryMatch(user1, user2) {
            reasons.append("Learning the same language")
            return 25
        }
        return 0
    }

    /// 2. Proficiency Match Score (0-15 points)
    private func calculateProficiencyScore(_ user1: User, _ user2: User, reasons: inout [String]) -> Int {
        let user1LearningLanguages = Set(user1.learningLanguages.map { $0.language })
        let user2LearningLanguages = Set(user2.learningLanguages.map { $0.language })
        let commonLanguages = user1LearningLanguages.intersection(user2LearningLanguages)

        guard !commonLanguages.isEmpty else { return 0 }

        var maxScore = 0
        for language in commonLanguages {
            if let user1Lang = user1.learningLanguages.first(where: { $0.language == language }),
               let user2Lang = user2.learningLanguages.first(where: { $0.language == language }) {
                let proficiencyDiff = abs(user1Lang.proficiency.ordinalValue - user2Lang.proficiency.ordinalValue)
                let score = max(0, 15 - (proficiencyDiff * 5))
                if score > maxScore {
                    maxScore = score
                    if proficiencyDiff <= 1 {
                        reasons.append("Similar proficiency level")
                    }
                }
            }
        }

        return maxScore
    }

    /// 3. Age Compatibility Score (0-10 points)
    private func calculateAgeScore(_ user1: User, _ user2: User, reasons: inout [String]) -> Int {
        guard let age1 = user1.age, let age2 = user2.age else { return 5 } // Neutral score if age unknown

        let ageDiff = abs(age1 - age2)

        // Check if within each user's preferred age range
        let user1Prefs = user1.matchingPreferences
        let user2Prefs = user2.matchingPreferences

        let user1AcceptsUser2 = age2 >= user1Prefs.minAge && age2 <= user1Prefs.maxAge
        let user2AcceptsUser1 = age1 >= user2Prefs.minAge && age1 <= user2Prefs.maxAge

        guard user1AcceptsUser2 && user2AcceptsUser1 else { return 0 }

        if ageDiff <= 3 {
            reasons.append("Very close in age")
            return 10
        }
        if ageDiff <= 5 { return 8 }
        if ageDiff <= 10 {
            reasons.append("Similar age range")
            return 5
        }
        if ageDiff <= 15 { return 2 }

        return 0
    }

    /// 4. Distance/Location Score (0-10 points)
    private func calculateDistanceScore(_ user1: User, _ user2: User, reasons: inout [String]) -> Int {
        let prefs1 = user1.matchingPreferences
        let prefs2 = user2.matchingPreferences

        // If both prefer "anywhere", give neutral positive score
        if prefs1.locationPreference == .anywhere && prefs2.locationPreference == .anywhere {
            return 5
        }

        // Calculate distance if both have location data
        if let distanceKm = prefs1.distanceKm(to: prefs2) {
            // Local matches
            if distanceKm <= 25 {
                reasons.append("Local match - great for meetups!")
                return 10
            }
            // Regional matches
            if distanceKm <= 100 {
                reasons.append("Nearby location")
                return 8
            }
            // Same country (approximate - within 500km)
            if distanceKm <= 500 {
                return 5
            }
            // Long distance
            return 2
        }

        // If no location data, give neutral score
        return 5
    }

    /// 5. Relationship Intent Score (0-10 points)
    private func calculateIntentScore(_ user1: User, _ user2: User, reasons: inout [String]) -> Int {
        let intents1 = Set(user1.matchingPreferences.relationshipIntents)
        let intents2 = Set(user2.matchingPreferences.relationshipIntents)
        let overlap = intents1.intersection(intents2)

        guard !overlap.isEmpty else { return 0 }

        if overlap.contains(.openToDating) {
            reasons.append("Both open to dating")
            return 10
        }
        if overlap.contains(.friendship) {
            reasons.append("Both want friendship")
            return 8
        }
        if overlap.contains(.languagePracticeOnly) {
            reasons.append("Focused on language practice")
            return 5
        }

        return 0
    }

    /// 6. Gender Preference Score (0-5 points)
    private func calculateGenderScore(_ user1: User, _ user2: User, reasons: inout [String]) -> Int {
        let prefs1 = user1.matchingPreferences
        let prefs2 = user2.matchingPreferences

        // Both have "all" preference
        if prefs1.genderPreference == .all && prefs2.genderPreference == .all {
            return 5
        }

        // Check if genders match preferences
        let user1Gender = prefs1.gender
        let user2Gender = prefs2.gender

        let user1AcceptsUser2 = matchesGenderPreference(prefs1.genderPreference, userGender: user1Gender, otherGender: user2Gender)
        let user2AcceptsUser1 = matchesGenderPreference(prefs2.genderPreference, userGender: user2Gender, otherGender: user1Gender)

        if user1AcceptsUser2 && user2AcceptsUser1 {
            return 5
        }

        return 0
    }

    /// 7. Travel Destination Score (0-5 points)
    private func calculateTravelScore(_ user1: User, _ user2: User, reasons: inout [String]) -> Int {
        let prefs1 = user1.matchingPreferences
        let prefs2 = user2.matchingPreferences

        var score = 0

        // User1 traveling to User2's location
        if let travel1 = prefs1.travelDestination, travel1.isActive,
           let user2Location = user2.location,
           user2Location.lowercased().contains(travel1.country.lowercased()) ||
           (travel1.city != nil && user2Location.lowercased().contains(travel1.city!.lowercased())) {
            reasons.append("Traveling to their city!")
            score += 5
        }

        // User2 traveling to User1's location
        if let travel2 = prefs2.travelDestination, travel2.isActive,
           let user1Location = user1.location,
           user1Location.lowercased().contains(travel2.country.lowercased()) ||
           (travel2.city != nil && user1Location.lowercased().contains(travel2.city!.lowercased())) {
            reasons.append("They're traveling to your city!")
            score += 5
        }

        return min(score, 5)
    }

    /// 8. Regional/Cultural Preference Score (0-5 points)
    private func calculateRegionalScore(_ user1: User, _ user2: User, reasons: inout [String]) -> Int {
        let prefs1 = user1.matchingPreferences
        let prefs2 = user2.matchingPreferences

        var score = 0

        // Check if User2 is a native speaker from User1's preferred region
        if let regionals1 = prefs1.regionalLanguagePreferences {
            for regional in regionals1 {
                if user2.nativeLanguage.language == regional.language {
                    // Check if user2's location matches preferred countries
                    if let user2Location = user2.location {
                        for countryCode in regional.preferredCountries {
                            if let countryName = Locale.current.localizedString(forRegionCode: countryCode),
                               user2Location.lowercased().contains(countryName.lowercased()) {
                                reasons.append("Native speaker from your preferred region")
                                score += 5
                                break
                            }
                        }
                    }
                }
            }
        }

        // Check if User1 is a native speaker from User2's preferred region
        if let regionals2 = prefs2.regionalLanguagePreferences {
            for regional in regionals2 {
                if user1.nativeLanguage.language == regional.language {
                    if let user1Location = user1.location {
                        for countryCode in regional.preferredCountries {
                            if let countryName = Locale.current.localizedString(forRegionCode: countryCode),
                               user1Location.lowercased().contains(countryName.lowercased()) {
                                score += 5
                                break
                            }
                        }
                    }
                }
            }
        }

        return min(score, 5)
    }

    // MARK: - Helper Methods

    /// Check if gender matches preference
    private func matchesGenderPreference(_ preference: GenderPreference, userGender: Gender, otherGender: Gender) -> Bool {
        switch preference {
        case .all:
            return true
        case .sameOnly:
            return userGender == otherGender
        case .differentOnly:
            return userGender != otherGender
        }
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
