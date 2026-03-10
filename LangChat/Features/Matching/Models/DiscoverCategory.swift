import Foundation

struct DiscoverCategory {
    let id: String
    let titleKey: String
    let subtitle: String?
    let users: [(user: User, score: Int, reasons: [String])]
}

class DiscoverCategoryBuilder {

    static func buildCategories(
        from scoredProfiles: [(user: User, score: Int, reasons: [String])],
        currentUser: User
    ) -> [DiscoverCategory] {
        var categories: [DiscoverCategory] = []

        // Extract primary learning language name for context-aware headers
        let learningLanguageName = currentUser.learningLanguages.first?.language.name

        // Apply hard filters before building rows
        var filteredProfiles = scoredProfiles

        // Exclude countries the user has blocked
        if currentUser.matchingPreferences.locationPreference == .excludeCountries,
           let excluded = currentUser.matchingPreferences.excludedCountries, !excluded.isEmpty {
            let excludedNames = excluded.compactMap { code in
                Locale(identifier: "en_US").localizedString(forRegionCode: code)?.lowercased()
            }
            filteredProfiles = filteredProfiles.filter { profile in
                guard let location = profile.user.location?.lowercased() else { return true }
                return !excludedNames.contains { location.contains($0) }
            }
        }

        // 1. Top Picks
        if let cat = buildTopPicks(from: filteredProfiles) {
            categories.append(cat)
        }

        // 2. Online Now
        if let cat = buildOnlineNow(from: filteredProfiles) {
            categories.append(cat)
        }

        // 3. Local to You
        if let cat = buildLocal(from: filteredProfiles, currentUser: currentUser) {
            categories.append(cat)
        }

        // 4. Traveling Soon
        if let cat = buildTravelingSoon(from: filteredProfiles, currentUser: currentUser) {
            categories.append(cat)
        }

        // 5. Lives in [Country] (target language countries)
        categories.append(contentsOf: buildTargetCountryRows(from: filteredProfiles, currentUser: currentUser))

        // 6. Intent-based rows
        categories.append(contentsOf: buildIntentRows(from: filteredProfiles, currentUser: currentUser))

        // 7. Proficiency rows
        if let cat = buildProficiencyRow(from: filteredProfiles, currentUser: currentUser) {
            categories.append(cat)
        }

        // 8. Formal/Business
        if let cat = buildLearningContextRow(
            from: filteredProfiles,
            contexts: [.formal],
            id: "business",
            titleKey: "discover_row_business",
            languageName: learningLanguageName
        ) {
            categories.append(cat)
        }

        // 9. Academic
        if let cat = buildLearningContextRow(
            from: filteredProfiles,
            contexts: [.academic],
            id: "academic",
            titleKey: "discover_row_academic",
            languageName: learningLanguageName
        ) {
            categories.append(cat)
        }

        // 10. Casual/Social
        if let cat = buildLearningContextRow(
            from: filteredProfiles,
            contexts: [.casual],
            id: "casual",
            titleKey: "discover_row_casual",
            languageName: learningLanguageName
        ) {
            categories.append(cat)
        }

        // 11. Regular Session Hosts
        if let cat = buildRegularSessionHosts(from: filteredProfiles) {
            categories.append(cat)
        }

        // 12. Global Connections
        if let cat = buildGlobalConnections(from: filteredProfiles, currentUser: currentUser) {
            categories.append(cat)
        }

        return categories
    }

    // MARK: - Category Builders

    private static func buildTopPicks(
        from profiles: [(user: User, score: Int, reasons: [String])]
    ) -> DiscoverCategory? {
        let topPicks = profiles
            .filter { $0.score >= 50 }
            .sorted { $0.score > $1.score }
            .prefix(10)

        guard !topPicks.isEmpty else { return nil }
        return DiscoverCategory(
            id: "top_picks",
            titleKey: "discover_row_top_picks",
            subtitle: nil,
            users: Array(topPicks)
        )
    }

    private static func buildOnlineNow(
        from profiles: [(user: User, score: Int, reasons: [String])]
    ) -> DiscoverCategory? {
        let online = profiles
            .filter { $0.user.isOnline }
            .sorted { $0.score > $1.score }

        guard online.count >= 2 else { return nil }
        return DiscoverCategory(
            id: "online_now",
            titleKey: "discover_row_online_now",
            subtitle: nil,
            users: online
        )
    }

    private static func buildLocal(
        from profiles: [(user: User, score: Int, reasons: [String])],
        currentUser: User
    ) -> DiscoverCategory? {
        let currentPrefs = currentUser.matchingPreferences
        guard let myLat = currentPrefs.latitude, let myLon = currentPrefs.longitude else { return nil }

        var localProfiles: [(user: User, score: Int, reasons: [String], distance: Double)] = []

        for profile in profiles {
            let otherPrefs = profile.user.matchingPreferences
            guard let otherLat = otherPrefs.latitude, let otherLon = otherPrefs.longitude else { continue }
            let dist = MatchingPreferences.calculateDistance(from: myLat, lon1: myLon, to: otherLat, lon2: otherLon)
            let maxDistance = Double(currentPrefs.maxDistanceKm ?? 100)
            if dist <= maxDistance {
                localProfiles.append((profile.user, profile.score, profile.reasons, dist))
            }
        }

        guard !localProfiles.isEmpty else { return nil }

        let sorted = localProfiles
            .sorted { $0.distance < $1.distance }
            .map { (user: $0.user, score: $0.score, reasons: $0.reasons) }

        return DiscoverCategory(
            id: "local",
            titleKey: "discover_row_local",
            subtitle: nil,
            users: sorted
        )
    }

    private static func buildTravelingSoon(
        from profiles: [(user: User, score: Int, reasons: [String])],
        currentUser: User
    ) -> DiscoverCategory? {
        let travelers = profiles.filter { profile in
            guard let travel = profile.user.matchingPreferences.travelDestination,
                  travel.isActive else { return false }
            return true
        }.sorted { p1, p2 in
            // Prioritize those traveling to current user's area
            let myLocation = currentUser.location?.lowercased() ?? ""
            let t1 = p1.user.matchingPreferences.travelDestination
            let t2 = p2.user.matchingPreferences.travelDestination
            let t1MatchesMyArea = t1.map { myLocation.contains($0.countryName.lowercased()) } ?? false
            let t2MatchesMyArea = t2.map { myLocation.contains($0.countryName.lowercased()) } ?? false
            if t1MatchesMyArea != t2MatchesMyArea { return t1MatchesMyArea }
            return p1.score > p2.score
        }

        guard !travelers.isEmpty else { return nil }
        return DiscoverCategory(
            id: "traveling_soon",
            titleKey: "discover_row_traveling",
            subtitle: nil,
            users: travelers
        )
    }

    private static func buildTargetCountryRows(
        from profiles: [(user: User, score: Int, reasons: [String])],
        currentUser: User
    ) -> [DiscoverCategory] {
        // When user has explicitly set preferred countries, show rows for those
        if currentUser.matchingPreferences.locationPreference == .specificCountries,
           let preferredCountries = currentUser.matchingPreferences.preferredCountries,
           !preferredCountries.isEmpty {
            return buildPreferredCountryRows(from: profiles, countryCodes: preferredCountries)
        }

        // Fallback: language→country association rows for discovery
        return buildLanguageCountryRows(from: profiles, currentUser: currentUser)
    }

    /// Build individual "Lives in [Country]" rows for user's preferred countries (up to 3)
    private static func buildPreferredCountryRows(
        from profiles: [(user: User, score: Int, reasons: [String])],
        countryCodes: [String]
    ) -> [DiscoverCategory] {
        var rows: [DiscoverCategory] = []

        for code in countryCodes.prefix(3) {
            guard let countryName = Locale(identifier: "en_US").localizedString(forRegionCode: code) else { continue }
            let countryLower = countryName.lowercased()

            let matching = profiles.filter { profile in
                guard let location = profile.user.location?.lowercased() else { return false }
                return location.contains(countryLower)
            }.sorted { $0.score > $1.score }

            guard !matching.isEmpty else { continue }

            rows.append(DiscoverCategory(
                id: "preferred_country_\(code)",
                titleKey: String(format: "discover_row_lives_in".localized, countryName),
                subtitle: nil,
                users: matching
            ))
        }

        return rows
    }

    /// Fallback: build country rows based on learning language → country associations
    private static func buildLanguageCountryRows(
        from profiles: [(user: User, score: Int, reasons: [String])],
        currentUser: User
    ) -> [DiscoverCategory] {
        for learningLang in currentUser.learningLanguages {
            let countries = learningLang.language.associatedCountries
            guard !countries.isEmpty else { continue }

            let matching = profiles.filter { profile in
                guard let location = profile.user.location else { return false }
                let locationLower = location.lowercased()
                return countries.contains { locationLower.contains($0.lowercased()) }
            }.sorted { $0.score > $1.score }

            guard !matching.isEmpty else { continue }

            let countryName = countries[0]
            return [DiscoverCategory(
                id: "target_country_\(learningLang.language.code)",
                titleKey: String(format: "discover_row_lives_in".localized, countryName),
                subtitle: nil,
                users: matching
            )]
        }

        return []
    }

    private static func buildIntentRows(
        from profiles: [(user: User, score: Int, reasons: [String])],
        currentUser: User
    ) -> [DiscoverCategory] {
        var rows: [DiscoverCategory] = []

        // Read intents from UserDefaults (stored as raw enum values)
        let storedIntents = UserDefaults.standard.stringArray(forKey: "relationshipIntents") ?? []
        let storedEnumIntents = storedIntents.compactMap { RelationshipIntent(rawValue: $0) }
        let currentIntent = currentUser.matchingPreferences.relationshipIntent
        let allIntents = Set([currentIntent] + storedEnumIntents)

        // Check friendship
        if allIntents.contains(.friendship) {
            let matching = profiles.filter {
                $0.user.matchingPreferences.relationshipIntent == .friendship
            }.sorted { $0.score > $1.score }
            if !matching.isEmpty {
                rows.append(DiscoverCategory(
                    id: "friendship",
                    titleKey: "discover_row_friendship",
                    subtitle: nil,
                    users: matching
                ))
            }
        }

        // Check dating
        if allIntents.contains(.openToDating) {
            let matching = profiles.filter {
                $0.user.matchingPreferences.relationshipIntent == .openToDating
            }.sorted { $0.score > $1.score }
            if !matching.isEmpty {
                rows.append(DiscoverCategory(
                    id: "dating",
                    titleKey: "discover_row_dating",
                    subtitle: nil,
                    users: matching
                ))
            }
        }

        // Check networking
        if allIntents.contains(.networking) {
            let matching = profiles.filter {
                $0.user.matchingPreferences.relationshipIntent == .networking
            }.sorted { $0.score > $1.score }
            if !matching.isEmpty {
                rows.append(DiscoverCategory(
                    id: "networking",
                    titleKey: "discover_row_networking",
                    subtitle: nil,
                    users: matching
                ))
            }
        }

        return rows
    }

    private static func buildProficiencyRow(
        from profiles: [(user: User, score: Int, reasons: [String])],
        currentUser: User
    ) -> DiscoverCategory? {
        // Find shared learning language with most profiles
        guard let myLearning = currentUser.learningLanguages.first else { return nil }
        let myProficiency = myLearning.proficiency

        // Group profiles by their proficiency in the shared language
        var byLevel: [LanguageProficiency: [(user: User, score: Int, reasons: [String])]] = [:]

        for profile in profiles {
            for lang in profile.user.learningLanguages {
                if lang.language == myLearning.language {
                    byLevel[lang.proficiency, default: []].append(profile)
                }
            }
            // Also check native speakers
            if profile.user.nativeLanguage.language == myLearning.language {
                byLevel[.native, default: []].append(profile)
            }
        }

        // Try to show the row matching user's own level first
        let levelOrder: [LanguageProficiency] = {
            switch myProficiency {
            case .beginner: return [.beginner, .intermediate, .advanced, .native]
            case .intermediate: return [.intermediate, .beginner, .advanced, .native]
            case .advanced: return [.advanced, .intermediate, .native, .beginner]
            case .native: return [.native, .advanced, .intermediate, .beginner]
            }
        }()

        // Try single level first (need >= 3)
        for level in levelOrder {
            if let users = byLevel[level], users.count >= 3 {
                let title = String(format: "discover_row_proficiency_single".localized, level.displayName)
                return DiscoverCategory(
                    id: "proficiency_\(level.rawValue)",
                    titleKey: title,
                    subtitle: nil,
                    users: users.sorted { $0.score > $1.score }
                )
            }
        }

        // Try combining adjacent levels
        let allLevels: [LanguageProficiency] = [.beginner, .intermediate, .advanced, .native]
        for i in 0..<(allLevels.count - 1) {
            let low = allLevels[i]
            let high = allLevels[i + 1]
            let combined = (byLevel[low] ?? []) + (byLevel[high] ?? [])
            if combined.count >= 3 {
                let title = String(format: "discover_row_proficiency_range".localized, low.displayName, high.displayName)
                return DiscoverCategory(
                    id: "proficiency_\(low.rawValue)_\(high.rawValue)",
                    titleKey: title,
                    subtitle: nil,
                    users: combined.sorted { $0.score > $1.score }
                )
            }
        }

        return nil
    }

    private static func buildLearningContextRow(
        from profiles: [(user: User, score: Int, reasons: [String])],
        contexts: [LearningContext],
        id: String,
        titleKey: String,
        languageName: String? = nil
    ) -> DiscoverCategory? {
        let contextSet = Set(contexts)
        let matching = profiles.filter { profile in
            let userContexts = Set(profile.user.matchingPreferences.learningContexts)
            return !userContexts.intersection(contextSet).isEmpty
        }.sorted { $0.score > $1.score }

        guard !matching.isEmpty else { return nil }

        // Append language name for context (e.g. "Business & Professional - Spanish")
        let displayTitle: String
        if let langName = languageName {
            displayTitle = "\(titleKey.localized) - \(langName)"
        } else {
            displayTitle = titleKey
        }

        return DiscoverCategory(
            id: id,
            titleKey: displayTitle,
            subtitle: nil,
            users: matching
        )
    }

    private static func buildRegularSessionHosts(
        from profiles: [(user: User, score: Int, reasons: [String])]
    ) -> DiscoverCategory? {
        // Filter to users who have hosted at least 3 completed sessions, sorted by count
        let hosts = profiles
            .filter { $0.user.sessionsHostedCount >= 3 }
            .sorted { $0.user.sessionsHostedCount > $1.user.sessionsHostedCount }

        guard !hosts.isEmpty else { return nil }
        return DiscoverCategory(
            id: "regular_session_hosts",
            titleKey: "discover_row_session_hosts",
            subtitle: nil,
            users: hosts
        )
    }

    private static func buildGlobalConnections(
        from profiles: [(user: User, score: Int, reasons: [String])],
        currentUser: User
    ) -> DiscoverCategory? {
        let myCountry = extractCountry(from: currentUser.location)

        // Collect all target-language countries
        var targetCountries = Set<String>()
        for lang in currentUser.learningLanguages {
            for country in lang.language.associatedCountries {
                targetCountries.insert(country.lowercased())
            }
        }

        let global = profiles.filter { profile in
            guard let location = profile.user.location else { return false }
            let profileCountry = extractCountry(from: location)?.lowercased() ?? ""

            // Not in user's country
            let notLocal = myCountry.map { profileCountry != $0.lowercased() } ?? true
            // Not in any target-language country
            let notTargetCountry = !targetCountries.contains { profileCountry.contains($0) }

            return notLocal && notTargetCountry
        }.sorted { $0.score > $1.score }

        guard !global.isEmpty else { return nil }
        return DiscoverCategory(
            id: "third_country",
            titleKey: "discover_row_third_country",
            subtitle: nil,
            users: global
        )
    }

    // MARK: - Helpers

    private static func extractCountry(from location: String?) -> String? {
        guard let location = location else { return nil }
        let components = location.components(separatedBy: ",")
        return components.last?.trimmingCharacters(in: .whitespaces)
    }
}
