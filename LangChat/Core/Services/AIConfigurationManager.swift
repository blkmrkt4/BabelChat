import Foundation

/// Manages AI model configurations for different categories (translation, grammar, scoring)
/// Provides access to saved models and their prompts for use throughout the app
class AIConfigurationManager {
    static let shared = AIConfigurationManager()

    private init() {}

    // MARK: - Resilient Model Execution

    /// Execute a chat completion with automatic fallback to backup models
    /// Tries primary model first, then fallback models in order if primary fails
    private func executeWithFallback(
        config: AIConfig,
        messages: [ChatMessage],
        temperature: Double,
        maxTokens: Int
    ) async throws -> String {
        // Build list of models to try (primary + fallbacks)
        var modelsToTry: [(id: String, name: String)] = [(config.modelId, config.modelName)]

        if let fb1 = config.fallbackModel1Id, !fb1.isEmpty {
            modelsToTry.append((fb1, config.fallbackModel1Name ?? fb1))
        }
        if let fb2 = config.fallbackModel2Id, !fb2.isEmpty {
            modelsToTry.append((fb2, config.fallbackModel2Name ?? fb2))
        }
        if let fb3 = config.fallbackModel3Id, !fb3.isEmpty {
            modelsToTry.append((fb3, config.fallbackModel3Name ?? fb3))
        }

        var lastError: Error?

        for (index, model) in modelsToTry.enumerated() {
            do {
                if index > 0 {
                    print("⚠️ Primary model failed, trying fallback \(index): \(model.name)")
                }

                let response = try await OpenRouterService.shared.sendChatCompletion(
                    model: model.id,
                    messages: messages,
                    temperature: temperature,
                    maxTokens: maxTokens
                )

                guard let content = response.choices?.first?.content else {
                    throw AIConfigurationError.emptyResponse
                }

                if index > 0 {
                    print("✅ Fallback model \(model.name) succeeded")
                }

                return content
            } catch {
                print("❌ Model \(model.name) failed: \(error.localizedDescription)")
                lastError = error
                // Continue to next model
            }
        }

        // All models failed
        throw lastError ?? AIConfigurationError.allModelsFailed
    }

    // MARK: - Configuration Retrieval

    /// Get the configuration for a specific category from Supabase
    /// Falls back to hardcoded defaults if Supabase is unavailable
    /// - Parameter category: The category (translation, grammar, scoring)
    /// - Returns: AIConfig from Supabase or fallback
    func getConfiguration(for category: AICategory) async throws -> AIConfig {
        do {
            return try await AIConfigService.shared.getConfiguration(for: category)
        } catch {
            print("⚠️ Failed to fetch AI config from Supabase: \(error). Using fallback.")
            return AIConfigService.shared.getFallbackConfiguration(for: category)
        }
    }

    /// Force refresh configurations from Supabase
    /// Bypasses the 24-hour cache
    func refreshConfigurations() async throws {
        try await AIConfigService.shared.refreshAllConfigurations()
    }

    // MARK: - Prompt Processing

    /// Replace language placeholders in a prompt template
    /// - Parameters:
    ///   - template: The prompt template with {learning_language}, {native_language}, and {explanation_language} placeholders
    ///   - learningLanguage: The language being learned (e.g., "Spanish", "French")
    ///   - nativeLanguage: The user's native language (e.g., "English")
    ///   - explanationLanguage: The language for explanations (defaults to nativeLanguage if not specified)
    /// - Returns: The prompt with placeholders replaced
    func fillPromptTemplate(_ template: String, learningLanguage: String, nativeLanguage: String, explanationLanguage: String? = nil) -> String {
        return template
            .replacingOccurrences(of: "{learning_language}", with: learningLanguage)
            .replacingOccurrences(of: "{native_language}", with: nativeLanguage)
            .replacingOccurrences(of: "{explanation_language}", with: explanationLanguage ?? nativeLanguage)
    }

    // MARK: - Translation

    /// Translate text using the configured translation model
    /// Automatically falls back to backup models if primary fails
    /// - Parameters:
    ///   - text: The text to translate
    ///   - learningLanguage: Source language (language being learned)
    ///   - nativeLanguage: Target language (user's native language)
    /// - Returns: Translated text
    func translate(text: String, learningLanguage: String, nativeLanguage: String) async throws -> String {
        let config = try await getConfiguration(for: .translation)

        let prompt = fillPromptTemplate(config.promptTemplate, learningLanguage: learningLanguage, nativeLanguage: nativeLanguage)

        let messages = [
            ChatMessage(role: "system", content: prompt),
            ChatMessage(role: "user", content: text)
        ]

        return try await executeWithFallback(
            config: config,
            messages: messages,
            temperature: Double(config.temperature),
            maxTokens: config.maxTokens
        )
    }

    // MARK: - Grammar Check

    /// Check grammar using the configured grammar model
    /// Automatically falls back to backup models if primary fails
    /// - Parameters:
    ///   - text: The text to check
    ///   - learningLanguage: The language the text is written in
    ///   - nativeLanguage: The user's native language
    ///   - explanationLanguage: The language for explanations (defaults to nativeLanguage if not specified)
    ///   - sensitivityLevel: The level of detail for feedback (optional, uses default if not specified)
    /// - Returns: Grammar check result (JSON string)
    func checkGrammar(text: String, learningLanguage: String, nativeLanguage: String, explanationLanguage: String? = nil, sensitivityLevel: GrammarSensitivityLevel? = nil) async throws -> String {
        let config = try await getConfiguration(for: .grammar)

        // Select prompt based on sensitivity level
        var promptTemplate = config.promptTemplate
        if let level = sensitivityLevel {
            switch level {
            case .minimal:
                promptTemplate = config.grammarLevel1Prompt ?? config.promptTemplate
            case .moderate:
                promptTemplate = config.grammarLevel2Prompt ?? config.promptTemplate
            case .verbose:
                promptTemplate = config.grammarLevel3Prompt ?? config.promptTemplate
            }
        }

        let prompt = fillPromptTemplate(
            promptTemplate,
            learningLanguage: learningLanguage,
            nativeLanguage: nativeLanguage,
            explanationLanguage: explanationLanguage
        )

        let messages = [
            ChatMessage(role: "system", content: prompt),
            ChatMessage(role: "user", content: text)
        ]

        return try await executeWithFallback(
            config: config,
            messages: messages,
            temperature: Double(config.temperature),
            maxTokens: config.maxTokens
        )
    }

    // MARK: - Scoring

    /// Score text using the configured scoring model
    /// Automatically falls back to backup models if primary fails
    /// - Parameters:
    ///   - text: The text to score
    ///   - learningLanguage: The language the text is written in
    ///   - nativeLanguage: The user's native language
    /// - Returns: Score result (JSON string)
    func scoreText(text: String, learningLanguage: String, nativeLanguage: String) async throws -> String {
        let config = try await getConfiguration(for: .scoring)

        let prompt = fillPromptTemplate(config.promptTemplate, learningLanguage: learningLanguage, nativeLanguage: nativeLanguage)

        let messages = [
            ChatMessage(role: "system", content: prompt),
            ChatMessage(role: "user", content: text)
        ]

        return try await executeWithFallback(
            config: config,
            messages: messages,
            temperature: Double(config.temperature),
            maxTokens: config.maxTokens
        )
    }
}

// MARK: - Supporting Types

enum AICategory: String, CaseIterable {
    case translation = "translation"
    case grammar = "grammar"
    case scoring = "scoring"
    case chatting = "chatting"
}

enum AIConfigurationError: LocalizedError {
    case emptyResponse
    case allModelsFailed

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "The AI model returned an empty response."
        case .allModelsFailed:
            return "All AI models (primary and fallbacks) failed. Please try again later."
        }
    }
}
