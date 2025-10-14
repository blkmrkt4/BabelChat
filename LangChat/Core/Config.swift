import Foundation

struct Config {
    // API Keys
    static let openRouterAPIKey: String = {
        // Try to read from .env file first
        if let envKey = readEnvFile(key: "OpenRouter_API_KEY") {
            return envKey
        }
        // Development fallback - replace with your actual key
        // In production, this should be stored securely (Keychain, environment variables, etc.)
        return "sk-or-v1-REDACTED-KEY-REMOVED"
    }()

    static let supabaseURL: String = {
        if let envURL = readEnvFile(key: "SUPABASE_URL") {
            return envURL
        }
        return ""
    }()

    static let supabaseAnonKey: String = {
        if let envKey = readEnvFile(key: "SUPABASE_ANON_KEY") {
            return envKey
        }
        return ""
    }()

    // MARK: - Helper to read .env file
    private static func readEnvFile(key: String) -> String? {
        guard let envPath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            // If .env not in bundle, try reading from project directory (development only)
            let projectPath = (#file as NSString).deletingLastPathComponent
            let envFile = (projectPath as NSString).deletingLastPathComponent.appending("/.env")

            guard let contents = try? String(contentsOfFile: envFile, encoding: .utf8) else {
                return nil
            }
            return parseEnv(contents: contents, key: key)
        }

        guard let contents = try? String(contentsOfFile: envPath, encoding: .utf8) else {
            return nil
        }

        return parseEnv(contents: contents, key: key)
    }

    private static func parseEnv(contents: String, key: String) -> String? {
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") || trimmed.isEmpty {
                continue
            }

            let parts = trimmed.components(separatedBy: "=")
            if parts.count >= 2 {
                let envKey = parts[0].trimmingCharacters(in: .whitespaces)
                let envValue = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces)
                if envKey == key {
                    return envValue
                }
            }
        }
        return nil
    }
}
