import Foundation
import Supabase

/// Service for fetching and caching AI configuration from Supabase
/// Configs are cached for 24 hours to minimize database calls
class AIConfigService {
    static let shared = AIConfigService()

    private init() {}

    // Cache storage
    private var cachedConfigs: [AICategory: AIConfig] = [:]
    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 24 * 60 * 60 // 24 hours

    // MARK: - Public API

    /// Get configuration for a specific category
    /// Fetches from cache if valid, otherwise fetches from Supabase
    func getConfiguration(for category: AICategory) async throws -> AIConfig {
        // Check if cache is still valid
        if let config = cachedConfigs[category], isCacheValid() {
            return config
        }

        // Fetch from Supabase
        return try await fetchConfiguration(for: category)
    }

    /// Force refresh all configurations from Supabase
    /// Call this when you want to bypass the cache
    func refreshAllConfigurations() async throws {
        cachedConfigs.removeAll()
        lastFetchTime = nil

        // Fetch all three categories
        _ = try await getConfiguration(for: .translation)
        _ = try await getConfiguration(for: .grammar)
        _ = try await getConfiguration(for: .scoring)
    }

    /// Clear all cached configurations (forces fresh fetch on next request)
    func clearCache() {
        cachedConfigs.removeAll()
        lastFetchTime = nil
        print("🗑️ AI Config cache cleared")
    }

    // MARK: - Private Helpers

    private func isCacheValid() -> Bool {
        guard let lastFetch = lastFetchTime else { return false }
        return Date().timeIntervalSince(lastFetch) < cacheValidityDuration
    }

    private func fetchConfiguration(for category: AICategory) async throws -> AIConfig {
        let supabase = SupabaseService.shared.client

        // Query the ai_config table
        let response: AIConfigResponse = try await supabase
            .from("ai_config")
            .select()
            .eq("category", value: category.rawValue)
            .eq("is_active", value: true)
            .single()
            .execute()
            .value

        // Convert response to AIConfig
        let config = AIConfig(
            category: category,
            modelId: response.modelId,
            modelName: response.modelName,
            modelProvider: response.modelProvider,
            promptTemplate: response.promptTemplate,
            grammarLevel1Prompt: response.grammarLevel1Prompt,
            grammarLevel2Prompt: response.grammarLevel2Prompt,
            grammarLevel3Prompt: response.grammarLevel3Prompt,
            temperature: response.temperature,
            maxTokens: response.maxTokens,
            fallbackModel1Id: response.fallbackModel1Id,
            fallbackModel1Name: response.fallbackModel1Name,
            fallbackModel2Id: response.fallbackModel2Id,
            fallbackModel2Name: response.fallbackModel2Name,
            fallbackModel3Id: response.fallbackModel3Id,
            fallbackModel3Name: response.fallbackModel3Name,
            fallbackModel4Id: response.fallbackModel4Id,
            fallbackModel4Name: response.fallbackModel4Name
        )

        // Cache it
        cachedConfigs[category] = config
        lastFetchTime = Date()

        return config
    }

    /// Get hardcoded fallback configuration
    /// Used when network is unavailable or Supabase fails
    func getFallbackConfiguration(for category: AICategory) -> AIConfig {
        switch category {
        case .translation:
            return AIConfig(
                category: .translation,
                modelId: "anthropic/claude-3.5-sonnet",
                modelName: "Claude 3.5 Sonnet",
                modelProvider: "anthropic",
                promptTemplate: "You are a professional translator. Translate from {learning_language} to {native_language}. Provide ONLY the translation.",
                temperature: 0.3,
                maxTokens: 1000
            )

        case .grammar:
            return AIConfig(
                category: .grammar,
                modelId: "anthropic/claude-3.5-sonnet",
                modelName: "Claude 3.5 Sonnet",
                modelProvider: "anthropic",
                promptTemplate: """
                You are a {learning_language} teacher. Check grammar and respond in JSON:
                {
                  "has_errors": boolean,
                  "corrections": [{"original": "text", "corrected": "text", "explanation": "in {native_language}"}],
                  "overall_feedback": "brief assessment"
                }
                """,
                grammarLevel1Prompt: "Check CRITICAL errors only. Minimal JSON response.",
                grammarLevel2Prompt: "Check grammar errors. Moderate detail in JSON.",
                grammarLevel3Prompt: "Comprehensive grammar check with detailed JSON response.",
                temperature: 0.3,
                maxTokens: 1500
            )

        case .scoring:
            return AIConfig(
                category: .scoring,
                modelId: "anthropic/claude-3.5-sonnet",
                modelName: "Claude 3.5 Sonnet",
                modelProvider: "anthropic",
                promptTemplate: """
                Assess {learning_language} text by {native_language} speaker. JSON response:
                {
                  "score": 0-100,
                  "level": "beginner|intermediate|advanced",
                  "strengths": [],
                  "areas_for_improvement": [],
                  "feedback": "in {native_language}"
                }
                """,
                temperature: 0.3,
                maxTokens: 800
            )

        case .chatting:
            return AIConfig(
                category: .chatting,
                modelId: "anthropic/claude-3.5-sonnet",
                modelName: "Claude 3.5 Sonnet",
                modelProvider: "anthropic",
                promptTemplate: """
                You are {bot_name}, a friendly and patient native {language} speaker helping someone learn your language.

                IMPORTANT: You MUST respond ONLY in {language}. Never use English or any other language in your response.

                Your role:
                - Have natural, engaging conversations in {language}
                - Adjust your language level to match the student's proficiency
                - Use common expressions and natural phrasing
                - Keep responses concise (1-3 sentences)
                - Be encouraging and supportive
                - If the student makes an error, gently model the correct form in your response without explicitly correcting

                Context: You are chatting with a language learner who wants to practice {language}.

                Conversation so far:
                {conversation_history}

                Respond naturally to continue the conversation.
                """,
                temperature: 0.8,
                maxTokens: 150
            )
        }
    }
}

// MARK: - Data Models

/// AI Configuration model
struct AIConfig {
    let category: AICategory
    let modelId: String
    let modelName: String
    let modelProvider: String
    let promptTemplate: String
    let grammarLevel1Prompt: String?
    let grammarLevel2Prompt: String?
    let grammarLevel3Prompt: String?
    let temperature: Float
    let maxTokens: Int

    // Fallback models for resilience
    let fallbackModel1Id: String?
    let fallbackModel1Name: String?
    let fallbackModel2Id: String?
    let fallbackModel2Name: String?
    let fallbackModel3Id: String?
    let fallbackModel3Name: String?
    let fallbackModel4Id: String?
    let fallbackModel4Name: String?

    init(
        category: AICategory,
        modelId: String,
        modelName: String,
        modelProvider: String,
        promptTemplate: String,
        grammarLevel1Prompt: String? = nil,
        grammarLevel2Prompt: String? = nil,
        grammarLevel3Prompt: String? = nil,
        temperature: Float = 0.7,
        maxTokens: Int = 1000,
        fallbackModel1Id: String? = nil,
        fallbackModel1Name: String? = nil,
        fallbackModel2Id: String? = nil,
        fallbackModel2Name: String? = nil,
        fallbackModel3Id: String? = nil,
        fallbackModel3Name: String? = nil,
        fallbackModel4Id: String? = nil,
        fallbackModel4Name: String? = nil
    ) {
        self.category = category
        self.modelId = modelId
        self.modelName = modelName
        self.modelProvider = modelProvider
        self.promptTemplate = promptTemplate
        self.grammarLevel1Prompt = grammarLevel1Prompt
        self.grammarLevel2Prompt = grammarLevel2Prompt
        self.grammarLevel3Prompt = grammarLevel3Prompt
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.fallbackModel1Id = fallbackModel1Id
        self.fallbackModel1Name = fallbackModel1Name
        self.fallbackModel2Id = fallbackModel2Id
        self.fallbackModel2Name = fallbackModel2Name
        self.fallbackModel3Id = fallbackModel3Id
        self.fallbackModel3Name = fallbackModel3Name
        self.fallbackModel4Id = fallbackModel4Id
        self.fallbackModel4Name = fallbackModel4Name
    }
}

/// Response model from Supabase
struct AIConfigResponse: Codable {
    let id: String
    let category: String
    let modelId: String
    let modelName: String
    let modelProvider: String
    let promptTemplate: String
    let grammarLevel1Prompt: String?
    let grammarLevel2Prompt: String?
    let grammarLevel3Prompt: String?
    let temperature: Float
    let maxTokens: Int
    let isActive: Bool

    // Fallback models
    let fallbackModel1Id: String?
    let fallbackModel1Name: String?
    let fallbackModel2Id: String?
    let fallbackModel2Name: String?
    let fallbackModel3Id: String?
    let fallbackModel3Name: String?
    let fallbackModel4Id: String?
    let fallbackModel4Name: String?

    enum CodingKeys: String, CodingKey {
        case id, category, temperature
        case modelId = "model_id"
        case modelName = "model_name"
        case modelProvider = "model_provider"
        case promptTemplate = "prompt_template"
        case grammarLevel1Prompt = "grammar_level_1_prompt"
        case grammarLevel2Prompt = "grammar_level_2_prompt"
        case grammarLevel3Prompt = "grammar_level_3_prompt"
        case maxTokens = "max_tokens"
        case isActive = "is_active"
        case fallbackModel1Id = "fallback_model_1_id"
        case fallbackModel1Name = "fallback_model_1_name"
        case fallbackModel2Id = "fallback_model_2_id"
        case fallbackModel2Name = "fallback_model_2_name"
        case fallbackModel3Id = "fallback_model_3_id"
        case fallbackModel3Name = "fallback_model_3_name"
        case fallbackModel4Id = "fallback_model_4_id"
        case fallbackModel4Name = "fallback_model_4_name"
    }
}
