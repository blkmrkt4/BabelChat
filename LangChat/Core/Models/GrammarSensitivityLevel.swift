import Foundation

/// Sensitivity levels for grammar correction feedback
enum GrammarSensitivityLevel: String, Codable, CaseIterable {
    case minimal = "minimal"
    case moderate = "moderate"
    case verbose = "verbose"

    var displayName: String {
        switch self {
        case .minimal:
            return "Minimal"
        case .moderate:
            return "Moderate"
        case .verbose:
            return "Verbose"
        }
    }

    var description: String {
        switch self {
        case .minimal:
            return "Only critical errors"
        case .moderate:
            return "Important corrections"
        case .verbose:
            return "Detailed explanations"
        }
    }
}

/// Grammar configuration with multiple sensitivity level templates
struct GrammarConfiguration: Codable {
    var minimalPrompt: String
    var moderatePrompt: String
    var verbosePrompt: String

    func getPrompt(for level: GrammarSensitivityLevel) -> String {
        switch level {
        case .minimal:
            return minimalPrompt
        case .moderate:
            return moderatePrompt
        case .verbose:
            return verbosePrompt
        }
    }

    mutating func setPrompt(_ prompt: String, for level: GrammarSensitivityLevel) {
        switch level {
        case .minimal:
            minimalPrompt = prompt
        case .moderate:
            moderatePrompt = prompt
        case .verbose:
            verbosePrompt = prompt
        }
    }

    static var defaultConfiguration: GrammarConfiguration {
        return GrammarConfiguration(
            minimalPrompt: """
            You are a grammar assistant. Check this {learning_language} text for MAJOR errors or incomprehensibility only. Ignore minor mistakes. User's native language: {native_language}.

            CRITICAL: Start your response IMMEDIATELY with either "✗" or "✓" - NO preamble, NO "Sure I can help", NO "Here's my analysis", NO "Is there anything else". Just the assessment.

            If the text has critical errors OR is incomprehensible, provide:
            ✗ Original: [text]
            ✓ Fixed: [correction]
            - [One sentence why]

            If minor errors only or perfectly clear: "✓ Clear enough"
            """,
            moderatePrompt: """
            You are a grammar assistant. Check this {learning_language} text for important errors and provide helpful corrections. User's native language: {native_language}.

            CRITICAL: Start your response IMMEDIATELY with either "✗" or "✓" - NO preamble, NO "Sure I can help", NO "Here's my analysis".

            If the text has errors worth correcting, provide:
            ✗ Original: [text]
            ✓ Fixed: [correction]
            - [Brief explanation in {native_language}]
            💡 [One helpful tip for improvement]

            If only minor issues or good: "✓ Good! [One brief compliment or minor suggestion]"
            """,
            verbosePrompt: """
            You are a detailed grammar tutor. Analyze this {learning_language} text and provide comprehensive feedback. User's native language: {native_language}.

            CRITICAL: Start your response IMMEDIATELY with either "✗" or "✓" - NO preamble.

            If the text has errors, provide:
            ✗ Original: [text]
            ✓ Fixed: [correction]

            📝 Grammar Notes:
            - [Specific error and rule in {native_language}]
            - [Another error if applicable]

            💡 Tips:
            - [Helpful suggestion]
            - [Cultural or usage note if relevant]

            ⭐ Overall: [Brief assessment of their {learning_language} level]

            If excellent: "✓ Excellent! [Detailed compliment and advanced suggestions]"
            """
        )
    }
}
