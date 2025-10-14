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
    let nativeLanguage: UserLanguage
    let learningLanguages: [UserLanguage]
    let openToLanguages: [Language]
    let practiceLanguages: [UserLanguage]? // Languages user wants to practice/chat in
    let location: String?
    let showCityInProfile: Bool // Privacy setting for showing city
    let matchedDate: Date?
    let isOnline: Bool

    // Default initializer for backwards compatibility
    init(id: String, username: String, firstName: String, lastName: String? = nil,
         bio: String? = nil, profileImageURL: String? = nil, photoURLs: [String] = [],
         nativeLanguage: UserLanguage, learningLanguages: [UserLanguage],
         openToLanguages: [Language], practiceLanguages: [UserLanguage]? = nil,
         location: String? = nil, showCityInProfile: Bool = true,
         matchedDate: Date? = nil, isOnline: Bool = false) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.photoURLs = photoURLs
        self.nativeLanguage = nativeLanguage
        self.learningLanguages = learningLanguages
        self.openToLanguages = openToLanguages
        self.practiceLanguages = practiceLanguages
        self.location = location
        self.showCityInProfile = showCityInProfile
        self.matchedDate = matchedDate
        self.isOnline = isOnline
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
}