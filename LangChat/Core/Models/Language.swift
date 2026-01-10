import Foundation
import NaturalLanguage

enum LanguageProficiency: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case native = "native"

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .native: return "Native"
        }
    }

    var abbreviation: String {
        switch self {
        case .beginner: return "Beg"
        case .intermediate: return "Int"
        case .advanced: return "Adv"
        case .native: return "Native"
        }
    }

    /// Decode from legacy values (Beg, Int, Adv, Native) or new values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        // Try new format first
        if let value = LanguageProficiency(rawValue: rawValue) {
            self = value
            return
        }

        // Fall back to legacy format
        switch rawValue {
        case "Beg": self = .beginner
        case "Int": self = .intermediate
        case "Adv": self = .advanced
        case "Native": self = .native
        default:
            // Try case-insensitive match
            if let match = LanguageProficiency.allCases.first(where: {
                $0.rawValue.lowercased() == rawValue.lowercased() ||
                $0.displayName.lowercased() == rawValue.lowercased()
            }) {
                self = match
            } else {
                self = .beginner // Default fallback
            }
        }
    }
}

enum Language: String, CaseIterable, Codable, Equatable {
    case english = "EN"
    case spanish = "ES"
    case french = "FR"
    case german = "DE"
    case portuguese = "PT"      // Brazilian Portuguese
    case portuguesePortugal = "PT-PT"  // European Portuguese
    case italian = "IT"
    case japanese = "JA"
    case korean = "KO"
    case dutch = "NL"
    case chinese = "ZH"         // Mandarin Chinese
    case russian = "RU"
    case polish = "PL"
    case hindi = "HI"
    case indonesian = "ID"
    case filipino = "TL"        // Tagalog/Filipino
    case swedish = "SV"
    case danish = "DA"
    case finnish = "FI"
    case norwegian = "NO"
    case arabic = "AR"

    var code: String {
        return rawValue
    }

    var name: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .portuguese: return "Portuguese (BR)"
        case .portuguesePortugal: return "Portuguese (PT)"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .dutch: return "Dutch"
        case .chinese: return "Mandarin Chinese"
        case .russian: return "Russian"
        case .polish: return "Polish"
        case .hindi: return "Hindi"
        case .indonesian: return "Indonesian"
        case .filipino: return "Filipino"
        case .swedish: return "Swedish"
        case .danish: return "Danish"
        case .finnish: return "Finnish"
        case .norwegian: return "Norwegian"
        case .arabic: return "Arabic"
        }
    }

    var nativeName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .portuguese: return "Português (BR)"
        case .portuguesePortugal: return "Português (PT)"
        case .italian: return "Italiano"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .dutch: return "Nederlands"
        case .chinese: return "中文"
        case .russian: return "Русский"
        case .polish: return "Polski"
        case .hindi: return "हिन्दी"
        case .indonesian: return "Bahasa Indonesia"
        case .filipino: return "Filipino"
        case .swedish: return "Svenska"
        case .danish: return "Dansk"
        case .finnish: return "Suomi"
        case .norwegian: return "Norsk"
        case .arabic: return "العربية"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .portuguese: return "🇧🇷"
        case .portuguesePortugal: return "🇵🇹"
        case .italian: return "🇮🇹"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .dutch: return "🇳🇱"
        case .chinese: return "🇨🇳"
        case .russian: return "🇷🇺"
        case .polish: return "🇵🇱"
        case .hindi: return "🇮🇳"
        case .indonesian: return "🇮🇩"
        case .filipino: return "🇵🇭"
        case .swedish: return "🇸🇪"
        case .danish: return "🇩🇰"
        case .finnish: return "🇫🇮"
        case .norwegian: return "🇳🇴"
        case .arabic: return "🇸🇦"
        }
    }

    /// Languages available for Muse (AI language tutors)
    static var museLanguages: [Language] {
        return [
            .english, .spanish, .french, .german, .portuguese, .portuguesePortugal, .italian,
            .japanese, .korean, .dutch, .chinese, .russian,
            .polish, .hindi, .indonesian, .filipino,
            .swedish, .danish, .finnish, .norwegian, .arabic
        ]
    }

    // MARK: - Language Detection

    /// Detect the language of a text string using iOS's NaturalLanguage framework
    /// - Parameter text: The text to analyze
    /// - Returns: The detected Language, or nil if unable to detect
    static func detect(from text: String) -> Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let languageCode = recognizer.dominantLanguage?.rawValue else {
            return nil
        }

        return Language.from(languageCode: languageCode)
    }

    /// Map a language code (e.g., "es", "en") to a Language enum case
    /// - Parameter languageCode: ISO language code
    /// - Returns: Corresponding Language case, or nil if not supported
    static func from(languageCode: String) -> Language? {
        switch languageCode.lowercased() {
        case "en": return .english
        case "es": return .spanish
        case "fr": return .french
        case "de": return .german
        case "pt", "pt-br": return .portuguese
        case "pt-pt": return .portuguesePortugal
        case "it": return .italian
        case "ja": return .japanese
        case "ko": return .korean
        case "nl": return .dutch
        case "zh", "zh-hans", "zh-hant", "cmn": return .chinese
        case "ru": return .russian
        case "pl": return .polish
        case "hi": return .hindi
        case "id": return .indonesian
        case "tl", "fil": return .filipino
        case "sv": return .swedish
        case "da": return .danish
        case "fi": return .finnish
        case "no", "nb", "nn": return .norwegian
        case "ar": return .arabic
        default: return nil
        }
    }

    /// Map a language name (e.g., "English", "Spanish") to a Language enum case
    /// - Parameter name: Full language name
    /// - Returns: Corresponding Language case, or nil if not supported
    static func from(name: String) -> Language? {
        switch name.lowercased() {
        case "english": return .english
        case "spanish": return .spanish
        case "french": return .french
        case "german": return .german
        case "portuguese", "portuguese (br)", "brazilian portuguese": return .portuguese
        case "portuguese (pt)", "portuguese (portugal)", "european portuguese": return .portuguesePortugal
        case "italian": return .italian
        case "japanese": return .japanese
        case "korean": return .korean
        case "dutch": return .dutch
        case "chinese", "chinese (mandarin)", "mandarin", "mandarin chinese": return .chinese
        case "russian": return .russian
        case "polish": return .polish
        case "hindi": return .hindi
        case "indonesian", "bahasa indonesia": return .indonesian
        case "filipino", "tagalog": return .filipino
        case "swedish": return .swedish
        case "danish": return .danish
        case "finnish": return .finnish
        case "norwegian": return .norwegian
        case "arabic": return .arabic
        default: return nil
        }
    }
}

struct UserLanguage: Codable {
    let language: Language
    let proficiency: LanguageProficiency
    let isNative: Bool

    var displayCode: String {
        return language.code
    }

    var displayProficiency: String {
        return proficiency.abbreviation
    }
}