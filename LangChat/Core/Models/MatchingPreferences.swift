import Foundation
import CoreLocation

// MARK: - Gender Enums

enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case nonBinary = "non_binary"
    case preferNotToSay = "prefer_not_to_say"

    var displayName: String {
        switch self {
        case .male: return "gender_male".localized
        case .female: return "gender_female".localized
        case .nonBinary: return "gender_nonbinary".localized
        case .preferNotToSay: return "gender_prefer_not_to_say".localized
        }
    }

    var icon: String {
        switch self {
        case .male: return "♂"
        case .female: return "♀"
        case .nonBinary: return "⚧"
        case .preferNotToSay: return "—"
        }
    }
}

enum GenderPreference: String, CaseIterable, Codable {
    case all = "all"
    case sameOnly = "same_only"
    case differentOnly = "different_only"

    var displayName: String {
        switch self {
        case .all: return "gender_pref_all".localized
        case .sameOnly: return "gender_pref_same".localized
        case .differentOnly: return "gender_pref_different".localized
        }
    }

    var subtitle: String {
        switch self {
        case .all: return "gender_pref_all_desc".localized
        case .sameOnly: return "gender_pref_same_desc".localized
        case .differentOnly: return "gender_pref_different_desc".localized
        }
    }
}

/// Preferred gender for AI Muse assistants
enum MuseGenderPreference: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"

    var displayName: String {
        switch self {
        case .male: return "muse_gender_male".localized
        case .female: return "muse_gender_female".localized
        }
    }

    var subtitle: String {
        switch self {
        case .male: return "muse_gender_male_desc".localized
        case .female: return "muse_gender_female_desc".localized
        }
    }

    var icon: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        }
    }
}

// MARK: - Location Enums

enum LocationPreference: String, CaseIterable, Codable {
    case localRegional = "local_regional"  // Customizable distance 10-200km
    case country = "country"
    case specificCountries = "specific_countries"
    case excludeCountries = "exclude_countries"  // Anywhere except selected countries
    case anywhere = "anywhere"

    var displayName: String {
        switch self {
        case .localRegional: return "location_pref_local".localized
        case .country: return "location_pref_country".localized
        case .specificCountries: return "location_pref_specific".localized
        case .excludeCountries: return "location_pref_exclude".localized
        case .anywhere: return "location_pref_anywhere".localized
        }
    }

    var subtitle: String {
        switch self {
        case .localRegional: return "location_pref_local_desc".localized
        case .country: return "location_pref_country_desc".localized
        case .specificCountries: return "location_pref_specific_desc".localized
        case .excludeCountries: return "location_pref_exclude_desc".localized
        case .anywhere: return "location_pref_anywhere_desc".localized
        }
    }

    var icon: String {
        switch self {
        case .localRegional: return "location.circle"
        case .country: return "flag"
        case .specificCountries: return "globe.americas"
        case .excludeCountries: return "globe.badge.chevron.backward"
        case .anywhere: return "globe"
        }
    }
}

// MARK: - Relationship Intent

enum RelationshipIntent: String, CaseIterable, Codable {
    case languagePracticeOnly = "language_practice_only"
    case friendship = "friendship"
    case openToDating = "open_to_dating"

    var displayName: String {
        switch self {
        case .languagePracticeOnly: return "intent_practice_only".localized
        case .friendship: return "intent_friendship".localized
        case .openToDating: return "intent_dating".localized
        }
    }

    var subtitle: String {
        switch self {
        case .languagePracticeOnly: return "intent_practice_only_desc".localized
        case .friendship: return "intent_friendship_desc".localized
        case .openToDating: return "intent_dating_desc".localized
        }
    }

    var icon: String {
        switch self {
        case .languagePracticeOnly: return "book.fill"
        case .friendship: return "person.2.fill"
        case .openToDating: return "heart.fill"
        }
    }
}

// MARK: - Learning Context

enum LearningContext: String, CaseIterable, Codable {
    case formal = "formal"
    case casual = "casual"
    case academic = "academic"
    case slang = "slang"
    case travel = "travel"
    case technical = "technical"

    var displayName: String {
        switch self {
        case .formal: return "goal_formal_title".localized
        case .casual: return "goal_casual_title".localized
        case .academic: return "goal_academic_title".localized
        case .slang: return "goal_slang_title".localized
        case .travel: return "goal_travel_title".localized
        case .technical: return "goal_technical_title".localized
        }
    }

    var icon: String {
        switch self {
        case .formal: return "briefcase.fill"
        case .casual: return "face.smiling.fill"
        case .academic: return "book.fill"
        case .slang: return "flame.fill"
        case .travel: return "airplane"
        case .technical: return "laptopcomputer"
        }
    }
}

// MARK: - Travel Destination

struct TravelDestination: Codable, Equatable {
    let city: String?
    let country: String // ISO country code
    let countryName: String
    let startDate: Date?
    let endDate: Date?

    var displayName: String {
        if let city = city {
            return "\(city), \(countryName)"
        }
        return countryName
    }

    var dateRange: String? {
        guard let start = startDate, let end = endDate else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    // Check if travel dates are current or upcoming
    var isActive: Bool {
        guard let end = endDate else { return false }
        return end > Date()
    }
}

// MARK: - Matching Preferences Model

struct MatchingPreferences: Codable {

    // MARK: - Demographics

    /// User's gender
    let gender: Gender

    /// Preferred genders to match with
    let genderPreference: GenderPreference

    /// Preferred gender for AI Muse assistants (male or female)
    let preferredMuseGender: MuseGenderPreference

    /// Minimum age preference
    let minAge: Int

    /// Maximum age preference
    let maxAge: Int

    // MARK: - Location

    /// Location preference type (local, regional, country, specific countries, anywhere)
    let locationPreference: LocationPreference

    /// User's current latitude (for distance calculation)
    let latitude: Double?

    /// User's current longitude (for distance calculation)
    let longitude: Double?

    /// List of preferred country codes (ISO) for matching
    /// Used when locationPreference is .specificCountries
    let preferredCountries: [String]?

    /// List of excluded country codes (ISO)
    /// Used when locationPreference is .excludeCountries
    let excludedCountries: [String]?

    /// Custom maximum distance in km for local/regional matching
    /// Used when locationPreference is .localRegional
    let customMaxDistanceKm: Int?

    // MARK: - Travel

    /// Travel destination if user is planning a trip
    let travelDestination: TravelDestination?

    // MARK: - Intent & Context

    /// What the user is looking for (single selection)
    let relationshipIntent: RelationshipIntent

    /// Why the user is learning languages (can select multiple)
    let learningContexts: [LearningContext]

    // MARK: - Existing Preferences (from original implementation)

    /// Allow matching with non-native speakers
    let allowNonNativeMatches: Bool

    /// Minimum proficiency level for non-native matches
    let minProficiencyLevel: LanguageProficiency

    /// Maximum proficiency level for non-native matches
    let maxProficiencyLevel: LanguageProficiency

    // MARK: - Initializer with defaults

    init(
        gender: Gender = .preferNotToSay,
        genderPreference: GenderPreference = .all,
        preferredMuseGender: MuseGenderPreference = .female,
        minAge: Int = 18,
        maxAge: Int = 80,
        locationPreference: LocationPreference = .anywhere,
        latitude: Double? = nil,
        longitude: Double? = nil,
        preferredCountries: [String]? = nil,
        excludedCountries: [String]? = nil,
        customMaxDistanceKm: Int? = nil,
        travelDestination: TravelDestination? = nil,
        relationshipIntent: RelationshipIntent = .languagePracticeOnly,
        learningContexts: [LearningContext] = [],  // Empty = open to all styles
        allowNonNativeMatches: Bool = false,
        minProficiencyLevel: LanguageProficiency = .beginner,
        maxProficiencyLevel: LanguageProficiency = .advanced
    ) {
        self.gender = gender
        self.genderPreference = genderPreference
        self.preferredMuseGender = preferredMuseGender
        self.minAge = minAge
        self.maxAge = maxAge
        self.locationPreference = locationPreference
        self.latitude = latitude
        self.longitude = longitude
        self.preferredCountries = preferredCountries
        self.excludedCountries = excludedCountries
        self.customMaxDistanceKm = customMaxDistanceKm
        self.travelDestination = travelDestination
        self.relationshipIntent = relationshipIntent
        self.learningContexts = learningContexts
        self.allowNonNativeMatches = allowNonNativeMatches
        self.minProficiencyLevel = minProficiencyLevel
        self.maxProficiencyLevel = maxProficiencyLevel
    }

    // MARK: - Helper Methods

    /// Get maximum distance in kilometers based on location preference
    var maxDistanceKm: Int? {
        switch locationPreference {
        case .localRegional:
            return customMaxDistanceKm ?? 50 // Default to 50km if not set
        case .country, .specificCountries, .excludeCountries, .anywhere:
            return nil
        }
    }

    /// Check if user has active travel plans
    var hasActiveTravelPlans: Bool {
        return travelDestination?.isActive ?? false
    }

    /// Check if user is open to any form of social connection beyond language practice
    var openToSocializing: Bool {
        return relationshipIntent == .friendship || relationshipIntent == .openToDating
    }
}

// MARK: - Distance Calculation Extension

extension MatchingPreferences {

    /// Calculate distance in kilometers between two locations
    /// - Parameters:
    ///   - lat1: First location latitude
    ///   - lon1: First location longitude
    ///   - lat2: Second location latitude
    ///   - lon2: Second location longitude
    /// - Returns: Distance in kilometers
    static func calculateDistance(
        from lat1: Double, lon1: Double,
        to lat2: Double, lon2: Double
    ) -> Double {
        let location1 = CLLocation(latitude: lat1, longitude: lon1)
        let location2 = CLLocation(latitude: lat2, longitude: lon2)
        let distanceMeters = location1.distance(from: location2)
        return distanceMeters / 1000.0 // Convert to kilometers
    }

    /// Calculate distance to another user's preferences
    func distanceKm(to otherPreferences: MatchingPreferences) -> Double? {
        guard let lat1 = self.latitude, let lon1 = self.longitude,
              let lat2 = otherPreferences.latitude, let lon2 = otherPreferences.longitude else {
            return nil
        }

        return MatchingPreferences.calculateDistance(
            from: lat1, lon1: lon1,
            to: lat2, lon2: lon2
        )
    }
}
