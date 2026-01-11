//
//  TTSService.swift
//  LangChat
//
//  Created by Claude Code on 2025-12-13.
//

import Foundation
import AVFoundation
import UIKit

// MARK: - TTS Error Types
enum TTSError: Error, LocalizedError {
    case messageTooLong(wordCount: Int, limit: Int)
    case limitReached(used: Int, limit: Int)
    case apiError(String)
    case audioPlaybackFailed
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .messageTooLong(let count, let limit):
            return "Message too long for text-to-speech (\(count) words). Messages over \(limit) words cannot be played."
        case .limitReached(let used, let limit):
            return "You've used all \(limit) TTS plays this month."
        case .apiError(let message):
            return "Unable to play audio: \(message)"
        case .audioPlaybackFailed:
            return "Unable to play audio right now. Please try again."
        case .notConfigured:
            return "TTS service is not configured."
        }
    }
}

// MARK: - TTS Play Result
struct TTSPlayResult {
    let success: Bool
    let usedPremiumVoice: Bool
    let remainingPlays: Int?
    let error: TTSError?
}

// MARK: - TTS Usage Info
struct TTSUsageInfo {
    let playsUsed: Int
    let playsLimit: Int?
    let billingCycleStart: Date?
    let voiceQuality: TTSVoiceQuality

    var playsRemaining: Int? {
        guard let limit = playsLimit else { return nil }
        return max(0, limit - playsUsed)
    }

    var isLimitReached: Bool {
        guard let limit = playsLimit else { return false }
        return playsUsed >= limit
    }

    var usageDisplayText: String {
        if let limit = playsLimit {
            return "\(playsUsed)/\(limit) plays used"
        } else {
            return "Unlimited plays"
        }
    }
}

// MARK: - TTS Service
class TTSService: NSObject {
    static let shared = TTSService()

    private let speechSynthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var currentCompletion: ((TTSPlayResult) -> Void)?

    // Google Cloud TTS API key (loaded from config)
    private var googleAPIKey: String?

    // Voice config cache
    private var voiceConfigCache: [String: SupabaseService.TTSVoiceConfig] = [:]
    private var voiceConfigLastFetch: Date?
    /// Cache validity: 30 minutes (voice configs rarely change - they're admin-configured)
    private let voiceConfigCacheValidity: TimeInterval = 1800 // 30 minutes

    private override init() {
        super.init()
        speechSynthesizer.delegate = self
        loadConfiguration()
        loadVoiceConfigs()
        setupAppLifecycleObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - App Lifecycle

    private func setupAppLifecycleObservers() {
        // Optionally refresh voice configs when app returns to foreground
        // This handles edge case where admin updated configs while app was backgrounded
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        // Only refresh if cache is more than 30 minutes old (stale)
        // This prevents unnecessary fetches on every foreground event
        guard let lastFetch = voiceConfigLastFetch else {
            // No cache yet, will be populated on first TTS call
            return
        }

        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        if timeSinceLastFetch > voiceConfigCacheValidity {
            print("🔊 TTSService: Cache stale (\(Int(timeSinceLastFetch))s old), refreshing on foreground")
            Task {
                await refreshVoiceConfigs()
            }
        }
    }

    private func loadConfiguration() {
        // Load Google Cloud API key from Config
        googleAPIKey = Config.googleCloudAPIKey
        if let key = googleAPIKey, !key.isEmpty {
            print("✅ TTSService: Google Cloud API key loaded (\(key.prefix(10))...)")
        } else {
            print("⚠️ TTSService: Google Cloud API key NOT loaded - will use Apple TTS only")
        }
    }

    private func loadVoiceConfigs() {
        Task {
            await refreshVoiceConfigs()
        }
    }

    /// Clear voice config cache (forces fresh fetch on next TTS play)
    func clearVoiceCache() {
        voiceConfigCache.removeAll()
        voiceConfigLastFetch = nil
        print("🔊 TTSService: Voice cache cleared")
    }

    /// Refresh voice configs from Supabase
    func refreshVoiceConfigs() async {
        do {
            let configs = try await SupabaseService.shared.fetchTTSVoiceConfigs()
            var cache: [String: SupabaseService.TTSVoiceConfig] = [:]

            for config in configs {
                // Cache by language code
                cache[config.languageCode.lowercased()] = config
                // Also cache by language name for flexibility
                cache[config.languageName.lowercased()] = config
            }

            await MainActor.run {
                self.voiceConfigCache = cache
                self.voiceConfigLastFetch = Date()
            }
            print("✅ TTSService: Cached \(configs.count) voice configs")
        } catch {
            print("⚠️ TTSService: Failed to load voice configs: \(error)")
        }
    }

    /// Get voice config for a language (from cache or Supabase)
    private func getVoiceConfig(forLanguage language: String) async -> SupabaseService.TTSVoiceConfig? {
        let languageLower = language.lowercased()

        // Check if cache needs refresh
        if let lastFetch = voiceConfigLastFetch,
           Date().timeIntervalSince(lastFetch) > voiceConfigCacheValidity {
            await refreshVoiceConfigs()
        }

        // Check cache first
        if let cached = voiceConfigCache[languageLower] {
            return cached
        }

        // Try fetching directly from Supabase
        do {
            if let config = try await SupabaseService.shared.fetchTTSVoiceConfig(forLanguage: language) {
                // Cache it
                await MainActor.run {
                    self.voiceConfigCache[languageLower] = config
                }
                return config
            }
        } catch {
            print("⚠️ TTSService: Failed to fetch voice config for \(language): \(error)")
        }

        return nil
    }

    // MARK: - Public Methods

    /// Check if user can play TTS for a message (only checks word limit, not usage)
    func canPlayTTS(text: String, tier: SubscriptionTier, usageInfo: TTSUsageInfo) -> Result<Void, TTSError> {
        // Check word count
        let wordCount = countWords(in: text)
        let maxWords = tier.maxWordsPerTTSPlay

        if wordCount > maxWords {
            return .failure(.messageTooLong(wordCount: wordCount, limit: maxWords))
        }

        // Note: We don't block TTS based on usage limits anymore
        // Free tier: Always uses Apple TTS (unlimited)
        // Premium tier: Uses Google TTS, falls back to Apple when limit reached
        // Pro tier: Unlimited Google TTS

        return .success(())
    }

    /// Check if user has premium TTS plays remaining
    private func hasPremiumPlaysRemaining(tier: SubscriptionTier, usageInfo: TTSUsageInfo) -> Bool {
        // Pro tier has unlimited
        if tier == .pro { return true }
        // Free tier doesn't get premium TTS
        if tier == .free { return false }
        // Premium tier: check limit
        if let limit = tier.monthlyTTSLimit {
            return usageInfo.playsUsed < limit
        }
        return true
    }

    /// Play TTS for text with appropriate voice based on tier and speaker gender
    /// - Parameters:
    ///   - text: The text to speak
    ///   - language: The language of the text
    ///   - speakerGender: The gender of the speaker (for selecting male/female voice)
    ///   - tier: User's subscription tier
    ///   - usageInfo: Current TTS usage info
    ///   - completion: Callback with the result
    func playTTS(
        text: String,
        language: String,
        speakerGender: String? = nil,
        tier: SubscriptionTier,
        usageInfo: TTSUsageInfo,
        completion: @escaping (TTSPlayResult) -> Void
    ) {
        // Check word count limit
        switch canPlayTTS(text: text, tier: tier, usageInfo: usageInfo) {
        case .failure(let error):
            completion(TTSPlayResult(success: false, usedPremiumVoice: false, remainingPlays: usageInfo.playsRemaining, error: error))
            return
        case .success:
            break
        }

        // Free tier: Always use Apple TTS (unlimited, no tracking)
        if tier == .free {
            playAppleNativeTTS(text: text, language: language) { success in
                completion(TTSPlayResult(
                    success: success,
                    usedPremiumVoice: false,
                    remainingPlays: nil,  // Unlimited for Apple TTS
                    error: success ? nil : .audioPlaybackFailed
                ))
            }
            return
        }

        // Premium/Pro tier: Try Google TTS if available and has plays remaining
        let canUseGoogle = tier.hasPremiumTTS && googleAPIKey != nil && hasPremiumPlaysRemaining(tier: tier, usageInfo: usageInfo)
        print("🔊 TTS Debug - tier: \(tier), hasPremiumTTS: \(tier.hasPremiumTTS), apiKeyPresent: \(googleAPIKey != nil), hasPremiumPlays: \(hasPremiumPlaysRemaining(tier: tier, usageInfo: usageInfo)), canUseGoogle: \(canUseGoogle), speakerGender: \(speakerGender ?? "nil")")

        if canUseGoogle {
            playGoogleTTS(text: text, language: language, speakerGender: speakerGender) { [weak self] success in
                guard let self = self else { return }

                if success {
                    // Increment usage count for premium plays
                    self.incrementUsageCount()
                    let remaining = tier.monthlyTTSLimit.map { max(0, $0 - usageInfo.playsUsed - 1) }
                    completion(TTSPlayResult(success: true, usedPremiumVoice: true, remainingPlays: remaining, error: nil))
                } else {
                    // Fall back to Apple TTS
                    self.playAppleNativeTTS(text: text, language: language) { fallbackSuccess in
                        completion(TTSPlayResult(
                            success: fallbackSuccess,
                            usedPremiumVoice: false,
                            remainingPlays: usageInfo.playsRemaining,
                            error: fallbackSuccess ? nil : .audioPlaybackFailed
                        ))
                    }
                }
            }
        } else {
            // Premium at limit or Google unavailable: Use Apple TTS (unlimited fallback)
            playAppleNativeTTS(text: text, language: language) { success in
                completion(TTSPlayResult(
                    success: success,
                    usedPremiumVoice: false,
                    remainingPlays: nil,  // Apple TTS is unlimited
                    error: success ? nil : .audioPlaybackFailed
                ))
            }
        }
    }

    /// Stop any currently playing TTS
    func stopPlayback() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
    }

    // MARK: - Apple Native TTS

    private func playAppleNativeTTS(text: String, language: String, completion: @escaping (Bool) -> Void) {
        let utterance = AVSpeechUtterance(string: text)

        // Map language code to locale
        let languageCode = mapLanguageToLocale(language)
        if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice
        }

        utterance.rate = 0.4 // Slower for language learning
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9

        currentCompletion = { result in
            completion(result.success)
        }

        speechSynthesizer.speak(utterance)
    }

    // MARK: - Google Cloud TTS

    private func playGoogleTTS(text: String, language: String, speakerGender: String? = nil, completion: @escaping (Bool) -> Void) {
        guard let apiKey = googleAPIKey else {
            completion(false)
            return
        }

        // Fetch voice config asynchronously, then play
        Task {
            // Try to get remote voice config first
            let voiceConfig = await getVoiceConfig(forLanguage: language)

            let googleLanguageCode: String
            let voiceName: String
            let speakingRate: Double
            let pitch: Double
            let gender: String

            if let config = voiceConfig {
                // Use remote config from web-admin
                googleLanguageCode = config.googleLanguageCode
                // Select voice based on speaker gender (uses male/female voice columns if available)
                voiceName = config.voiceName(forGender: speakerGender)
                speakingRate = config.speakingRate
                pitch = config.pitch
                // Determine gender from the selected voice, or use the speaker's gender
                gender = speakerGender?.uppercased() == "MALE" ? "MALE" : speakerGender?.uppercased() == "FEMALE" ? "FEMALE" : config.voiceGender
                print("🔊 Using remote voice config: \(voiceName) for \(language) (speaker: \(speakerGender ?? "unknown"))")
            } else {
                // Fall back to hardcoded mapping
                let fallback = mapLanguageToGoogleVoice(language)
                googleLanguageCode = fallback.languageCode
                voiceName = fallback.voiceName
                speakingRate = 0.85
                pitch = 0
                gender = "NEUTRAL"
                print("🔊 Using fallback voice: \(voiceName) for \(language)")
            }

            await self.executeGoogleTTSRequest(
                text: text,
                apiKey: apiKey,
                googleLanguageCode: googleLanguageCode,
                voiceName: voiceName,
                speakingRate: speakingRate,
                pitch: pitch,
                gender: gender,
                completion: completion
            )
        }
    }

    private func executeGoogleTTSRequest(
        text: String,
        apiKey: String,
        googleLanguageCode: String,
        voiceName: String,
        speakingRate: Double,
        pitch: Double,
        gender: String,
        completion: @escaping (Bool) -> Void
    ) async {
        guard let url = URL(string: "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(apiKey)") else {
            print("❌ Failed to create Google TTS URL")
            completion(false)
            return
        }

        let requestBody: [String: Any] = [
            "input": ["text": text],
            "voice": [
                "languageCode": googleLanguageCode,
                "name": voiceName,
                "ssmlGender": gender
            ],
            "audioConfig": [
                "audioEncoding": "MP3",
                "speakingRate": speakingRate,
                "pitch": pitch
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Google TTS network error: \(error.localizedDescription)")
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("🔊 Google TTS response status: \(httpResponse.statusCode)")
            }
            guard let self = self,
                  let data = data,
                  error == nil else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let audioContent = json["audioContent"] as? String,
                   let audioData = Data(base64Encoded: audioContent) {
                    DispatchQueue.main.async {
                        self.playAudioData(audioData, completion: completion)
                    }
                } else {
                    // Check for error message
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        print("❌ Google TTS error: \(message)")
                    }
                    DispatchQueue.main.async { completion(false) }
                }
            } catch {
                print("Google TTS parse error: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    private func playAudioData(_ data: Data, completion: @escaping (Bool) -> Void) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            currentCompletion = { result in completion(result.success) }
            audioPlayer?.play()
        } catch {
            print("Audio playback error: \(error)")
            completion(false)
        }
    }

    // MARK: - Usage Tracking

    private func incrementUsageCount() {
        Task {
            do {
                try await SupabaseService.shared.incrementTTSUsage()
            } catch {
                print("Failed to increment TTS usage: \(error)")
            }
        }
    }

    // MARK: - Helper Methods

    private func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }

    private func mapLanguageToLocale(_ language: String) -> String {
        // Map common language names/codes to BCP-47 locale codes
        let languageLower = language.lowercased()

        let mapping: [String: String] = [
            "english": "en-US",
            "spanish": "es-ES",
            "french": "fr-FR",
            "german": "de-DE",
            "italian": "it-IT",
            "portuguese": "pt-BR",
            "chinese": "zh-CN",
            "mandarin": "zh-CN",
            "japanese": "ja-JP",
            "korean": "ko-KR",
            "russian": "ru-RU",
            "arabic": "ar-SA",
            "hindi": "hi-IN",
            "dutch": "nl-NL",
            "swedish": "sv-SE",
            "norwegian": "nb-NO",
            "danish": "da-DK",
            "finnish": "fi-FI",
            "polish": "pl-PL",
            "turkish": "tr-TR",
            "thai": "th-TH",
            "vietnamese": "vi-VN",
            "indonesian": "id-ID",
            "malay": "ms-MY",
            "tagalog": "fil-PH",
            "greek": "el-GR",
            "hebrew": "he-IL",
            "czech": "cs-CZ",
            "romanian": "ro-RO",
            "hungarian": "hu-HU",
            "ukrainian": "uk-UA"
        ]

        return mapping[languageLower] ?? language
    }

    private func mapLanguageToGoogleVoice(_ language: String) -> (languageCode: String, voiceName: String) {
        // Map to Google Cloud TTS Neural2 voices
        let languageLower = language.lowercased()

        let mapping: [String: (String, String)] = [
            "english": ("en-US", "en-US-Neural2-J"),
            "spanish": ("es-ES", "es-ES-Neural2-A"),
            "french": ("fr-FR", "fr-FR-Neural2-A"),
            "german": ("de-DE", "de-DE-Neural2-A"),
            "italian": ("it-IT", "it-IT-Neural2-A"),
            "portuguese": ("pt-BR", "pt-BR-Neural2-A"),
            "chinese": ("cmn-CN", "cmn-CN-Wavenet-A"),
            "mandarin": ("cmn-CN", "cmn-CN-Wavenet-A"),
            "japanese": ("ja-JP", "ja-JP-Neural2-B"),
            "korean": ("ko-KR", "ko-KR-Neural2-A"),
            "russian": ("ru-RU", "ru-RU-Wavenet-A"),
            "arabic": ("ar-XA", "ar-XA-Wavenet-A"),
            "hindi": ("hi-IN", "hi-IN-Neural2-A"),
            "dutch": ("nl-NL", "nl-NL-Wavenet-A"),
            "swedish": ("sv-SE", "sv-SE-Wavenet-A"),
            "norwegian": ("nb-NO", "nb-NO-Wavenet-A"),
            "danish": ("da-DK", "da-DK-Wavenet-A"),
            "finnish": ("fi-FI", "fi-FI-Wavenet-A"),
            "polish": ("pl-PL", "pl-PL-Wavenet-A"),
            "turkish": ("tr-TR", "tr-TR-Wavenet-A"),
            "thai": ("th-TH", "th-TH-Neural2-C"),
            "vietnamese": ("vi-VN", "vi-VN-Neural2-A"),
            "indonesian": ("id-ID", "id-ID-Wavenet-A"),
            "greek": ("el-GR", "el-GR-Wavenet-A"),
            "hebrew": ("he-IL", "he-IL-Wavenet-A"),
            "czech": ("cs-CZ", "cs-CZ-Wavenet-A"),
            "romanian": ("ro-RO", "ro-RO-Wavenet-A"),
            "hungarian": ("hu-HU", "hu-HU-Wavenet-A"),
            "ukrainian": ("uk-UA", "uk-UA-Wavenet-A")
        ]

        return mapping[languageLower] ?? ("en-US", "en-US-Neural2-J")
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TTSService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        currentCompletion?(TTSPlayResult(success: true, usedPremiumVoice: false, remainingPlays: nil, error: nil))
        currentCompletion = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        currentCompletion?(TTSPlayResult(success: false, usedPremiumVoice: false, remainingPlays: nil, error: .audioPlaybackFailed))
        currentCompletion = nil
    }
}

// MARK: - AVAudioPlayerDelegate
extension TTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentCompletion?(TTSPlayResult(success: flag, usedPremiumVoice: true, remainingPlays: nil, error: flag ? nil : .audioPlaybackFailed))
        currentCompletion = nil
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        currentCompletion?(TTSPlayResult(success: false, usedPremiumVoice: false, remainingPlays: nil, error: .audioPlaybackFailed))
        currentCompletion = nil
    }
}
