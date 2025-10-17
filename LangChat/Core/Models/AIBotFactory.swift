import Foundation

/// Factory for creating AI practice partners
class AIBotFactory {

    /// Create multiple AI practice partners for different languages
    static func createAIBots() -> [User] {
        return [
            createSpanishBot(),
            createFrenchBot(),
            createJapaneseBot(),
            createGermanBot(),
            createMandarinBot()
        ]
    }

    // MARK: - Spanish Bot

    private static func createSpanishBot() -> User {
        return User(
            id: "ai_bot_spanish",
            username: "maria_ai",
            firstName: "María",
            lastName: "AI Assistant",
            bio: "¡Hola! I'm an AI language partner here to help you practice Spanish. I can chat naturally and help with grammar! 🤖🇪🇸",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .spanish, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.spanish, .english],
            practiceLanguages: [UserLanguage(language: .spanish, proficiency: .native, isNative: true)],
            location: "Virtual, Worldwide",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - French Bot

    private static func createFrenchBot() -> User {
        return User(
            id: "ai_bot_french",
            username: "sophie_ai",
            firstName: "Sophie",
            lastName: "AI Assistant",
            bio: "Bonjour! Je suis votre partenaire IA pour pratiquer le français. Let's chat! 🤖🇫🇷",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.french, .english],
            practiceLanguages: [UserLanguage(language: .french, proficiency: .native, isNative: true)],
            location: "Virtual, Worldwide",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - Japanese Bot

    private static func createJapaneseBot() -> User {
        return User(
            id: "ai_bot_japanese",
            username: "yuki_ai",
            firstName: "Yuki",
            lastName: "AI Assistant",
            bio: "こんにちは！I'm your AI partner for practicing Japanese. I can help with conversation and grammar! 🤖🇯🇵",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .japanese, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.japanese, .english],
            practiceLanguages: [UserLanguage(language: .japanese, proficiency: .native, isNative: true)],
            location: "Virtual, Worldwide",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - German Bot

    private static func createGermanBot() -> User {
        return User(
            id: "ai_bot_german",
            username: "max_ai",
            firstName: "Max",
            lastName: "AI Assistant",
            bio: "Hallo! I'm here to help you practice German. Let's have a conversation! 🤖🇩🇪",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .german, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.german, .english],
            practiceLanguages: [UserLanguage(language: .german, proficiency: .native, isNative: true)],
            location: "Virtual, Worldwide",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - Mandarin Bot

    private static func createMandarinBot() -> User {
        return User(
            id: "ai_bot_mandarin",
            username: "lin_ai",
            firstName: "Lin",
            lastName: "AI Assistant",
            bio: "你好！I'm your AI practice partner for Mandarin Chinese. Let's chat and learn! 🤖🇨🇳",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .chinese, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.chinese, .english],
            practiceLanguages: [UserLanguage(language: .chinese, proficiency: .native, isNative: true)],
            location: "Virtual, Worldwide",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }
}
