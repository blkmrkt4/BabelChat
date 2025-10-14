import Foundation

/// Manages AI model configurations for different categories (translation, grammar, scoring)
/// Provides access to saved models and their prompts for use throughout the app
class AIConfigurationManager {
    static let shared = AIConfigurationManager()

    private init() {}

    // MARK: - Configuration Retrieval

    /// Get the saved configuration for a specific category
    /// - Parameter category: The category (translation, grammar, scoring)
    /// - Returns: SavedConfiguration if one exists for the category
    func getConfiguration(for category: AICategory) -> SavedConfiguration? {
        guard let data = UserDefaults.standard.data(forKey: "AIModelConfigs"),
              let allConfigs = try? JSONDecoder().decode([String: SavedConfig].self, from: data),
              let savedConfig = allConfigs[category.rawValue] else {
            return nil
        }

        return SavedConfiguration(
            modelId: savedConfig.modelId,
            modelName: savedConfig.modelName,
            modelProvider: savedConfig.modelProvider,
            category: category,
            promptTemplate: savedConfig.masterPrompt
        )
    }

    /// Check if a configuration exists for a category
    func hasConfiguration(for category: AICategory) -> Bool {
        return getConfiguration(for: category) != nil
    }

    // MARK: - Prompt Processing

    /// Replace language placeholders in a prompt template
    /// - Parameters:
    ///   - template: The prompt template with {learning_language} and {native_language} placeholders
    ///   - learningLanguage: The language being learned (e.g., "Spanish", "French")
    ///   - nativeLanguage: The user's native language (e.g., "English")
    /// - Returns: The prompt with placeholders replaced
    func fillPromptTemplate(_ template: String, learningLanguage: String, nativeLanguage: String) -> String {
        return template
            .replacingOccurrences(of: "{learning_language}", with: learningLanguage)
            .replacingOccurrences(of: "{native_language}", with: nativeLanguage)
    }

    // MARK: - Translation

    /// Translate text using the saved translation model
    /// - Parameters:
    ///   - text: The text to translate
    ///   - learningLanguage: Source language (language being learned)
    ///   - nativeLanguage: Target language (user's native language)
    /// - Returns: Translated text
    func translate(text: String, learningLanguage: String, nativeLanguage: String) async throws -> String {
        guard let config = getConfiguration(for: .translation) else {
            throw AIConfigurationError.noConfigurationFound(category: .translation)
        }

        let prompt = fillPromptTemplate(config.promptTemplate, learningLanguage: learningLanguage, nativeLanguage: nativeLanguage)

        let messages = [
            ChatMessage(role: "system", content: prompt),
            ChatMessage(role: "user", content: text)
        ]

        let response = try await OpenRouterService.shared.sendChatCompletion(
            model: config.modelId,
            messages: messages,
            temperature: 0.7,
            maxTokens: 1000
        )

        guard let content = response.choices.first?.message.content else {
            throw AIConfigurationError.emptyResponse
        }

        return content
    }

    // MARK: - Grammar Check

    /// Check grammar using the saved grammar model
    /// - Parameters:
    ///   - text: The text to check
    ///   - learningLanguage: The language the text is written in
    ///   - nativeLanguage: The user's native language (for explanations)
    ///   - sensitivityLevel: The level of detail for feedback (optional, uses default if not specified)
    /// - Returns: Grammar check result (JSON string)
    func checkGrammar(text: String, learningLanguage: String, nativeLanguage: String, sensitivityLevel: GrammarSensitivityLevel? = nil) async throws -> String {
        guard let config = getConfiguration(for: .grammar) else {
            throw AIConfigurationError.noConfigurationFound(category: .grammar)
        }

        // If sensitivity level is specified, use the corresponding template from saved grammar config
        var promptTemplate = config.promptTemplate
        if let level = sensitivityLevel,
           let grammarData = UserDefaults.standard.data(forKey: "GrammarConfiguration"),
           let grammarConfig = try? JSONDecoder().decode(GrammarConfiguration.self, from: grammarData) {
            promptTemplate = grammarConfig.getPrompt(for: level)
        }

        let prompt = fillPromptTemplate(promptTemplate, learningLanguage: learningLanguage, nativeLanguage: nativeLanguage)

        let messages = [
            ChatMessage(role: "system", content: prompt),
            ChatMessage(role: "user", content: text)
        ]

        let response = try await OpenRouterService.shared.sendChatCompletion(
            model: config.modelId,
            messages: messages,
            temperature: 0.3,
            maxTokens: 1500
        )

        guard let content = response.choices.first?.message.content else {
            throw AIConfigurationError.emptyResponse
        }

        return content
    }

    // MARK: - Scoring

    /// Score text using the saved scoring model
    /// - Parameters:
    ///   - text: The text to score
    ///   - learningLanguage: The language the text is written in
    ///   - nativeLanguage: The user's native language
    /// - Returns: Score result (JSON string)
    func scoreText(text: String, learningLanguage: String, nativeLanguage: String) async throws -> String {
        guard let config = getConfiguration(for: .scoring) else {
            throw AIConfigurationError.noConfigurationFound(category: .scoring)
        }

        let prompt = fillPromptTemplate(config.promptTemplate, learningLanguage: learningLanguage, nativeLanguage: nativeLanguage)

        let messages = [
            ChatMessage(role: "system", content: prompt),
            ChatMessage(role: "user", content: text)
        ]

        let response = try await OpenRouterService.shared.sendChatCompletion(
            model: config.modelId,
            messages: messages,
            temperature: 0.3,
            maxTokens: 800
        )

        guard let content = response.choices.first?.message.content else {
            throw AIConfigurationError.emptyResponse
        }

        return content
    }
}

// MARK: - Supporting Types

enum AICategory: String, CaseIterable {
    case translation = "translation"
    case grammar = "grammar"
    case scoring = "scoring"
}

struct SavedConfiguration {
    let modelId: String
    let modelName: String
    let modelProvider: String
    let category: AICategory
    let promptTemplate: String
}

struct SavedConfig: Codable {
    let modelId: String
    let modelName: String
    let modelProvider: String
    let masterPrompt: String
}

enum AIConfigurationError: LocalizedError {
    case noConfigurationFound(category: AICategory)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noConfigurationFound(let category):
            return "No AI model configured for \(category.rawValue). Please configure one in Settings > AI Setup."
        case .emptyResponse:
            return "The AI model returned an empty response."
        }
    }
}
