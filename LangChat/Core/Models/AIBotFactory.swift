import Foundation

/// Factory for creating AI Muses - creative language practice partners
class AIBotFactory {

    /// Create multiple AI Muses for different languages
    static func createAIBots() -> [User] {
        return [
            createSpanishMuse(),
            createFrenchMuse(),
            createJapaneseMuse(),
            createGermanMuse(),
            createMandarinMuse(),
            createPortugueseMuse()
        ]
    }

    // MARK: - Spanish Muse

    private static func createSpanishMuse() -> User {
        return User(
            id: "ai_bot_spanish",
            username: "maria_muse",
            firstName: "María",
            lastName: "Muse",
            bio: "¡Hola! I'm your Spanish Muse, here to inspire your language journey. Let's explore Spanish together! ✨🇪🇸",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .spanish, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.spanish, .english],
            practiceLanguages: [UserLanguage(language: .spanish, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - French Muse

    private static func createFrenchMuse() -> User {
        return User(
            id: "ai_bot_french",
            username: "sophie_muse",
            firstName: "Sophie",
            lastName: "Muse",
            bio: "Bonjour! I'm your French Muse, ready to guide you through la belle langue française. Allons-y! ✨🇫🇷",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.french, .english],
            practiceLanguages: [UserLanguage(language: .french, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - Japanese Muse

    private static func createJapaneseMuse() -> User {
        return User(
            id: "ai_bot_japanese",
            username: "yuki_muse",
            firstName: "Yuki",
            lastName: "Muse",
            bio: "こんにちは！I'm your Japanese Muse, here to inspire your journey through 日本語. Let's create something beautiful! ✨🇯🇵",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .japanese, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.japanese, .english],
            practiceLanguages: [UserLanguage(language: .japanese, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - German Muse

    private static func createGermanMuse() -> User {
        return User(
            id: "ai_bot_german",
            username: "max_muse",
            firstName: "Max",
            lastName: "Muse",
            bio: "Hallo! I'm your German Muse, here to inspire your Deutsch adventures. Lass uns anfangen! ✨🇩🇪",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .german, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.german, .english],
            practiceLanguages: [UserLanguage(language: .german, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - Mandarin Muse

    private static func createMandarinMuse() -> User {
        return User(
            id: "ai_bot_mandarin",
            username: "lin_muse",
            firstName: "Lin",
            lastName: "Muse",
            bio: "你好！I'm your Mandarin Muse, ready to inspire your Chinese journey. 我们一起学习吧！✨🇨🇳",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .chinese, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.chinese, .english],
            practiceLanguages: [UserLanguage(language: .chinese, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - Portuguese Muse

    private static func createPortugueseMuse() -> User {
        return User(
            id: "ai_bot_portuguese",
            username: "racquel_muse",
            firstName: "Racquel",
            lastName: "Muse",
            bio: "Olá! I'm your Portuguese Muse, here to inspire your journey through português. Vamos sonhar juntos! ✨🇧🇷",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .portuguese, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.portuguese, .english],
            practiceLanguages: [UserLanguage(language: .portuguese, proficiency: .native, isNative: true)],
            location: "Your Imagination",
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
