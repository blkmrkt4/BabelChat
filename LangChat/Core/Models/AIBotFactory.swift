import Foundation

/// Muse configuration from database
struct MuseConfig {
    let languageCode: String
    let languageName: String
    let maleName: String?
    let femaleName: String?
    let maleVoiceName: String?
    let femaleVoiceName: String?
    let isMuseLanguage: Bool
}

/// Factory for creating AI Muses - creative language practice partners
class AIBotFactory {

    // MARK: - Cached Muse Configurations

    /// Cached configurations from database (keyed by language code)
    private static var museConfigs: [String: MuseConfig] = [:]

    /// Whether configs have been loaded from database
    private static var configsLoaded = false

    // MARK: - Database Fetching

    /// Load Muse configurations from database (tts_voices table)
    static func loadMuseConfigs() async {
        guard !configsLoaded else { return }

        do {
            let voices = try await SupabaseService.shared.getTTSVoices()
            for voice in voices {
                guard voice.isMuseLanguageEnabled else { continue }

                let config = MuseConfig(
                    languageCode: voice.languageCode,
                    languageName: voice.languageName,
                    maleName: voice.maleMuseName,
                    femaleName: voice.femaleMuseName,
                    maleVoiceName: voice.maleVoiceName,
                    femaleVoiceName: voice.femaleVoiceName,
                    isMuseLanguage: voice.isMuseLanguageEnabled
                )
                museConfigs[voice.languageCode] = config
            }
            configsLoaded = true
            print("✅ Loaded \(museConfigs.count) Muse configurations from database")
        } catch {
            print("⚠️ Failed to load Muse configs from database, using defaults: \(error)")
        }
    }

    /// Get Muse config for a language (from cache or fallback to default)
    static func getMuseConfig(for languageCode: String) -> MuseConfig? {
        return museConfigs[languageCode]
    }

    // MARK: - Muse Creation

    /// Create multiple AI Muses for different languages using default (female) gender
    static func createAIBots() -> [User] {
        return createAIBots(preferredGender: .female)
    }

    /// Create multiple AI Muses for different languages with specified gender preference
    static func createAIBots(preferredGender: MuseGenderPreference) -> [User] {
        return [
            createEnglishMuse(gender: preferredGender),
            createSpanishMuse(gender: preferredGender),
            createFrenchMuse(gender: preferredGender),
            createGermanMuse(gender: preferredGender),
            createPortugueseMuse(gender: preferredGender),
            createPortuguesePortugalMuse(gender: preferredGender),
            createItalianMuse(gender: preferredGender),
            createJapaneseMuse(gender: preferredGender),
            createKoreanMuse(gender: preferredGender),
            createDutchMuse(gender: preferredGender),
            createMandarinMuse(gender: preferredGender),
            createRussianMuse(gender: preferredGender),
            createPolishMuse(gender: preferredGender),
            createHindiMuse(gender: preferredGender),
            createIndonesianMuse(gender: preferredGender),
            createFilipinoMuse(gender: preferredGender),
            createSwedishMuse(gender: preferredGender),
            createDanishMuse(gender: preferredGender),
            createFinnishMuse(gender: preferredGender),
            createNorwegianMuse(gender: preferredGender),
            createArabicMuse(gender: preferredGender)
        ]
    }

    /// Get the Muse for a specific language (uses default female gender)
    static func getMuse(for language: Language) -> User? {
        return getMuse(for: language, preferredGender: .female)
    }

    /// Get the Muse for a specific language with specified gender preference
    static func getMuse(for language: Language, preferredGender: MuseGenderPreference) -> User? {
        return createAIBots(preferredGender: preferredGender).first { $0.nativeLanguage.language == language }
    }

    // MARK: - Helper for creating Muse with database config

    /// Get the name for a Muse based on language and gender preference
    private static func getMuseName(languageCode: String, gender: MuseGenderPreference, defaultMale: String, defaultFemale: String) -> String {
        if let config = museConfigs[languageCode] {
            switch gender {
            case .male:
                return config.maleName ?? defaultMale
            case .female:
                return config.femaleName ?? defaultFemale
            }
        }
        // Fall back to defaults if not in database
        return gender == .male ? defaultMale : defaultFemale
    }

    // MARK: - English Muse

    private static func createEnglishMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "en", gender: gender, defaultMale: "James", defaultFemale: "Emma")
        return User(
            id: "ai_bot_english_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Spanish Muse

    private static func createSpanishMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "es", gender: gender, defaultMale: "Carlos", defaultFemale: "Maria")
        return User(
            id: "ai_bot_spanish_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - French Muse

    private static func createFrenchMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "fr", gender: gender, defaultMale: "Pierre", defaultFemale: "Sophie")
        return User(
            id: "ai_bot_french_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - German Muse

    private static func createGermanMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "de", gender: gender, defaultMale: "Max", defaultFemale: "Anna")
        return User(
            id: "ai_bot_german_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Portuguese Muse

    private static func createPortugueseMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "pt", gender: gender, defaultMale: "Lucas", defaultFemale: "Racquel")
        return User(
            id: "ai_bot_portuguese_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Portuguese (Portugal) Muse

    private static func createPortuguesePortugalMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "pt-pt", gender: gender, defaultMale: "Tiago", defaultFemale: "Sofia")
        return User(
            id: "ai_bot_portuguese_portugal_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
            lastName: "Muse",
            bio: "Ola! I'm your European Portuguese Muse, here to guide you through the beautiful sounds of portugues europeu. Vamos la!",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .portuguesePortugal, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.portuguesePortugal, .english],
            practiceLanguages: [UserLanguage(language: .portuguesePortugal, proficiency: .native, isNative: true)],
            location: "Your Imagination",
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: true,
            isAI: true,
            gender: gender.rawValue
        )
    }

    // MARK: - Italian Muse

    private static func createItalianMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "it", gender: gender, defaultMale: "Marco", defaultFemale: "Giulia")
        return User(
            id: "ai_bot_italian_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Japanese Muse

    private static func createJapaneseMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "ja", gender: gender, defaultMale: "Kenji", defaultFemale: "Yuki")
        return User(
            id: "ai_bot_japanese_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Korean Muse

    private static func createKoreanMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "ko", gender: gender, defaultMale: "Minho", defaultFemale: "Jiwoo")
        return User(
            id: "ai_bot_korean_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Dutch Muse

    private static func createDutchMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "nl", gender: gender, defaultMale: "Lars", defaultFemale: "Emma")
        return User(
            id: "ai_bot_dutch_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Mandarin Muse

    private static func createMandarinMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "zh", gender: gender, defaultMale: "Wei", defaultFemale: "Lin")
        return User(
            id: "ai_bot_mandarin_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Russian Muse

    private static func createRussianMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "ru", gender: gender, defaultMale: "Dmitri", defaultFemale: "Natasha")
        return User(
            id: "ai_bot_russian_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Polish Muse

    private static func createPolishMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "pl", gender: gender, defaultMale: "Jakub", defaultFemale: "Kasia")
        return User(
            id: "ai_bot_polish_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Hindi Muse

    private static func createHindiMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "hi", gender: gender, defaultMale: "Arjun", defaultFemale: "Poonam")
        return User(
            id: "ai_bot_hindi_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Indonesian Muse

    private static func createIndonesianMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "id", gender: gender, defaultMale: "Budi", defaultFemale: "Dewi")
        return User(
            id: "ai_bot_indonesian_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Filipino Muse

    private static func createFilipinoMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "tl", gender: gender, defaultMale: "Miguel", defaultFemale: "Evangeline")
        return User(
            id: "ai_bot_filipino_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Swedish Muse

    private static func createSwedishMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "sv", gender: gender, defaultMale: "Erik", defaultFemale: "Astrid")
        return User(
            id: "ai_bot_swedish_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Danish Muse

    private static func createDanishMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "da", gender: gender, defaultMale: "Magnus", defaultFemale: "Freja")
        return User(
            id: "ai_bot_danish_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Finnish Muse

    private static func createFinnishMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "fi", gender: gender, defaultMale: "Mikko", defaultFemale: "Aino")
        return User(
            id: "ai_bot_finnish_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Norwegian Muse

    private static func createNorwegianMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "no", gender: gender, defaultMale: "Lars", defaultFemale: "Ingrid")
        return User(
            id: "ai_bot_norwegian_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }

    // MARK: - Arabic Muse

    private static func createArabicMuse(gender: MuseGenderPreference = .female) -> User {
        let name = getMuseName(languageCode: "ar", gender: gender, defaultMale: "Omar", defaultFemale: "Layla")
        return User(
            id: "ai_bot_arabic_\(gender.rawValue)",
            username: "\(name.lowercased())_muse",
            firstName: name,
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
            gender: gender.rawValue
        )
    }
}
