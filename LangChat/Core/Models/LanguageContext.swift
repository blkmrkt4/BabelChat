import Foundation

// MARK: - Language Context
// Provides explicit, deterministic language routing for all AI operations.
// This replaces reliance on Language.detect() as source of truth.
//
// Routing rules:
//   - User messages are tagged with their actual input language (native or learning)
//   - Translation direction is determined by message ownership, not detection:
//       * User's own message (native input)  → translate TO learning language
//       * Partner/Muse message (learning lang) → translate TO native language
//   - Grammar always analyzes in the conversation's learning language
//   - Explanation language is toggleable (native/learning) independently of analysis language
//   - Language.detect() is advisory only — used for logging, never for routing decisions

struct LanguageContext {
    /// The language the user is learning in this conversation
    let conversationLearningLanguage: Language
    /// The current user's native language
    let currentUserNativeLanguage: Language

    // MARK: - Translation Routing

    /// Determine translation source and target based on message ownership.
    /// Does NOT use language detection — direction is deterministic.
    func translationPair(isCurrentUserMessage: Bool) -> (source: Language, target: Language) {
        if isCurrentUserMessage {
            // User wrote in native → translate to learning language
            return (source: currentUserNativeLanguage, target: conversationLearningLanguage)
        } else {
            // Partner/Muse wrote in learning language → translate to native
            return (source: conversationLearningLanguage, target: currentUserNativeLanguage)
        }
    }

    // MARK: - Grammar Routing

    /// The language to analyze grammar in — always the conversation's learning language.
    /// This prevents grammar from randomly evaluating in Italian when the pair is EN↔TL.
    var grammarAnalysisLanguage: Language {
        return conversationLearningLanguage
    }

    /// Default explanation language (user's native). Toggling is handled at call site.
    var defaultExplanationLanguage: Language {
        return currentUserNativeLanguage
    }
}

// MARK: - Muse Request Mode
// Explicit mode for Muse AI assistant requests.
// Even if UI initially uses only .phraseTranslation, the plumbing is deterministic.

enum MuseRequestMode: String {
    /// Default: translate a phrase or expression (e.g., "How do you say peanut?")
    case phraseTranslation = "phrase_translation"
    /// Look up meaning of a word in context
    case wordMeaning = "word_meaning"
    /// Fix grammar in a sentence
    case grammarFix = "grammar_fix"
}
