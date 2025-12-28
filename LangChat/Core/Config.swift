import Foundation

struct Config {

    // MARK: - Configuration Validation

    /// Check if all required configuration is present
    static var isConfigured: Bool {
        return !openRouterAPIKey.isEmpty && !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }

    /// Returns a list of missing configuration keys for debugging
    static var missingConfigKeys: [String] {
        var missing: [String] = []
        if openRouterAPIKey.isEmpty { missing.append("OPENROUTER_API_KEY") }
        if supabaseURL.isEmpty { missing.append("SUPABASE_URL") }
        if supabaseAnonKey.isEmpty { missing.append("SUPABASE_ANON_KEY") }
        return missing
    }

    // MARK: - API Keys (read from Info.plist, populated by Secrets.xcconfig)

    static let openRouterAPIKey: String = {
        guard let key = infoPlistValue(for: "OPENROUTER_API_KEY") else {
            print("""
                ⚠️ OPENROUTER_API_KEY not found in Info.plist!

                Make sure:
                1. Secrets.xcconfig exists in project root with OPENROUTER_API_KEY = your-key
                2. Secrets.xcconfig is set as the configuration file in Xcode project settings

                Get your key from: https://openrouter.ai/keys
                """)
            return ""
        }
        print("✅ Loaded OPENROUTER_API_KEY from Info.plist")
        return key
    }()

    static let supabaseURL: String = {
        guard let url = infoPlistValue(for: "SUPABASE_URL") else {
            print("""
                ⚠️ SUPABASE_URL not found in Info.plist!

                Make sure:
                1. Secrets.xcconfig exists in project root with SUPABASE_URL = your-url
                2. Secrets.xcconfig is set as the configuration file in Xcode project settings

                Get it from: https://supabase.com/dashboard/project/_/settings/api
                """)
            return ""
        }
        print("✅ Loaded SUPABASE_URL from Info.plist: \(url)")
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = infoPlistValue(for: "SUPABASE_ANON_KEY") else {
            print("""
                ⚠️ SUPABASE_ANON_KEY not found in Info.plist!

                Make sure:
                1. Secrets.xcconfig exists in project root with SUPABASE_ANON_KEY = your-key
                2. Secrets.xcconfig is set as the configuration file in Xcode project settings

                Get it from: https://supabase.com/dashboard/project/_/settings/api
                """)
            return ""
        }
        print("✅ Loaded SUPABASE_ANON_KEY from Info.plist")
        return key
    }()

    static let revenueCatAPIKey: String? = {
        return infoPlistValue(for: "REVENUECAT_API_KEY")
    }()

    static let googleCloudAPIKey: String? = {
        let rawValue = Bundle.main.infoDictionary?["GOOGLE_CLOUD_API_KEY"] as? String
        print("🔑 Config: GOOGLE_CLOUD_API_KEY raw value: '\(rawValue ?? "nil")'")

        if let value = rawValue, !value.isEmpty, !value.hasPrefix("$(") {
            print("🔑 Config: Google API key loaded successfully (\(value.prefix(10))...)")
            return value
        }
        print("⚠️ Config: Google API key NOT found or not substituted")
        return nil
    }()

    // MARK: - Helper to read from Info.plist

    private static func infoPlistValue(for key: String) -> String? {
        guard let value = Bundle.main.infoDictionary?[key] as? String,
              !value.isEmpty,
              !value.hasPrefix("$(") else {  // Check for unsubstituted variable
            return nil
        }
        return value
    }
}
