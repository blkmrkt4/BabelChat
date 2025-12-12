import Foundation

struct Config {

    // MARK: - API Keys (read from Info.plist, populated by Secrets.xcconfig)

    static let openRouterAPIKey: String = {
        guard let key = infoPlistValue(for: "OPENROUTER_API_KEY") else {
            fatalError("""
                ❌ OPENROUTER_API_KEY not found in Info.plist!

                Make sure:
                1. Secrets.xcconfig exists in project root with OPENROUTER_API_KEY = your-key
                2. Secrets.xcconfig is set as the configuration file in Xcode project settings

                Get your key from: https://openrouter.ai/keys
                """)
        }
        print("✅ Loaded OPENROUTER_API_KEY from Info.plist")
        return key
    }()

    static let supabaseURL: String = {
        guard let url = infoPlistValue(for: "SUPABASE_URL") else {
            fatalError("""
                ❌ SUPABASE_URL not found in Info.plist!

                Make sure:
                1. Secrets.xcconfig exists in project root with SUPABASE_URL = your-url
                2. Secrets.xcconfig is set as the configuration file in Xcode project settings

                Get it from: https://supabase.com/dashboard/project/_/settings/api
                """)
        }
        print("✅ Loaded SUPABASE_URL from Info.plist: \(url)")
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = infoPlistValue(for: "SUPABASE_ANON_KEY") else {
            fatalError("""
                ❌ SUPABASE_ANON_KEY not found in Info.plist!

                Make sure:
                1. Secrets.xcconfig exists in project root with SUPABASE_ANON_KEY = your-key
                2. Secrets.xcconfig is set as the configuration file in Xcode project settings

                Get it from: https://supabase.com/dashboard/project/_/settings/api
                """)
        }
        print("✅ Loaded SUPABASE_ANON_KEY from Info.plist")
        return key
    }()

    static let revenueCatAPIKey: String? = {
        return infoPlistValue(for: "REVENUECAT_API_KEY")
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
