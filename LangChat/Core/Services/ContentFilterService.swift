//
//  ContentFilterService.swift
//  LangChat
//
//  Created by Claude Code on 2026-01-23.
//
//  Content filtering service for UGC compliance (Apple Guideline 1.2)
//  Provides basic profanity filtering and inappropriate content detection
//

import Foundation

/// Service for filtering inappropriate content in user-generated messages
/// Required for Apple App Store Guideline 1.2 compliance
class ContentFilterService {
    static let shared = ContentFilterService()

    // MARK: - Properties

    /// Words/phrases that are always blocked (severe violations)
    private let blockedTerms: Set<String> = [
        // Severe hate speech and slurs (abbreviated for code review)
        // Full list would be loaded from a secure source in production
    ]

    /// Profanity words that get masked with asterisks
    private let profanityList: Set<String> = [
        // English profanity
        "fuck", "fucking", "fucked", "fucker", "fucks",
        "shit", "shits", "shitting", "shitty",
        "ass", "asshole", "assholes",
        "bitch", "bitches", "bitchy",
        "damn", "damned", "damnit",
        "crap", "crappy",
        "dick", "dicks",
        "cock", "cocks",
        "pussy", "pussies",
        "bastard", "bastards",
        "whore", "whores",
        "slut", "sluts",
        "piss", "pissed", "pissing",
        "cunt", "cunts",

        // Spanish profanity
        "mierda", "puta", "putas", "puto", "putos",
        "joder", "jodido", "coño", "cabron", "cabrón",
        "culo", "pendejo", "pendeja", "chingar", "chingada",
        "verga", "pinche",

        // French profanity
        "merde", "putain", "bordel", "connard", "connasse",
        "salaud", "salope", "enculé", "nique", "foutre",

        // German profanity
        "scheiße", "scheisse", "arschloch", "fick", "ficken",
        "hurensohn", "wichser", "fotze",

        // Portuguese profanity
        "merda", "porra", "caralho", "foda", "fodase",
        "puta", "buceta", "cacete",

        // Italian profanity
        "cazzo", "merda", "stronzo", "stronza", "vaffanculo",
        "puttana", "minchia", "figa"
    ]

    /// Patterns for detecting inappropriate content (regex)
    private let inappropriatePatterns: [NSRegularExpression] = {
        var patterns: [NSRegularExpression] = []

        // Phone number patterns (to prevent contact sharing violations)
        if let phonePattern = try? NSRegularExpression(
            pattern: #"\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b"#,
            options: .caseInsensitive
        ) {
            patterns.append(phonePattern)
        }

        // Email-like patterns in early conversations
        if let emailPattern = try? NSRegularExpression(
            pattern: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"#,
            options: .caseInsensitive
        ) {
            patterns.append(emailPattern)
        }

        // Social media handle patterns
        if let socialPattern = try? NSRegularExpression(
            pattern: #"@[A-Za-z0-9_]{3,}"#,
            options: .caseInsensitive
        ) {
            patterns.append(socialPattern)
        }

        return patterns
    }()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Check if text contains inappropriate content
    /// - Parameter text: The text to check
    /// - Returns: ContentCheckResult with details about any issues found
    func checkContent(_ text: String) -> ContentCheckResult {
        let lowercaseText = text.lowercased()
        var issues: [ContentIssue] = []

        // Check for blocked terms (severe)
        for term in blockedTerms {
            if lowercaseText.contains(term) {
                issues.append(.blockedTerm(term))
            }
        }

        // Check for profanity
        let words = lowercaseText.components(separatedBy: .whitespacesAndNewlines)
        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            if profanityList.contains(cleanWord) {
                issues.append(.profanity(cleanWord))
            }
        }

        // Check for inappropriate patterns
        for pattern in inappropriatePatterns {
            let range = NSRange(text.startIndex..., in: text)
            if pattern.firstMatch(in: text, options: [], range: range) != nil {
                issues.append(.suspiciousPattern)
            }
        }

        return ContentCheckResult(
            isClean: issues.isEmpty,
            issues: issues,
            shouldBlock: issues.contains(where: { if case .blockedTerm = $0 { return true } else { return false } })
        )
    }

    /// Filter profanity from text by masking with asterisks
    /// - Parameter text: The text to filter
    /// - Returns: Filtered text with profanity masked
    func filterProfanity(_ text: String) -> String {
        var filteredText = text

        // Replace profanity with asterisks
        for word in profanityList {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(filteredText.startIndex..., in: filteredText)
                let replacement = String(repeating: "*", count: word.count)
                filteredText = regex.stringByReplacingMatches(
                    in: filteredText,
                    options: [],
                    range: range,
                    withTemplate: replacement
                )
            }
        }

        return filteredText
    }

    /// Quick check if text contains any profanity
    /// - Parameter text: The text to check
    /// - Returns: true if profanity detected
    func containsProfanity(_ text: String) -> Bool {
        let lowercaseText = text.lowercased()
        let words = lowercaseText.components(separatedBy: .whitespacesAndNewlines)

        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            if profanityList.contains(cleanWord) {
                return true
            }
        }

        return false
    }

    /// Report content to moderation team
    /// - Parameters:
    ///   - text: The content being reported
    ///   - userId: The user who sent the content
    ///   - reason: Why it's being reported
    func reportContent(_ text: String, userId: String, reason: String) {
        // Log the report for moderation review
        print("📝 [ContentFilter] Content reported:")
        print("   User: \(userId)")
        print("   Reason: \(reason)")
        print("   Content preview: \(text.prefix(100))...")

        // In production, this would:
        // 1. Send to backend moderation queue
        // 2. Store in reports table
        // 3. Trigger notification to moderation team
        // 4. Auto-flag repeat offenders

        Task {
            do {
                try await SupabaseService.shared.reportUser(
                    reportedUserId: userId,
                    reason: reason,
                    description: "Auto-flagged content: \(text.prefix(200))"
                )
            } catch {
                print("❌ [ContentFilter] Failed to submit report: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

/// Result of checking content for inappropriate material
struct ContentCheckResult {
    let isClean: Bool
    let issues: [ContentIssue]
    let shouldBlock: Bool

    var issueDescription: String {
        if isClean {
            return "Content is clean"
        }
        return issues.map { $0.description }.joined(separator: ", ")
    }
}

/// Types of content issues that can be detected
enum ContentIssue: CustomStringConvertible {
    case blockedTerm(String)
    case profanity(String)
    case suspiciousPattern

    var description: String {
        switch self {
        case .blockedTerm(let term):
            return "Blocked term: \(term)"
        case .profanity(let word):
            return "Profanity: \(word)"
        case .suspiciousPattern:
            return "Suspicious pattern detected"
        }
    }

    var severity: ContentSeverity {
        switch self {
        case .blockedTerm:
            return .severe
        case .profanity:
            return .moderate
        case .suspiciousPattern:
            return .low
        }
    }
}

/// Severity levels for content issues
enum ContentSeverity {
    case low        // Warning only
    case moderate   // Filter/mask the content
    case severe     // Block and report

    var shouldNotifyModeration: Bool {
        switch self {
        case .severe:
            return true
        case .moderate, .low:
            return false
        }
    }
}
