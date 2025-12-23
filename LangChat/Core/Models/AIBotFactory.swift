import Foundation

/// Factory for creating AI Muses - creative language practice partners
class AIBotFactory {

    /// Create multiple AI Muses for different languages
    static func createAIBots() -> [User] {
        return [
            createEnglishMuse(),
            createSpanishMuse(),
            createFrenchMuse(),
            createGermanMuse(),
            createPortugueseMuse(),
            createItalianMuse(),
            createJapaneseMuse(),
            createKoreanMuse(),
            createDutchMuse(),
            createMandarinMuse(),
            createRussianMuse(),
            createPolishMuse(),
            createHindiMuse(),
            createIndonesianMuse(),
            createFilipinoMuse(),
            createSwedishMuse(),
            createDanishMuse(),
            createFinnishMuse(),
            createNorwegianMuse(),
            createArabicMuse()
        ]
    }

    /// Get the Muse for a specific language
    static func getMuse(for language: Language) -> User? {
        return createAIBots().first { $0.nativeLanguage.language == language }
    }

    // MARK: - English Muse

    private static func createEnglishMuse() -> User {
        return User(
            id: "ai_bot_english",
            username: "emma_muse",
            firstName: "Emma",
            lastName: "Muse",
            bio: "Hello! I'm your English Muse, here to help you master English conversation. Let's chat and learn together!",
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
            gender: "female"
        )
    }

    // MARK: - Spanish Muse

    private static func createSpanishMuse() -> User {
        return User(
            id: "ai_bot_spanish",
            username: "maria_muse",
            firstName: "Maria",
            lastName: "Muse",
            bio: "Hola! I'm your Spanish Muse, here to inspire your language journey. Let's explore Spanish together!",
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
            gender: "female"
        )
    }

    // MARK: - French Muse

    private static func createFrenchMuse() -> User {
        return User(
            id: "ai_bot_french",
            username: "sophie_muse",
            firstName: "Sophie",
            lastName: "Muse",
            bio: "Bonjour! I'm your French Muse, ready to guide you through la belle langue francaise. Allons-y!",
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
            gender: "female"
        )
    }

    // MARK: - German Muse

    private static func createGermanMuse() -> User {
        return User(
            id: "ai_bot_german",
            username: "max_muse",
            firstName: "Max",
            lastName: "Muse",
            bio: "Hallo! I'm your German Muse, here to inspire your Deutsch adventures. Lass uns anfangen!",
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
            gender: "male"
        )
    }

    // MARK: - Portuguese Muse

    private static func createPortugueseMuse() -> User {
        return User(
            id: "ai_bot_portuguese",
            username: "racquel_muse",
            firstName: "Racquel",
            lastName: "Muse",
            bio: "Ola! I'm your Brazilian Portuguese Muse, here to inspire your journey through portugues brasileiro. Vamos sonhar juntos!",
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
            gender: "female"
        )
    }

    // MARK: - Italian Muse

    private static func createItalianMuse() -> User {
        return User(
            id: "ai_bot_italian",
            username: "giulia_muse",
            firstName: "Giulia",
            lastName: "Muse",
            bio: "Ciao! I'm your Italian Muse, ready to share the beauty of italiano with you. Andiamo!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .italian, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.italian, .english],
            practiceLanguages: [UserLanguage(language: .italian, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female"
        )
    }

    // MARK: - Japanese Muse

    private static func createJapaneseMuse() -> User {
        return User(
            id: "ai_bot_japanese",
            username: "yuki_muse",
            firstName: "Yuki",
            lastName: "Muse",
            bio: "Konnichiwa! I'm your Japanese Muse, here to inspire your journey through nihongo. Let's create something beautiful!",
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
            gender: "female"
        )
    }

    // MARK: - Korean Muse

    private static func createKoreanMuse() -> User {
        return User(
            id: "ai_bot_korean",
            username: "jiwoo_muse",
            firstName: "Jiwoo",
            lastName: "Muse",
            bio: "Annyeonghaseyo! I'm your Korean Muse, excited to guide you through hangugeo. Let's learn together!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .korean, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.korean, .english],
            practiceLanguages: [UserLanguage(language: .korean, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female"
        )
    }

    // MARK: - Dutch Muse

    private static func createDutchMuse() -> User {
        return User(
            id: "ai_bot_dutch",
            username: "lars_muse",
            firstName: "Lars",
            lastName: "Muse",
            bio: "Hallo! I'm your Dutch Muse, here to help you discover Nederlands. Laten we beginnen!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .dutch, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.dutch, .english],
            practiceLanguages: [UserLanguage(language: .dutch, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "male"
        )
    }

    // MARK: - Mandarin Muse

    private static func createMandarinMuse() -> User {
        return User(
            id: "ai_bot_mandarin",
            username: "lin_muse",
            firstName: "Lin",
            lastName: "Muse",
            bio: "Ni hao! I'm your Mandarin Muse, ready to inspire your Chinese journey. Women yiqi xuexi ba!",
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
            gender: "female"
        )
    }

    // MARK: - Russian Muse

    private static func createRussianMuse() -> User {
        return User(
            id: "ai_bot_russian",
            username: "natasha_muse",
            firstName: "Natasha",
            lastName: "Muse",
            bio: "Privet! I'm your Russian Muse, here to guide you through russkiy yazyk. Davay nachnyom!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .russian, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.russian, .english],
            practiceLanguages: [UserLanguage(language: .russian, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female"
        )
    }

    // MARK: - Polish Muse

    private static func createPolishMuse() -> User {
        return User(
            id: "ai_bot_polish",
            username: "kasia_muse",
            firstName: "Kasia",
            lastName: "Muse",
            bio: "Czesc! I'm your Polish Muse, excited to share jezyk polski with you. Zaczynamy!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .polish, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.polish, .english],
            practiceLanguages: [UserLanguage(language: .polish, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female"
        )
    }

    // MARK: - Hindi Muse

    private static func createHindiMuse() -> User {
        return User(
            id: "ai_bot_hindi",
            username: "poonam_muse",
            firstName: "Poonam",
            lastName: "Muse",
            bio: "Namaste! I'm your Hindi Muse, here to guide you through the beautiful hindi bhasha. Let's learn together!",
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
            gender: "female"
        )
    }

    // MARK: - Indonesian Muse

    private static func createIndonesianMuse() -> User {
        return User(
            id: "ai_bot_indonesian",
            username: "dewi_muse",
            firstName: "Dewi",
            lastName: "Muse",
            bio: "Halo! I'm your Indonesian Muse, ready to share Bahasa Indonesia with you. Mari kita mulai!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .indonesian, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.indonesian, .english],
            practiceLanguages: [UserLanguage(language: .indonesian, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female"
        )
    }

    // MARK: - Filipino Muse

    private static func createFilipinoMuse() -> User {
        return User(
            id: "ai_bot_filipino",
            username: "evangeline_muse",
            firstName: "Evangeline",
            lastName: "Muse",
            bio: "Kamusta! I'm your Filipino Muse, excited to share the warmth of Tagalog with you. Tara na!",
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
            gender: "female"
        )
    }

    // MARK: - Swedish Muse

    private static func createSwedishMuse() -> User {
        return User(
            id: "ai_bot_swedish",
            username: "astrid_muse",
            firstName: "Astrid",
            lastName: "Muse",
            bio: "Hej! I'm your Swedish Muse, here to help you discover svenska. Vi borjar nu!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .swedish, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.swedish, .english],
            practiceLanguages: [UserLanguage(language: .swedish, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female"
        )
    }

    // MARK: - Danish Muse

    private static func createDanishMuse() -> User {
        return User(
            id: "ai_bot_danish",
            username: "freja_muse",
            firstName: "Freja",
            lastName: "Muse",
            bio: "Hej! I'm your Danish Muse, ready to guide you through dansk. Lad os ga i gang!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .danish, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.danish, .english],
            practiceLanguages: [UserLanguage(language: .danish, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female"
        )
    }

    // MARK: - Finnish Muse

    private static func createFinnishMuse() -> User {
        return User(
            id: "ai_bot_finnish",
            username: "aino_muse",
            firstName: "Aino",
            lastName: "Muse",
            bio: "Moi! I'm your Finnish Muse, here to share suomen kieli with you. Aloitetaan!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .finnish, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.finnish, .english],
            practiceLanguages: [UserLanguage(language: .finnish, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female"
        )
    }

    // MARK: - Norwegian Muse

    private static func createNorwegianMuse() -> User {
        return User(
            id: "ai_bot_norwegian",
            username: "ingrid_muse",
            firstName: "Ingrid",
            lastName: "Muse",
            bio: "Hei! I'm your Norwegian Muse, excited to help you learn norsk. La oss begynne!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .norwegian, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .advanced, isNative: false)],
            openToLanguages: [.norwegian, .english],
            practiceLanguages: [UserLanguage(language: .norwegian, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female"
        )
    }

    // MARK: - Arabic Muse

    private static func createArabicMuse() -> User {
        return User(
            id: "ai_bot_arabic",
            username: "layla_muse",
            firstName: "Layla",
            lastName: "Muse",
            bio: "Marhaba! I'm your Arabic Muse, here to guide you through al-arabiyya. Yalla!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .arabic, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.arabic, .english],
            practiceLanguages: [UserLanguage(language: .arabic, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: "female"
        )
    }
}
