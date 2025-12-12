import Foundation

// MARK: - Per-Language Matching Preferences
// Implements concepts #4 (non-native matching) and #5 (proficiency filtering)

/// Preferences for whether to match with non-native speakers for a specific language
struct NonNativePreference: Codable, Equatable {
    /// Whether the user is willing to match with non-native speakers for this language
    let allowNonNatives: Bool

    init(allowNonNatives: Bool = false) {
        self.allowNonNatives = allowNonNatives
    }
}

/// Proficiency level filtering preferences for non-native matches
struct ProficiencyPreference: Codable, Equatable {
    /// Minimum proficiency level acceptable for matching
    /// Only applies when matching with non-natives
    let minimumLevel: LanguageProficiency

    /// Whether to allow matching with users at the same proficiency level
    let allowSameLevel: Bool

    init(minimumLevel: LanguageProficiency = .beginner, allowSameLevel: Bool = true) {
        self.minimumLevel = minimumLevel
        self.allowSameLevel = allowSameLevel
    }
}

/// Complete language matching preferences for a user
/// Stores preferences for each language they're open to matching in
struct LanguageMatchingPreferences: Codable, Equatable {
    /// Map of language code to non-native preferences
    /// Example: ["French": NonNativePreference(allowNonNatives: false)]
    var nonNativePreferences: [String: NonNativePreference]

    /// Map of language code to proficiency preferences
    /// Only used for languages where allowNonNatives is true
    /// Example: ["English": ProficiencyPreference(minimumLevel: .intermediate, allowSameLevel: true)]
    var proficiencyPreferences: [String: ProficiencyPreference]

    init(
        nonNativePreferences: [String: NonNativePreference] = [:],
        proficiencyPreferences: [String: ProficiencyPreference] = [:]
    ) {
        self.nonNativePreferences = nonNativePreferences
        self.proficiencyPreferences = proficiencyPreferences
    }

    // MARK: - Helper Methods

    /// Check if user allows non-native matches for a specific language
    func allowsNonNatives(for language: String) -> Bool {
        return nonNativePreferences[language]?.allowNonNatives ?? false
    }

    /// Get minimum proficiency level for a language
    func minimumLevel(for language: String) -> LanguageProficiency {
        return proficiencyPreferences[language]?.minimumLevel ?? .beginner
    }

    /// Check if user allows same-level matches for a language
    func allowsSameLevel(for language: String) -> Bool {
        return proficiencyPreferences[language]?.allowSameLevel ?? true
    }

    /// Set preference for a language (convenience method)
    mutating func setPreference(
        for language: String,
        allowNonNatives: Bool,
        minimumLevel: LanguageProficiency = .beginner,
        allowSameLevel: Bool = true
    ) {
        nonNativePreferences[language] = NonNativePreference(allowNonNatives: allowNonNatives)

        if allowNonNatives {
            proficiencyPreferences[language] = ProficiencyPreference(
                minimumLevel: minimumLevel,
                allowSameLevel: allowSameLevel
            )
        }
    }

    // MARK: - Factory Methods

    /// Create preferences with "natives only" for all languages
    static func nativesOnly(for languages: [String]) -> LanguageMatchingPreferences {
        var prefs = LanguageMatchingPreferences()
        for lang in languages {
            prefs.nonNativePreferences[lang] = NonNativePreference(allowNonNatives: false)
        }
        return prefs
    }

    /// Create preferences allowing all levels for all languages
    static func allowAll(for languages: [String]) -> LanguageMatchingPreferences {
        var prefs = LanguageMatchingPreferences()
        for lang in languages {
            prefs.setPreference(
                for: lang,
                allowNonNatives: true,
                minimumLevel: .beginner,
                allowSameLevel: true
            )
        }
        return prefs
    }
}

// MARK: - Extension for User Model Integration

extension User {
    /// Get language-specific matching preferences
    var languagePreferences: LanguageMatchingPreferences {
        // This will be loaded from the database fields:
        // - non_native_preferences (JSONB)
        // - proficiency_preferences (JSONB)

        // For now, return default (will be populated from Supabase)
        return LanguageMatchingPreferences()
    }
}
