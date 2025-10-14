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
            You are a grammar assistant. Check this text written in {learning_language} for CRITICAL errors only. \
            The user's native language is {native_language}.

            Return JSON format:
            {
              "corrections": [
                {"original": "...", "corrected": "...", "explanation": "brief explanation in {native_language}"}
              ]
            }

            Only flag serious mistakes that impede understanding.
            """,
            moderatePrompt: """
            You are a grammar assistant. Check this text written in {learning_language} for important errors. \
            The user is learning {learning_language} and their native language is {native_language}.

            Return JSON format:
            {
              "corrections": [
                {"original": "...", "corrected": "...", "explanation": "clear explanation in {native_language}", "severity": "high|medium"}
              ]
            }

            Focus on errors that affect meaning and common mistakes learners make.
            """,
            verbosePrompt: """
            You are a detailed grammar tutor. Analyze this text written in {learning_language}. \
            The user is learning {learning_language} and their native language is {native_language}.

            Return JSON format:
            {
              "corrections": [
                {
                  "original": "...",
                  "corrected": "...",
                  "explanation": "detailed explanation in {native_language}",
                  "rule": "grammar rule being violated",
                  "severity": "high|medium|low",
                  "examples": ["example usage"]
                }
              ],
              "overall_feedback": "general comments on their {learning_language} proficiency"
            }

            Provide comprehensive feedback including minor improvements, style suggestions, and learning tips.
            """
        )
    }
}
