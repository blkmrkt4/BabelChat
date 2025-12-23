import Foundation
import UIKit

struct User: Codable {
    let id: String
    let username: String
    let firstName: String
    let lastName: String?
    let bio: String?
    let profileImageURL: String?
    let photoURLs: [String]
    let photoCaptions: [String?]? // Optional captions for photos
    let nativeLanguage: UserLanguage
    let learningLanguages: [UserLanguage]
    let openToLanguages: [Language]
    let practiceLanguages: [UserLanguage]? // Languages user wants to practice/chat in
    let museLanguages: [Language] // Additional languages accessible via Muse (beyond learning languages)
    let location: String?
    let showCityInProfile: Bool // Privacy setting for showing city
    let matchedDate: Date?
    let isOnline: Bool
    let isAI: Bool // Indicates if this is an AI practice partner
    let birthYear: Int? // Birth year for age calculation
    let gender: String? // Gender for TTS voice selection (male, female, or nil)

    // Platonic and blur preferences
    let strictlyPlatonic: Bool // Only wants platonic language exchange (no dating)
    let blurPhotosUntilMatch: Bool // Photos blurred in discovery until matched (legacy global setting)
    let photoBlurSettings: [Bool] // Per-photo blur settings (index matches photoURLs)

    // Matching preferences (new comprehensive preferences model)
    let matchingPreferences: MatchingPreferences

    /// Returns all languages available for Muse interactions
    /// Includes: English (always), learning languages, and additional Muse languages
    var availableMuseLanguages: [Language] {
        var languages = Set<Language>()

        // Always include English
        languages.insert(.english)

        // Add learning languages
        for userLang in learningLanguages {
            languages.insert(userLang.language)
        }

        // Add selected Muse languages
        for lang in museLanguages {
            languages.insert(lang)
        }

        // Sort by the order in museLanguages static list, with English first
        let sortOrder = [Language.english] + Language.museLanguages
        return languages.sorted { lang1, lang2 in
            let idx1 = sortOrder.firstIndex(of: lang1) ?? 999
            let idx2 = sortOrder.firstIndex(of: lang2) ?? 999
            return idx1 < idx2
        }
    }

    // MARK: - Deprecated properties (kept for backwards compatibility)
    // These are now part of matchingPreferences but kept here for compatibility
    @available(*, deprecated, message: "Use matchingPreferences.allowNonNativeMatches instead")
    var allowNonNativeMatches: Bool {
        return matchingPreferences.allowNonNativeMatches
    }

    @available(*, deprecated, message: "Use matchingPreferences.minProficiencyLevel instead")
    var minProficiencyLevel: LanguageProficiency {
        return matchingPreferences.minProficiencyLevel
    }

    @available(*, deprecated, message: "Use matchingPreferences.maxProficiencyLevel instead")
    var maxProficiencyLevel: LanguageProficiency {
        return matchingPreferences.maxProficiencyLevel
    }

    // Default initializer for backwards compatibility
    init(id: String,
         username: String,
         firstName: String,
         lastName: String? = nil,
         bio: String? = nil,
         profileImageURL: String? = nil,
         photoURLs: [String] = [],
         photoCaptions: [String?]? = nil,
         nativeLanguage: UserLanguage,
         learningLanguages: [UserLanguage],
         openToLanguages: [Language],
         practiceLanguages: [UserLanguage]? = nil,
         museLanguages: [Language] = [],
         location: String? = nil,
         showCityInProfile: Bool = true,
         matchedDate: Date? = nil,
         isOnline: Bool = false,
         isAI: Bool = false,
         birthYear: Int? = nil,
         gender: String? = nil,
         strictlyPlatonic: Bool = false,
         blurPhotosUntilMatch: Bool = false,
         photoBlurSettings: [Bool] = [],
         matchingPreferences: MatchingPreferences? = nil,
         // Deprecated parameters (for backwards compatibility)
         allowNonNativeMatches: Bool = false,
         minProficiencyLevel: LanguageProficiency = .beginner,
         maxProficiencyLevel: LanguageProficiency = .advanced) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.photoURLs = photoURLs
        self.photoCaptions = photoCaptions
        self.nativeLanguage = nativeLanguage
        self.learningLanguages = learningLanguages
        self.openToLanguages = openToLanguages
        self.practiceLanguages = practiceLanguages
        self.museLanguages = museLanguages
        self.location = location
        self.showCityInProfile = showCityInProfile
        self.matchedDate = matchedDate
        self.isOnline = isOnline
        self.isAI = isAI
        self.birthYear = birthYear
        self.gender = gender
        self.strictlyPlatonic = strictlyPlatonic
        self.blurPhotosUntilMatch = blurPhotosUntilMatch
        self.photoBlurSettings = photoBlurSettings

        // Use provided matchingPreferences or create default from old parameters
        if let matchingPreferences = matchingPreferences {
            self.matchingPreferences = matchingPreferences
        } else {
            // Create default preferences using old parameters for backwards compatibility
            self.matchingPreferences = MatchingPreferences(
                allowNonNativeMatches: allowNonNativeMatches,
                minProficiencyLevel: minProficiencyLevel,
                maxProficiencyLevel: maxProficiencyLevel
            )
        }
    }

    var displayName: String {
        return username
    }

    var fullName: String {
        if let lastName = lastName {
            return "\(firstName) \(lastName)"
        }
        return firstName
    }

    var formattedMatchDate: String? {
        guard let matchedDate = matchedDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return "Matched \(formatter.string(from: matchedDate))"
    }

    var aspiringLanguages: [UserLanguage] {
        return learningLanguages
    }

    // Display location based on privacy setting
    var displayLocation: String? {
        guard let location = location else { return nil }

        if showCityInProfile {
            // Show full location (city, country)
            return location
        } else {
            // Show only country (extract from "City, Country" format)
            let components = location.components(separatedBy: ",")
            if components.count > 1 {
                return components.last?.trimmingCharacters(in: .whitespaces)
            }
            return location
        }
    }

    // Calculate age from birth year
    var age: Int? {
        guard let birthYear = birthYear else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birthYear
    }

    // Check if any photo has blur enabled (for discovery view)
    var hasAnyBlurredPhotos: Bool {
        // Check per-photo settings first
        if photoBlurSettings.contains(true) {
            return true
        }
        // Fall back to legacy global setting
        return blurPhotosUntilMatch
    }

    // Check if a specific photo should be blurred
    func shouldBlurPhoto(at index: Int) -> Bool {
        if index < photoBlurSettings.count {
            return photoBlurSettings[index]
        }
        // Fall back to legacy global setting
        return blurPhotosUntilMatch
    }

    // Get age range display string
    var ageRangeDisplay: String {
        guard let age = age else { return "Age not specified" }
        return "\(age)"
    }
}