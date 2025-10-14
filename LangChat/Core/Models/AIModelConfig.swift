import Foundation

enum AIModelCategory: String, CaseIterable {
    case translation = "translation"
    case grammar = "grammar"
    case scoring = "scoring"

    var displayName: String {
        switch self {
        case .translation: return "Translation"
        case .grammar: return "Grammar"
        case .scoring: return "Scoring"
        }
    }
}

class AIModelConfig {
    let id: UUID
    let userId: UUID?
    let modelId: String
    let modelName: String
    let modelProvider: String
    let category: AIModelCategory
    let inputCostPerToken: Decimal?
    let outputCostPerToken: Decimal?
    var masterPrompt: String
    var temperature: Double
    var maxTokens: Int
    var userScore: Double?
    var scoreNotes: String?
    var testsPerformed: Int
    var isActive: Bool
    var isDefault: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        modelId: String,
        modelName: String,
        modelProvider: String,
        category: AIModelCategory,
        inputCostPerToken: Decimal? = nil,
        outputCostPerToken: Decimal? = nil,
        masterPrompt: String = "",
        temperature: Double = 0.7,
        maxTokens: Int = 1000,
        userScore: Double? = nil,
        scoreNotes: String? = nil,
        testsPerformed: Int = 0,
        isActive: Bool = true,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.modelId = modelId
        self.modelName = modelName
        self.modelProvider = modelProvider
        self.category = category
        self.inputCostPerToken = inputCostPerToken
        self.outputCostPerToken = outputCostPerToken
        self.masterPrompt = masterPrompt
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.userScore = userScore
        self.scoreNotes = scoreNotes
        self.testsPerformed = testsPerformed
        self.isActive = isActive
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayName: String {
        var display = "\(modelName) - \(modelProvider)"
        if let score = userScore {
            display += " (\(String(format: "%.1f", score)))"
        }
        return display
    }

    var costDisplay: String? {
        guard let inputCost = inputCostPerToken,
              let outputCost = outputCostPerToken else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 6
        formatter.maximumFractionDigits = 8

        let inStr = formatter.string(from: inputCost as NSNumber) ?? "$0"
        let outStr = formatter.string(from: outputCost as NSNumber) ?? "$0"

        return "In: \(inStr) | Out: \(outStr)"
    }
}

extension AIModelConfig {
    static func fromModel(_ model: AIModel, category: AIModelCategory) -> AIModelConfig {
        let defaultPrompts: [AIModelCategory: String] = [
            .translation: "You are a professional translator. Translate the following text from {source_language} to {target_language}. Maintain the tone and style of the original message. Only return the translation, no explanations.",
            .grammar: "You are a language expert. Check the following {language} text for grammar errors and provide corrections with brief explanations. Format: {\"corrections\": [...], \"explanation\": \"...\"}",
            .scoring: "Rate the following {language} text for correctness on a scale of 0-100. Consider grammar, spelling, and natural expression. Return only a JSON: {\"score\": X, \"brief_feedback\": \"...\"}"
        ]

        return AIModelConfig(
            modelId: model.id,
            modelName: model.name,
            modelProvider: model.provider,
            category: category,
            inputCostPerToken: model.inputCostPerToken,
            outputCostPerToken: model.outputCostPerToken,
            masterPrompt: defaultPrompts[category] ?? ""
        )
    }
}