import Foundation

struct MatchFilterCategory {
    let id: String
    let displayTitle: String
    let filterFunction: ([Match]) -> [Match]
}

class MatchFilterCategoryBuilder {

    static func buildCategories(
        matches: [Match],
        currentUser: User? = nil
    ) -> [MatchFilterCategory] {
        var categories: [MatchFilterCategory] = []

        // 1. For You (default) - all matches sorted by matchedAt
        categories.append(MatchFilterCategory(
            id: "for_you",
            displayTitle: "matches_filter_all_matches".localized,
            filterFunction: { matches in
                matches.sorted { $0.matchedAt > $1.matchedAt }
            }
        ))

        // 2. Most Talked To - sorted by lastMessageTime
        categories.append(MatchFilterCategory(
            id: "most_talked",
            displayTitle: "matches_filter_most_talked".localized,
            filterFunction: { matches in
                matches.sorted { m1, m2 in
                    let t1 = m1.lastMessageTime ?? .distantPast
                    let t2 = m2.lastMessageTime ?? .distantPast
                    return t1 > t2
                }
            }
        ))

        // 3. Latest Matches - sorted by matchedAt desc
        categories.append(MatchFilterCategory(
            id: "latest",
            displayTitle: "matches_filter_latest".localized,
            filterFunction: { matches in
                matches.sorted { $0.matchedAt > $1.matchedAt }
            }
        ))

        // 4. Local - only if user has lat/lon and >=1 match within 100km
        if let user = currentUser,
           let myLat = user.matchingPreferences.latitude,
           let myLon = user.matchingPreferences.longitude {
            let hasLocalMatch = matches.contains { match in
                guard let otherLat = match.user.matchingPreferences.latitude,
                      let otherLon = match.user.matchingPreferences.longitude else { return false }
                let dist = MatchingPreferences.calculateDistance(from: myLat, lon1: myLon, to: otherLat, lon2: otherLon)
                return dist <= 100
            }
            if hasLocalMatch {
                categories.append(MatchFilterCategory(
                    id: "local",
                    displayTitle: "matches_filter_local".localized,
                    filterFunction: { matches in
                        matches.filter { match in
                            guard let otherLat = match.user.matchingPreferences.latitude,
                                  let otherLon = match.user.matchingPreferences.longitude else { return false }
                            let dist = MatchingPreferences.calculateDistance(from: myLat, lon1: myLon, to: otherLat, lon2: otherLon)
                            return dist <= 100
                        }
                    }
                ))
            }
        }

        // Read intents from UserDefaults (stored as raw enum values)
        let storedIntents = UserDefaults.standard.stringArray(forKey: "relationshipIntents") ?? []
        let storedEnumIntents = storedIntents.compactMap { RelationshipIntent(rawValue: $0) }
        let currentIntent = currentUser?.matchingPreferences.relationshipIntent
        var allIntents = Set(storedEnumIntents)
        if let currentIntent = currentIntent {
            allIntents.insert(currentIntent)
        }

        // 5. Friendship
        if allIntents.contains(.friendship) {
            let hasMatch = matches.contains { $0.user.matchingPreferences.relationshipIntent == .friendship }
            if hasMatch {
                categories.append(MatchFilterCategory(
                    id: "friendship",
                    displayTitle: "intent_friendship".localized,
                    filterFunction: { matches in
                        matches.filter { $0.user.matchingPreferences.relationshipIntent == .friendship }
                    }
                ))
            }
        }

        // 6. Dating
        if allIntents.contains(.openToDating) {
            let hasMatch = matches.contains { $0.user.matchingPreferences.relationshipIntent == .openToDating }
            if hasMatch {
                categories.append(MatchFilterCategory(
                    id: "dating",
                    displayTitle: "matches_filter_potential_dating".localized,
                    filterFunction: { matches in
                        matches.filter { $0.user.matchingPreferences.relationshipIntent == .openToDating }
                    }
                ))
            }
        }

        // 7. Networking
        if allIntents.contains(.networking) {
            let hasMatch = matches.contains { $0.user.matchingPreferences.relationshipIntent == .networking }
            if hasMatch {
                categories.append(MatchFilterCategory(
                    id: "networking",
                    displayTitle: "intent_networking".localized,
                    filterFunction: { matches in
                        matches.filter { $0.user.matchingPreferences.relationshipIntent == .networking }
                    }
                ))
            }
        }

        // 8. Language Learning chips - one per user's learning language
        let learningLanguages = currentUserLearningLanguages()
        for language in learningLanguages {
            let hasMatch = matches.contains { $0.user.nativeLanguage.language == language }
            if hasMatch {
                let title = String(format: "matches_filter_language_learning".localized, language.name)
                categories.append(MatchFilterCategory(
                    id: "lang_\(language.code)",
                    displayTitle: title,
                    filterFunction: { matches in
                        matches.filter { $0.user.nativeLanguage.language == language }
                    }
                ))
            }
        }

        return categories
    }

    private static func currentUserLearningLanguages() -> [Language] {
        guard let userLanguagesData = UserDefaults.standard.data(forKey: "userLanguages"),
              let userLanguageData = try? JSONDecoder().decode(UserLanguageData.self, from: userLanguagesData) else {
            return []
        }
        return userLanguageData.learningLanguages.map { $0.language }
    }
}
