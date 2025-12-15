import Foundation
import NaturalLanguage

enum LanguageProficiency: String, CaseIterable, Codable {
    case beginner = "Beg"
    case intermediate = "Int"
    case advanced = "Adv"
    case native = "Native"

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .native: return "Native"
        }
    }

    var abbreviation: String {
        return self.rawValue
    }
}

enum Language: String, CaseIterable, Codable, Equatable {
    case english = "EN"
    case spanish = "ES"
    case french = "FR"
    case german = "DE"
    case japanese = "JA"
    case korean = "KO"
    case chinese = "ZH"
    case portuguese = "PT"
    case italian = "IT"
    case russian = "RU"
    case arabic = "AR"
    case hindi = "HI"
    case dutch = "NL"
    case polish = "PL"
    case turkish = "TR"
    case filipino = "TL"  // Tagalog/Filipino
    case thai = "TH"

    var code: String {
        return rawValue
    }

    var name: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .chinese: return "Chinese (Mandarin)"
        case .portuguese: return "Portuguese (BR)"
        case .italian: return "Italian"
        case .russian: return "Russian"
        case .arabic: return "Arabic"
        case .hindi: return "Hindi"
        case .dutch: return "Dutch"
        case .polish: return "Polish"
        case .turkish: return "Turkish"
        case .filipino: return "Filipino"
        case .thai: return "Thai"
        }
    }

    var nativeName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chinese: return "中文"
        case .portuguese: return "Português"
        case .italian: return "Italiano"
        case .russian: return "Русский"
        case .arabic: return "العربية"
        case .hindi: return "हिन्दी"
        case .dutch: return "Nederlands"
        case .polish: return "Polski"
        case .turkish: return "Türkçe"
        case .filipino: return "Filipino"
        case .thai: return "ไทย"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .portuguese: return "🇵🇹"
        case .italian: return "🇮🇹"
        case .russian: return "🇷🇺"
        case .arabic: return "🇸🇦"
        case .hindi: return "🇮🇳"
        case .dutch: return "🇳🇱"
        case .polish: return "🇵🇱"
        case .turkish: return "🇹🇷"
        case .filipino: return "🇵🇭"
        case .thai: return "🇹🇭"
        }
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
        case "ja": return .japanese
        case "ko": return .korean
        case "zh", "zh-hans", "zh-hant": return .chinese
        case "pt": return .portuguese
        case "it": return .italian
        case "ru": return .russian
        case "ar": return .arabic
        case "hi": return .hindi
        case "nl": return .dutch
        case "pl": return .polish
        case "tr": return .turkish
        case "tl", "fil": return .filipino
        case "th": return .thai
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
        case "japanese": return .japanese
        case "korean": return .korean
        case "chinese", "chinese (mandarin)", "mandarin": return .chinese
        case "portuguese": return .portuguese
        case "italian": return .italian
        case "russian": return .russian
        case "arabic": return .arabic
        case "hindi": return .hindi
        case "dutch": return .dutch
        case "polish": return .polish
        case "turkish": return .turkish
        case "filipino", "tagalog": return .filipino
        case "thai": return .thai
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