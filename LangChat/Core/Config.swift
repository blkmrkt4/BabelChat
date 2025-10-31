import Foundation

struct Config {
    // API Keys
    static let openRouterAPIKey: String = {
        // SECURITY: API keys must NEVER be hardcoded in source code
        // Try multiple sources in order of preference:

        // 1. Try Xcode environment variable (set in scheme)
        if let envVar = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !envVar.isEmpty {
            print("✅ Using OPENROUTER_API_KEY from Xcode environment variable")
            return envVar
        }

        // 2. Try .env file
        if let envKey = readEnvFile(key: "OPENROUTER_API_KEY"), !envKey.isEmpty {
            print("✅ Using OPENROUTER_API_KEY from .env file")
            return envKey
        }

        fatalError("""
            ❌ OPENROUTER_API_KEY not found!

            To fix this, choose ONE of these options:

            Option 1 - Xcode Environment Variables (Recommended for iOS):
            1. In Xcode, go to Product > Scheme > Edit Scheme
            2. Select "Run" on the left
            3. Go to "Arguments" tab
            4. Under "Environment Variables", click +
            5. Add: OPENROUTER_API_KEY = your-api-key-here
            6. Get your key from: https://openrouter.ai/keys

            Option 2 - .env file (Alternative):
            1. Make sure .env exists in project root: \(FileManager.default.currentDirectoryPath)
            2. Add: OPENROUTER_API_KEY=your-api-key-here
            3. Add .env as a resource in Xcode (right-click project, "Add Files")
            """)
    }()

    static let supabaseURL: String = {
        // Try Xcode environment variable first, then .env file
        if let envVar = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envVar.isEmpty {
            return envVar
        }
        guard let envURL = readEnvFile(key: "SUPABASE_URL"), !envURL.isEmpty else {
            fatalError("""
                ❌ SUPABASE_URL not found!
                Add to Xcode environment variables or .env file.
                Get it from: https://supabase.com/dashboard/project/_/settings/api
                """)
        }
        return envURL
    }()

    static let supabaseAnonKey: String = {
        // Try Xcode environment variable first, then .env file
        if let envVar = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !envVar.isEmpty {
            return envVar
        }
        guard let envKey = readEnvFile(key: "SUPABASE_ANON_KEY"), !envKey.isEmpty else {
            fatalError("""
                ❌ SUPABASE_ANON_KEY not found!
                Add to Xcode environment variables or .env file.
                Get it from: https://supabase.com/dashboard/project/_/settings/api
                """)
        }
        return envKey
    }()

    // MARK: - Helper to read .env file
    private static func readEnvFile(key: String) -> String? {
        guard let envPath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            // If .env not in bundle, try reading from project directory (development only)
            // Config.swift is at: /path/to/LangChat/LangChat/Core/Config.swift
            // We need to go up 3 levels to reach the project root where .env lives
            let projectPath = ((#file as NSString).deletingLastPathComponent as NSString)
                .deletingLastPathComponent as NSString
            let envFile = projectPath.deletingLastPathComponent.appending("/.env")

            print("🔍 DEBUG: Looking for .env at: \(envFile)")
            print("🔍 DEBUG: #file is: \(#file)")

            guard let contents = try? String(contentsOfFile: envFile, encoding: .utf8) else {
                print("❌ DEBUG: Could not read .env from file system at: \(envFile)")
                return nil
            }
            print("✅ DEBUG: Successfully read .env from file system")
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
