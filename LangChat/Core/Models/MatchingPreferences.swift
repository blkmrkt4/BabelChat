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
        case .male: return "Male"
        case .female: return "Female"
        case .nonBinary: return "Non-binary"
        case .preferNotToSay: return "Prefer not to say"
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
        case .all: return "Everyone"
        case .sameOnly: return "Same gender only"
        case .differentOnly: return "Different gender only"
        }
    }

    var subtitle: String {
        switch self {
        case .all: return "Match with people of any gender"
        case .sameOnly: return "Match with people of the same gender"
        case .differentOnly: return "Match with people of different genders"
        }
    }
}

// MARK: - Location Enums

enum LocationPreference: String, CaseIterable, Codable {
    case local25km = "local_25km"
    case regional100km = "regional_100km"
    case country = "country"
    case specificCountries = "specific_countries"
    case anywhere = "anywhere"

    var displayName: String {
        switch self {
        case .local25km: return "Local (25km/15mi)"
        case .regional100km: return "Regional (100km/60mi)"
        case .country: return "My country"
        case .specificCountries: return "Specific countries"
        case .anywhere: return "Anywhere in the world"
        }
    }

    var subtitle: String {
        switch self {
        case .local25km: return "Find language partners nearby for in-person meetups"
        case .regional100km: return "Expand your search to a wider area"
        case .country: return "Match with people from your country"
        case .specificCountries: return "Choose countries where you want to find partners"
        case .anywhere: return "Connect with language learners globally"
        }
    }

    var maxDistanceKm: Int? {
        switch self {
        case .local25km: return 25
        case .regional100km: return 100
        case .country, .specificCountries, .anywhere: return nil
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
        case .languagePracticeOnly: return "Language practice only"
        case .friendship: return "Friendship"
        case .openToDating: return "Open to dating"
        }
    }

    var subtitle: String {
        switch self {
        case .languagePracticeOnly: return "Focused language exchange, no socializing beyond the app"
        case .friendship: return "Willing to connect outside the app as friends"
        case .openToDating: return "Language practice with possibility of romance"
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
    case travel = "travel"
    case work = "work"
    case cultural = "cultural"
    case family = "family"
    case academic = "academic"
    case fun = "fun"

    var displayName: String {
        switch self {
        case .travel: return "Travel"
        case .work: return "Work/Business"
        case .cultural: return "Cultural interest"
        case .family: return "Family/Heritage"
        case .academic: return "Academic"
        case .fun: return "Just for fun"
        }
    }

    var icon: String {
        switch self {
        case .travel: return "airplane"
        case .work: return "briefcase.fill"
        case .cultural: return "globe"
        case .family: return "house.fill"
        case .academic: return "graduationcap.fill"
        case .fun: return "star.fill"
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

    // MARK: - Travel

    /// Travel destination if user is planning a trip
    let travelDestination: TravelDestination?

    // MARK: - Intent & Context

    /// What the user is looking for (can select multiple)
    let relationshipIntents: [RelationshipIntent]

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
        minAge: Int = 18,
        maxAge: Int = 80,
        locationPreference: LocationPreference = .anywhere,
        latitude: Double? = nil,
        longitude: Double? = nil,
        preferredCountries: [String]? = nil,
        travelDestination: TravelDestination? = nil,
        relationshipIntents: [RelationshipIntent] = [.languagePracticeOnly],
        learningContexts: [LearningContext] = [.fun],
        allowNonNativeMatches: Bool = false,
        minProficiencyLevel: LanguageProficiency = .beginner,
        maxProficiencyLevel: LanguageProficiency = .advanced
    ) {
        self.gender = gender
        self.genderPreference = genderPreference
        self.minAge = minAge
        self.maxAge = maxAge
        self.locationPreference = locationPreference
        self.latitude = latitude
        self.longitude = longitude
        self.preferredCountries = preferredCountries
        self.travelDestination = travelDestination
        self.relationshipIntents = relationshipIntents
        self.learningContexts = learningContexts
        self.allowNonNativeMatches = allowNonNativeMatches
        self.minProficiencyLevel = minProficiencyLevel
        self.maxProficiencyLevel = maxProficiencyLevel
    }

    // MARK: - Helper Methods

    /// Get maximum distance in kilometers based on location preference
    var maxDistanceKm: Int? {
        return locationPreference.maxDistanceKm
    }

    /// Check if user has active travel plans
    var hasActiveTravelPlans: Bool {
        return travelDestination?.isActive ?? false
    }

    /// Check if user is open to any form of social connection beyond language practice
    var openToSocializing: Bool {
        return relationshipIntents.contains(.friendship) || relationshipIntents.contains(.openToDating)
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
