import Foundation

/// Service for managing app interface localization
/// Uses iOS bundle-based localization with compiled .lproj folders to provide
/// localized strings based on the user's selected interface language.
final class LocalizationService {

    // MARK: - Singleton

    static let shared = LocalizationService()

    // MARK: - Notification

    /// Posted when the interface language changes. Observers should refresh their UI.
    static let languageDidChangeNotification = Notification.Name("LocalizationServiceLanguageDidChange")

    // MARK: - Properties

    /// All available interface languages with their display names and flags
    static let availableLanguages: [(code: String, name: String, nativeName: String, flag: String)] = [
        ("en", "English", "English", "🇺🇸"),
        ("es", "Spanish", "Español", "🇪🇸"),
        ("fr", "French", "Français", "🇫🇷"),
        ("de", "German", "Deutsch", "🇩🇪"),
        ("it", "Italian", "Italiano", "🇮🇹"),
        ("pt-BR", "Portuguese (Brazil)", "Português (Brasil)", "🇧🇷"),
        ("pt-PT", "Portuguese (Portugal)", "Português (Portugal)", "🇵🇹"),
        ("ja", "Japanese", "日本語", "🇯🇵"),
        ("ko", "Korean", "한국어", "🇰🇷"),
        ("zh", "Chinese", "中文", "🇨🇳"),
        ("ru", "Russian", "Русский", "🇷🇺"),
        ("ar", "Arabic", "العربية", "🇸🇦"),
        ("hi", "Hindi", "हिन्दी", "🇮🇳"),
        ("nl", "Dutch", "Nederlands", "🇳🇱"),
        ("sv", "Swedish", "Svenska", "🇸🇪"),
        ("da", "Danish", "Dansk", "🇩🇰"),
        ("fi", "Finnish", "Suomi", "🇫🇮"),
        ("no", "Norwegian", "Norsk", "🇳🇴"),
        ("pl", "Polish", "Polski", "🇵🇱"),
        ("id", "Indonesian", "Bahasa Indonesia", "🇮🇩"),
        ("tl", "Filipino", "Filipino", "🇵🇭"),
        ("th", "Thai", "ไทย", "🇹🇭")
    ]

    /// UserDefaults key for storing the selected interface language
    private static let languageKey = "app_interface_language"

    /// The currently selected interface language code
    private(set) var currentLanguage: String {
        didSet {
            if oldValue != currentLanguage {
                UserDefaults.standard.set(currentLanguage, forKey: Self.languageKey)
                NotificationCenter.default.post(name: Self.languageDidChangeNotification, object: nil)
                print("🌐 Interface language changed to: \(currentLanguage)")
            }
        }
    }

    /// Bundle for the selected language
    private var languageBundle: Bundle?

    // MARK: - Initialization

    private init() {
        // Load saved language or default to English
        self.currentLanguage = UserDefaults.standard.string(forKey: Self.languageKey) ?? "en"
        loadLanguageBundle()
    }

    // MARK: - Private Methods

    /// Load the bundle for the current language
    private func loadLanguageBundle() {
        // Map language codes to .lproj folder names
        // Some codes need conversion (e.g., "zh" might be "zh-Hans")
        let lprojName = mapLanguageCodeToLproj(currentLanguage)

        if let path = Bundle.main.path(forResource: lprojName, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            languageBundle = bundle
            print("✅ Loaded language bundle for: \(currentLanguage) (\(lprojName).lproj)")
        } else {
            // Fallback to main bundle (will use Base or development language)
            languageBundle = Bundle.main
            print("⚠️ No .lproj found for \(currentLanguage), using main bundle")
        }
    }

    /// Map our language codes to .lproj folder names
    private func mapLanguageCodeToLproj(_ code: String) -> String {
        // Xcode may use different folder names for some languages
        switch code {
        case "zh":
            return "zh-Hans"  // Simplified Chinese
        case "pt-BR":
            return "pt-BR"
        case "pt-PT":
            return "pt-PT"
        default:
            return code
        }
    }

    // MARK: - Public Methods

    /// Set the interface language
    /// - Parameter code: The language code (e.g., "en", "es", "pt-BR")
    func setLanguage(_ code: String) {
        guard Self.availableLanguages.contains(where: { $0.code == code }) else {
            print("⚠️ Unknown language code: \(code)")
            return
        }
        currentLanguage = code
        loadLanguageBundle()
    }

    /// Get the display name for a language code
    /// - Parameter code: The language code
    /// - Returns: The display name in English, or the code if not found
    func displayName(for code: String) -> String {
        return Self.availableLanguages.first { $0.code == code }?.name ?? code
    }

    /// Get the native name for a language code
    /// - Parameter code: The language code
    /// - Returns: The native name, or the code if not found
    func nativeName(for code: String) -> String {
        return Self.availableLanguages.first { $0.code == code }?.nativeName ?? code
    }

    /// Get the flag emoji for a language code
    /// - Parameter code: The language code
    /// - Returns: The flag emoji, or empty string if not found
    func flag(for code: String) -> String {
        return Self.availableLanguages.first { $0.code == code }?.flag ?? ""
    }

    /// Get the Locale for the current language (useful for date/number formatters)
    var currentLocale: Locale {
        // Map language codes to locale identifiers
        let localeId: String
        switch currentLanguage {
        case "en": localeId = "en_US"
        case "es": localeId = "es_ES"
        case "fr": localeId = "fr_FR"
        case "de": localeId = "de_DE"
        case "it": localeId = "it_IT"
        case "pt-BR": localeId = "pt_BR"
        case "pt-PT": localeId = "pt_PT"
        case "ja": localeId = "ja_JP"
        case "ko": localeId = "ko_KR"
        case "zh": localeId = "zh_CN"
        case "ru": localeId = "ru_RU"
        case "ar": localeId = "ar_SA"
        case "hi": localeId = "hi_IN"
        case "nl": localeId = "nl_NL"
        case "sv": localeId = "sv_SE"
        case "da": localeId = "da_DK"
        case "fi": localeId = "fi_FI"
        case "no": localeId = "nb_NO"
        case "pl": localeId = "pl_PL"
        case "id": localeId = "id_ID"
        case "tl": localeId = "fil_PH"
        case "th": localeId = "th_TH"
        default: localeId = "en_US"
        }
        return Locale(identifier: localeId)
    }

    /// Get a localized string for the current language
    /// - Parameters:
    ///   - key: The string key
    ///   - fallback: Fallback value if key not found (defaults to key itself)
    /// - Returns: The localized string
    func string(for key: String, fallback: String? = nil) -> String {
        guard let bundle = languageBundle else {
            print("⚠️ Language bundle not loaded, returning key: \(key)")
            return fallback ?? key
        }

        // Use NSLocalizedString with the language-specific bundle
        let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")

        // If the value equals the key, the translation wasn't found
        if value == key {
            // Try English fallback if not already English
            if currentLanguage != "en",
               let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let enBundle = Bundle(path: enPath) {
                let enValue = enBundle.localizedString(forKey: key, value: nil, table: "Localizable")
                if enValue != key {
                    return enValue
                }
            }
            // Return fallback or key
            return fallback ?? key
        }

        return value
    }

    /// Get a localized string with placeholder substitution
    /// - Parameters:
    ///   - key: The string key
    ///   - substitutions: Dictionary of placeholder names to values (e.g., ["year": "2024"])
    /// - Returns: The localized string with placeholders replaced
    func string(for key: String, substitutions: [String: String]) -> String {
        var result = string(for: key)
        for (placeholder, value) in substitutions {
            result = result.replacingOccurrences(of: "{\(placeholder)}", with: value)
        }
        return result
    }

    /// Reload language bundle (useful for development)
    func reload() {
        loadLanguageBundle()
    }
}

// MARK: - Convenience Extension

extension String {
    /// Get the localized version of this string key
    var localized: String {
        return LocalizationService.shared.string(for: self)
    }

    /// Get the localized version of this string key with substitutions
    func localized(with substitutions: [String: String]) -> String {
        return LocalizationService.shared.string(for: self, substitutions: substitutions)
    }
}
