import Foundation

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

        let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return completionResponse
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

        guard let firstChoice = response.choices.first else {
            throw OpenRouterError.emptyResponse
        }

        return firstChoice.message.content
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
    let id: String
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Codable {
        let index: Int
        let message: ChatMessage
        let finish_reason: String?
    }

    struct Usage: Codable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
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
