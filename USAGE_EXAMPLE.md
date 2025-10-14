# AI Configuration Manager - Usage Examples

## Overview

The `AIConfigurationManager` provides a centralized way to access your saved AI model configurations and use them throughout your app for translation, grammar checking, and scoring.

## Basic Usage

### 1. Check if a Configuration Exists

```swift
import Foundation

// Check if translation model is configured
let hasTranslation = AIConfigurationManager.shared.hasConfiguration(for: .translation)
let hasGrammar = AIConfigurationManager.shared.hasConfiguration(for: .grammar)
let hasScoring = AIConfigurationManager.shared.hasConfiguration(for: .scoring)

if !hasTranslation {
    print("Please configure a translation model in Settings > AI Setup")
}
```

### 2. Get Configuration Details

```swift
// Get the saved translation configuration
if let config = AIConfigurationManager.shared.getConfiguration(for: .translation) {
    print("Model: \(config.modelName)")
    print("Provider: \(config.modelProvider)")
    print("Model ID: \(config.modelId)")
    print("Prompt Template: \(config.promptTemplate)")
}
```

### 3. Translate Text

```swift
// Example: Translate from Spanish to English
Task {
    do {
        let spanishText = "Hola, ¿cómo estás?"
        let translation = try await AIConfigurationManager.shared.translate(
            text: spanishText,
            from: "Spanish",
            to: "English"
        )
        print("Translation: \(translation)")
        // Output: "Hello, how are you?"
    } catch {
        print("Translation error: \(error.localizedDescription)")
    }
}
```

### 4. Check Grammar

```swift
// Example: Check grammar of French text
Task {
    do {
        let frenchText = "Je suis allé au magasin hier"
        let grammarCheck = try await AIConfigurationManager.shared.checkGrammar(
            text: frenchText,
            from: "French",
            to: "English"
        )
        print("Grammar check result: \(grammarCheck)")
        // Returns JSON with corrections and explanations
    } catch AIConfigurationError.noConfigurationFound(let category) {
        print("Error: No model configured for \(category.rawValue)")
    } catch {
        print("Grammar check error: \(error.localizedDescription)")
    }
}
```

### 5. Score Text

```swift
// Example: Score German text quality
Task {
    do {
        let germanText = "Ich gehe zur Schule jeden Tag"
        let score = try await AIConfigurationManager.shared.scoreText(
            text: germanText,
            from: "German",
            to: "English"
        )
        print("Score result: \(score)")
        // Returns JSON with score (0-100) and feedback
    } catch {
        print("Scoring error: \(error.localizedDescription)")
    }
}
```

## Integration in Chat View

Here's how you might integrate this into a chat interface:

```swift
class ChatViewController: UIViewController {

    // Translate incoming message
    func translateIncomingMessage(_ message: String, fromLanguage: String, toLanguage: String) {
        Task {
            do {
                let translation = try await AIConfigurationManager.shared.translate(
                    text: message,
                    from: fromLanguage,
                    to: toLanguage
                )

                // Display translation in UI
                await MainActor.run {
                    showTranslation(translation)
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
        }
    }

    // Check grammar before sending
    func checkGrammarBeforeSending(_ message: String, language: String) {
        Task {
            do {
                let grammarResult = try await AIConfigurationManager.shared.checkGrammar(
                    text: message,
                    from: language,
                    to: "English" // User's native language
                )

                // Parse JSON result and show suggestions
                await MainActor.run {
                    showGrammarSuggestions(grammarResult)
                }
            } catch {
                // If no grammar model configured, just send without checking
                sendMessage(message)
            }
        }
    }
}
```

## Custom Prompt Processing

If you need to manually process prompts with custom logic:

```swift
// Get the configuration
if let config = AIConfigurationManager.shared.getConfiguration(for: .translation) {

    // Fill in the language placeholders
    let filledPrompt = AIConfigurationManager.shared.fillPromptTemplate(
        config.promptTemplate,
        from: "Japanese",
        to: "English"
    )

    print("Filled prompt: \(filledPrompt)")
    // Output: "You are a professional translator. Translate the following text
    //          from Japanese to English. Maintain the tone and style. Return only the translation."

    // Use the prompt with OpenRouter directly
    let messages = [
        ChatMessage(role: "system", content: filledPrompt),
        ChatMessage(role: "user", content: "こんにちは")
    ]

    Task {
        let response = try await OpenRouterService.shared.sendChatCompletion(
            model: config.modelId,
            messages: messages,
            temperature: 0.7,
            maxTokens: 1000
        )
        print(response.choices.first?.message.content ?? "")
    }
}
```

## Error Handling

Always handle errors appropriately:

```swift
Task {
    do {
        let result = try await AIConfigurationManager.shared.translate(
            text: "Hello",
            from: "English",
            to: "Spanish"
        )
        print(result)
    } catch AIConfigurationError.noConfigurationFound(let category) {
        // User hasn't configured a model for this category
        showConfigurationPrompt(for: category)
    } catch AIConfigurationError.emptyResponse {
        // Model returned no content
        showAlert(title: "Error", message: "The AI model returned an empty response")
    } catch {
        // Other errors (network, API, etc.)
        showAlert(title: "Error", message: error.localizedDescription)
    }
}

func showConfigurationPrompt(for category: AICategory) {
    let alert = UIAlertController(
        title: "Model Not Configured",
        message: "Please configure a \(category.rawValue) model in Settings > AI Setup",
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
        // Navigate to AI Setup screen
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
}
```

## Placeholder Format

The prompt templates use `<from>` and `<to>` as placeholders:

- `<from>` - Source language (the language being analyzed/translated from)
- `<to>` - Target language (the user's native language or translation target)

Example prompts:
- Translation: "Translate from `<from>` to `<to>`"
- Grammar: "Check grammar in `<from>`, explain in `<to>`"
- Scoring: "Score text in `<from>`, provide feedback in `<to>`"

## Notes

- All AI operations are asynchronous and should be called within a `Task` block
- Configurations are saved per category (translation, grammar, scoring)
- Each category can have a different model and prompt template
- The configuration manager automatically handles prompt template substitution
- Users must configure models via Settings > Preferences > AI Setup before using these features
