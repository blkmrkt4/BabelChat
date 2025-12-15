import Foundation

/// Factory for creating AI Muses - creative language practice partners
class AIBotFactory {

    /// Create multiple AI Muses for different languages
    static func createAIBots() -> [User] {
        return [
            createEnglishMuse(),
            createSpanishMuse(),
            createFrenchMuse(),
            createJapaneseMuse(),
            createGermanMuse(),
            createMandarinMuse(),
            createPortugueseMuse(),
            createHindiMuse(),
            createFilipinoMuse(),
            createThaiMuse()
        ]
    }

    // MARK: - English Muse

    private static func createEnglishMuse() -> User {
        return User(
            id: "ai_bot_english",
            username: "emma_muse",
            firstName: "Emma",
            lastName: "Muse",
            bio: "Hello! I'm your English Muse, here to help you master English conversation. Let's chat and learn together! ✨",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .english, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .spanish, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.english, .spanish],
            practiceLanguages: [UserLanguage(language: .english, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female",
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - Spanish Muse

    private static func createSpanishMuse() -> User {
        return User(
            id: "ai_bot_spanish",
            username: "maria_muse",
            firstName: "María",
            lastName: "Muse",
            bio: "¡Hola! I'm your Spanish Muse, here to inspire your language journey. Let's explore Spanish together! ✨",
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
            gender: "female",
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
            bio: "Bonjour! I'm your French Muse, ready to guide you through la belle langue française. Allons-y! ✨",
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
            gender: "female",
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
            bio: "こんにちは！I'm your Japanese Muse, here to inspire your journey through 日本語. Let's create something beautiful! ✨",
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
            gender: "female",
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
            bio: "Hallo! I'm your German Muse, here to inspire your Deutsch adventures. Lass uns anfangen! ✨",
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
            gender: "male",
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
            bio: "你好！I'm your Mandarin Muse, ready to inspire your Chinese journey. 我们一起学习吧！✨",
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
            gender: "female",
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
            bio: "Olá! I'm your Brazilian Portuguese Muse, here to inspire your journey through português brasileiro. Vamos sonhar juntos! ✨",
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
            gender: "female",
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - Hindi Muse

    private static func createHindiMuse() -> User {
        return User(
            id: "ai_bot_hindi",
            username: "poonam_muse",
            firstName: "Poonam",
            lastName: "Muse",
            bio: "नमस्ते! I'm your Hindi Muse, here to guide you through the beautiful हिन्दी language. Let's learn together! ✨",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .hindi, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.hindi, .english],
            practiceLanguages: [UserLanguage(language: .hindi, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female",
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - Filipino Muse

    private static func createFilipinoMuse() -> User {
        return User(
            id: "ai_bot_filipino",
            username: "evangeline_muse",
            firstName: "Evangeline",
            lastName: "Muse",
            bio: "Kamusta! I'm your Filipino Muse, excited to share the warmth of Tagalog with you. Tara na! ✨",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .filipino, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.filipino, .english],
            practiceLanguages: [UserLanguage(language: .filipino, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female",
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }

    // MARK: - Thai Muse

    private static func createThaiMuse() -> User {
        return User(
            id: "ai_bot_thai",
            username: "mekhala_muse",
            firstName: "Mekhala",
            lastName: "Muse",
            bio: "สวัสดีค่ะ! I'm your Thai Muse, here to help you discover the beauty of ภาษาไทย. Let's begin! ✨",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .thai, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.thai, .english],
            practiceLanguages: [UserLanguage(language: .thai, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female",
            allowNonNativeMatches: true,
            minProficiencyLevel: .beginner,
            maxProficiencyLevel: .advanced
        )
    }
}
