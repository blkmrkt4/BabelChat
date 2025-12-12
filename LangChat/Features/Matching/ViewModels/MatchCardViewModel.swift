import Foundation

/// ViewModel for displaying a match card with context-specific language information
class MatchCardViewModel {
    let user: User
    let matchedLanguagePair: MatchedLanguagePair?

    init(user: User, matchedLanguagePair: MatchedLanguagePair? = nil) {
        self.user = user
        self.matchedLanguagePair = matchedLanguagePair
    }

    // MARK: - Display Properties

    var displayName: String {
        return user.displayName
    }

    var profileImageURL: String? {
        return user.profileImageURL
    }

    var photoURLs: [String] {
        return user.photoURLs
    }

    /// Primary native language to display (based on match context if available)
    var displayNativeLanguage: UserLanguage {
        if let matchContext = matchedLanguagePair {
            // Show the native language that matches the context
            if user.nativeLanguage.language == matchContext.partnerNativeLanguage {
                return user.nativeLanguage
            }
        }
        // Fallback to user's primary native language
        return user.nativeLanguage
    }

    /// Primary learning language to display (based on match context if available)
    var displayLearningLanguage: UserLanguage? {
        if let matchContext = matchedLanguagePair {
            // Show the learning language that matches the context
            return user.learningLanguages.first { $0.language == matchContext.partnerLearningLanguage }
        }
        // Fallback to first learning language
        return user.learningLanguages.first
    }

    /// Additional learning languages (excluding the primary matched one)
    var additionalLearningLanguages: [UserLanguage] {
        guard let matchContext = matchedLanguagePair else {
            // If no match context, return all but the first
            return Array(user.learningLanguages.dropFirst())
        }

        // Filter out the matched learning language
        return user.learningLanguages.filter { $0.language != matchContext.partnerLearningLanguage }
    }

    /// Bio text with optional additional learning languages appended
    var bioText: String {
        var bio = user.bio ?? ""

        // If there are additional learning languages not shown in the primary context
        if !additionalLearningLanguages.isEmpty {
            let languageNames = additionalLearningLanguages.map { $0.language.name }

            // Only append if the bio doesn't already mention these languages
            let bioLower = bio.lowercased()
            let unmentionedLanguages = languageNames.filter { !bioLower.contains($0.lowercased()) }

            if !unmentionedLanguages.isEmpty {
                let langList = unmentionedLanguages.joined(separator: ", ")
                let separator = bio.isEmpty ? "" : "\n\n"
                bio += "\(separator)Also learning: \(langList)"
            }
        }

        return bio
    }

    /// Display string for languages the user is open to matching in
    var openToMatchText: String {
        let languageNames = user.openToLanguages.map { $0.name }.joined(separator: ", ")
        return "Open to match in: \(languageNames)"
    }

    var displayLocation: String? {
        return user.displayLocation
    }

    var age: Int? {
        return user.age
    }

    var formattedMatchDate: String? {
        return user.formattedMatchDate
    }

    /// Full name for "About" section
    var aboutHeaderText: String {
        return "About \(user.firstName)"
    }
}
