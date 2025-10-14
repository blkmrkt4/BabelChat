import Foundation

struct AIModel {
    let id: String
    let name: String
    let provider: String
    let inputCostPerToken: Decimal
    let outputCostPerToken: Decimal
    let contextLength: Int
    let description: String?

    var formattedInputCostPer1K: String {
        let costPer1K = inputCostPerToken * 1000
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter.string(from: costPer1K as NSNumber) ?? "$0"
    }

    var formattedOutputCostPer1K: String {
        let costPer1K = outputCostPerToken * 1000
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter.string(from: costPer1K as NSNumber) ?? "$0"
    }

    var costDisplay: String {
        return "\(formattedInputCostPer1K)/\(formattedOutputCostPer1K) per 1K"
    }
}

extension AIModel {
    static func getSampleModels(for category: String) -> [AIModel] {
        // For now, return all models for any category
        // In production, this would filter models based on their suitability for the category
        return sampleModels
    }

    static var sampleModels: [AIModel] {
        return [
            // OpenAI Models
            AIModel(
                id: "openai/gpt-4-turbo",
                name: "GPT-4 Turbo",
                provider: "OpenAI",
                inputCostPerToken: 0.00001,
                outputCostPerToken: 0.00003,
                contextLength: 128000,
                description: "Latest GPT-4 Turbo with improved performance"
            ),
            AIModel(
                id: "openai/gpt-4o",
                name: "GPT-4o",
                provider: "OpenAI",
                inputCostPerToken: 0.0000025,
                outputCostPerToken: 0.00001,
                contextLength: 128000,
                description: "GPT-4 Omni - multimodal flagship model"
            ),
            AIModel(
                id: "openai/gpt-4o-mini",
                name: "GPT-4o Mini",
                provider: "OpenAI",
                inputCostPerToken: 0.00000015,
                outputCostPerToken: 0.0000006,
                contextLength: 128000,
                description: "Smaller, faster GPT-4o variant"
            ),
            AIModel(
                id: "openai/gpt-3.5-turbo",
                name: "GPT-3.5 Turbo",
                provider: "OpenAI",
                inputCostPerToken: 0.0000005,
                outputCostPerToken: 0.0000015,
                contextLength: 16385,
                description: "Fast and cost-effective"
            ),

            // Anthropic Models
            AIModel(
                id: "anthropic/claude-3.5-sonnet:beta",
                name: "Claude 3.5 Sonnet",
                provider: "Anthropic",
                inputCostPerToken: 0.000003,
                outputCostPerToken: 0.000015,
                contextLength: 200000,
                description: "Latest Claude with improved capabilities"
            ),
            AIModel(
                id: "anthropic/claude-3-opus:beta",
                name: "Claude 3 Opus",
                provider: "Anthropic",
                inputCostPerToken: 0.000015,
                outputCostPerToken: 0.000075,
                contextLength: 200000,
                description: "Most capable Claude model for complex tasks"
            ),
            AIModel(
                id: "anthropic/claude-3-sonnet:beta",
                name: "Claude 3 Sonnet",
                provider: "Anthropic",
                inputCostPerToken: 0.000003,
                outputCostPerToken: 0.000015,
                contextLength: 200000,
                description: "Balanced performance and cost"
            ),
            AIModel(
                id: "anthropic/claude-3-haiku:beta",
                name: "Claude 3 Haiku",
                provider: "Anthropic",
                inputCostPerToken: 0.00000025,
                outputCostPerToken: 0.00000125,
                contextLength: 200000,
                description: "Fastest and most compact Claude model"
            ),

            // Google Models
            AIModel(
                id: "google/gemini-pro-1.5-exp",
                name: "Gemini Pro 1.5",
                provider: "Google",
                inputCostPerToken: 0.0000025,
                outputCostPerToken: 0.0000075,
                contextLength: 1000000,
                description: "Google's latest with 1M token context"
            ),
            AIModel(
                id: "google/gemini-flash-1.5-exp",
                name: "Gemini Flash 1.5",
                provider: "Google",
                inputCostPerToken: 0.00000025,
                outputCostPerToken: 0.00000075,
                contextLength: 1000000,
                description: "Fast and efficient Gemini variant"
            ),
            AIModel(
                id: "google/gemini-pro",
                name: "Gemini Pro",
                provider: "Google",
                inputCostPerToken: 0.000000125,
                outputCostPerToken: 0.000000375,
                contextLength: 32000,
                description: "Google's advanced language model"
            ),

            // Meta Llama Models
            AIModel(
                id: "meta-llama/llama-3.1-405b-instruct",
                name: "Llama 3.1 405B",
                provider: "Meta",
                inputCostPerToken: 0.000003,
                outputCostPerToken: 0.000003,
                contextLength: 131072,
                description: "Largest and most capable Llama model"
            ),
            AIModel(
                id: "meta-llama/llama-3.1-70b-instruct",
                name: "Llama 3.1 70B",
                provider: "Meta",
                inputCostPerToken: 0.00000052,
                outputCostPerToken: 0.00000075,
                contextLength: 131072,
                description: "High performance open-source model"
            ),
            AIModel(
                id: "meta-llama/llama-3.1-8b-instruct",
                name: "Llama 3.1 8B",
                provider: "Meta",
                inputCostPerToken: 0.00000006,
                outputCostPerToken: 0.00000006,
                contextLength: 131072,
                description: "Efficient open-source model"
            ),

            // Mistral Models
            AIModel(
                id: "mistralai/mistral-large",
                name: "Mistral Large",
                provider: "Mistral",
                inputCostPerToken: 0.000003,
                outputCostPerToken: 0.000009,
                contextLength: 128000,
                description: "Mistral's flagship model"
            ),
            AIModel(
                id: "mistralai/mixtral-8x7b-instruct",
                name: "Mixtral 8x7B",
                provider: "Mistral",
                inputCostPerToken: 0.00000024,
                outputCostPerToken: 0.00000024,
                contextLength: 32768,
                description: "Mixture of experts model"
            ),
            AIModel(
                id: "mistralai/mistral-7b-instruct",
                name: "Mistral 7B",
                provider: "Mistral",
                inputCostPerToken: 0.00000006,
                outputCostPerToken: 0.00000006,
                contextLength: 32768,
                description: "Efficient 7B parameter model"
            ),

            // Cohere Models
            AIModel(
                id: "cohere/command-r-plus-08-2024",
                name: "Command R+",
                provider: "Cohere",
                inputCostPerToken: 0.000003,
                outputCostPerToken: 0.000015,
                contextLength: 128000,
                description: "Cohere's most capable model"
            ),
            AIModel(
                id: "cohere/command-r-08-2024",
                name: "Command R",
                provider: "Cohere",
                inputCostPerToken: 0.0000005,
                outputCostPerToken: 0.0000015,
                contextLength: 128000,
                description: "Balanced performance and efficiency"
            ),

            // DeepSeek Models
            AIModel(
                id: "deepseek/deepseek-chat",
                name: "DeepSeek Chat",
                provider: "DeepSeek",
                inputCostPerToken: 0.00000014,
                outputCostPerToken: 0.00000028,
                contextLength: 32000,
                description: "Cost-effective Chinese model"
            ),

            // Perplexity Models
            AIModel(
                id: "perplexity/llama-3.1-sonar-large-128k-online",
                name: "Sonar Large Online",
                provider: "Perplexity",
                inputCostPerToken: 0.000001,
                outputCostPerToken: 0.000001,
                contextLength: 127072,
                description: "Online search-augmented model"
            ),

            // Qwen Models
            AIModel(
                id: "qwen/qwen-2-72b-instruct",
                name: "Qwen 2 72B",
                provider: "Alibaba",
                inputCostPerToken: 0.00000056,
                outputCostPerToken: 0.00000056,
                contextLength: 32768,
                description: "High-quality multilingual model"
            )
        ]
    }
}