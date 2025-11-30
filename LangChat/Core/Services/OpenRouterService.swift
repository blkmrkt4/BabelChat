import Foundation
import UIKit

class OpenRouterService {
    static let shared = OpenRouterService()

    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1"

    private init() {
        self.apiKey = Config.openRouterAPIKey
    }

    // MARK: - Chat Completion
    func sendChatCompletion(
        model: String,
        messages: [ChatMessage],
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ) async throws -> ChatCompletionResponse {
        guard !apiKey.isEmpty else {
            throw OpenRouterError.missingAPIKey
        }

        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://langchat.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("LangChat iOS", forHTTPHeaderField: "X-Title")

        let requestBody = ChatCompletionRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            max_tokens: maxTokens
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenRouterError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        do {
            let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

            // Check for API error in response
            if let apiError = completionResponse.error {
                throw OpenRouterError.httpError(
                    statusCode: apiError.code ?? 500,
                    message: apiError.message ?? "Unknown API error"
                )
            }

            return completionResponse
        } catch let decodingError as DecodingError {
            // Log the raw response for debugging
            let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("❌ OpenRouter decoding error: \(decodingError)")
            print("📄 Raw response: \(rawResponse)")
            throw OpenRouterError.httpError(statusCode: httpResponse.statusCode, message: "Failed to decode response: \(decodingError.localizedDescription)")
        }
    }

    // MARK: - Translate Helper
    func translate(
        text: String,
        sourceLanguage: String,
        targetLanguage: String,
        model: String,
        masterPrompt: String? = nil
    ) async throws -> String {
        let systemPrompt = masterPrompt ?? """
        You are a professional translator. Translate the following text from \(sourceLanguage) to \(targetLanguage).
        Maintain the tone and style of the original message. Only return the translation, no explanations.
        """

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: text)
        ]

        let response = try await sendChatCompletion(model: model, messages: messages)

        guard let firstChoice = response.choices?.first,
              let content = firstChoice.content else {
            throw OpenRouterError.emptyResponse
        }

        return content
    }

    // MARK: - Fetch Available Models
    func fetchAvailableModels() async throws -> [OpenRouterModel] {
        let url = URL(string: "\(baseURL)/models")!

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenRouterError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let modelsResponse = try JSONDecoder().decode(ModelsListResponse.self, from: data)
        return modelsResponse.data
    }
}

// MARK: - Models
struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int
}

struct ChatCompletionResponse: Codable {
    let id: String?
    let choices: [Choice]?
    let usage: Usage?
    let error: APIError?

    struct Choice: Codable {
        let index: Int?
        let message: ChoiceMessage?
        let finish_reason: String?
        let delta: ChoiceMessage?  // For streaming responses

        // Get content from either message or delta
        var content: String? {
            return message?.content ?? delta?.content
        }
    }

    struct ChoiceMessage: Codable {
        let role: String?
        let content: String?
    }

    struct Usage: Codable {
        let prompt_tokens: Int?
        let completion_tokens: Int?
        let total_tokens: Int?
    }

    struct APIError: Codable {
        let message: String?
        let code: Int?
        let type: String?
    }
}

// MARK: - OpenRouter Model Data
struct ModelsListResponse: Codable {
    let data: [OpenRouterModel]
}

struct OpenRouterModel: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let pricing: Pricing
    let contextLength: Int
    let architecture: Architecture?
    let topProvider: TopProvider?

    struct Pricing: Codable {
        let prompt: String
        let completion: String
        let image: String?
        let internalReasoning: String?

        enum CodingKeys: String, CodingKey {
            case prompt, completion, image
            case internalReasoning = "internal_reasoning"
        }
    }

    struct Architecture: Codable {
        let modality: String?
        let tokenizer: String?
        let instructType: String?
        let inputModalities: [String]?
        let outputModalities: [String]?

        enum CodingKeys: String, CodingKey {
            case modality, tokenizer
            case instructType = "instruct_type"
            case inputModalities = "input_modalities"
            case outputModalities = "output_modalities"
        }
    }

    struct TopProvider: Codable {
        let maxCompletionTokens: Int?

        enum CodingKeys: String, CodingKey {
            case maxCompletionTokens = "max_completion_tokens"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, pricing, architecture
        case contextLength = "context_length"
        case topProvider = "top_provider"
    }

    // MARK: - Computed Properties

    var isFree: Bool {
        return (Double(pricing.prompt) ?? 0) == 0 && (Double(pricing.completion) ?? 0) == 0
    }

    var hasReasoningCost: Bool {
        guard let reasoning = pricing.internalReasoning else { return false }
        return (Double(reasoning) ?? 0) > 0
    }

    var isTextOnly: Bool {
        guard let arch = architecture else { return true }

        // Check input modalities
        if let inputMods = arch.inputModalities {
            if inputMods.contains(where: { $0 != "text" }) {
                return false
            }
        }

        // Check output modalities
        if let outputMods = arch.outputModalities {
            if outputMods.contains(where: { $0 != "text" }) {
                return false
            }
        }

        // Check modality string
        if let modality = arch.modality, modality != "text->text" {
            return false
        }

        return true
    }

    var totalCostPer1K: Double {
        let promptCost = (Double(pricing.prompt) ?? 0) * 1000
        let completionCost = (Double(pricing.completion) ?? 0) * 1000
        return promptCost + completionCost
    }

    var formattedCost: String {
        if isFree { return "Free" }

        let cost = totalCostPer1K
        if cost < 0.001 { return String(format: "$%.5f", cost) }
        if cost < 0.01 { return String(format: "$%.4f", cost) }
        if cost < 1 { return String(format: "$%.3f", cost) }
        return String(format: "$%.2f", cost)
    }

    var formattedContextLength: String {
        if contextLength >= 1_000_000 {
            return String(format: "%.1fM", Double(contextLength) / 1_000_000)
        }
        if contextLength >= 1_000 {
            return "\(contextLength / 1_000)K"
        }
        return "\(contextLength)"
    }
}

// MARK: - Model with Score
struct ModelWithScore {
    let model: OpenRouterModel
    let score: Double?
    let translationScore: Double?
    let speedScore: Double?
    let testCount: Int

    var displayScore: String {
        guard let score = score else { return "Not tested" }
        return String(format: "%.0f", score)
    }

    var scoreBreakdown: String? {
        guard let trans = translationScore, let speed = speedScore else { return nil }
        return String(format: "Trans(%.0f) + Speed(%.0f)", trans, speed)
    }

    var scoreColor: UIColor {
        guard let score = score else { return .secondaryLabel }
        if score >= 85 { return .systemGreen }
        if score >= 70 { return .systemBlue }
        if score >= 50 { return .systemOrange }
        return .systemRed
    }
}

enum OpenRouterError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenRouter API key is missing. Please add it to your .env file."
        case .invalidResponse:
            return "Invalid response from OpenRouter API"
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message)"
        case .emptyResponse:
            return "OpenRouter returned an empty response"
        }
    }
}
