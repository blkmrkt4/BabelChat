import Foundation
import UIKit
import Supabase

/// Central service for managing all Supabase interactions
class SupabaseService {

    // MARK: - Singleton
    static let shared = SupabaseService()

    // MARK: - Supabase Client
    let client: SupabaseClient

    // MARK: - Initialization
    private init() {
        // Initialize Supabase client with credentials from Config.swift
        // Config.swift loads from environment variables (Xcode scheme or .env file)
        guard let url = URL(string: Config.supabaseURL) else {
            fatalError("❌ Invalid Supabase URL in Config.swift")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.supabaseAnonKey
        )

        print("✅ Supabase initialized: \(Config.supabaseURL)")
    }

    // MARK: - Current User
    var currentUser: Supabase.User? {
        return client.auth.currentUser
    }

    var currentUserId: UUID? {
        return client.auth.currentUser?.id
    }

    var isAuthenticated: Bool {
        return currentUser != nil
    }
}

// MARK: - Authentication Methods
extension SupabaseService {

    /// Sign in with Apple
    /// - Parameter presentingViewController: The view controller to present the Apple sign in sheet from
    func signInWithApple(from presentingViewController: UIViewController) async throws {
        // Use SignInWithAppleService to get Apple credentials
        let appleResult = try await SignInWithAppleService.shared.signIn(from: presentingViewController)

        // Sign in to Supabase using Apple ID token
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: appleResult.idToken,
                nonce: appleResult.nonce
            )
        )

        print("✅ Signed in with Apple via Supabase")

        // If this is a new user and we have their name/email, update their profile
        if let email = appleResult.email {
            print("📧 Apple provided email: \(email)")
            // You can save this to the profile if needed
        }

        if let fullName = appleResult.fullName {
            let firstName = fullName.givenName ?? ""
            let lastName = fullName.familyName ?? ""
            if !firstName.isEmpty {
                print("👤 Apple provided name: \(firstName) \(lastName)")
                // Note: Apple only provides name on FIRST sign in
                // You should save this to user profile immediately
            }
        }
    }

    /// Sign in with email/password
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
        print("✅ Signed in: \(email)")
    }

    /// Sign up with email/password
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
        print("✅ Signed up: \(email)")
    }

    /// Sign out
    func signOut() async throws {
        try await client.auth.signOut()
        print("✅ Signed out")
    }

    /// Send magic link to email
    func sendMagicLink(email: String) async throws {
        try await client.auth.signInWithOTP(email: email)
        print("✅ Magic link sent to: \(email)")
    }

    /// Verify OTP
    func verifyOTP(email: String, token: String) async throws {
        try await client.auth.verifyOTP(email: email, token: token, type: .email)
        print("✅ OTP verified for: \(email)")
    }
}

// MARK: - Storage Methods
extension SupabaseService {

    /// Upload a photo to Supabase Storage (PRIVATE bucket)
    /// Returns the storage path (not a URL) for later retrieval
    func uploadPhoto(_ imageData: Data, userId: String, photoIndex: Int) async throws -> String {
        let fileName = "\(userId)/photo_\(photoIndex)_\(Date().timeIntervalSince1970).jpg"
        let bucketName = "user-photos" // This should be a PRIVATE bucket

        // Upload to private storage
        let path = try await client.storage
            .from(bucketName)
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        // Return the storage path (not URL) - we'll generate signed URLs when needed
        return fileName
    }

    /// Get a signed URL for a private photo (expires in 1 hour)
    func getSignedPhotoURL(path: String, expiresIn: Int = 3600) async throws -> String {
        let bucketName = "user-photos"

        let signedURL = try await client.storage
            .from(bucketName)
            .createSignedURL(path: path, expiresIn: expiresIn)

        return signedURL.absoluteString
    }

    /// Get signed URLs for multiple photos
    func getSignedPhotoURLs(paths: [String], expiresIn: Int = 3600) async throws -> [String] {
        var signedURLs: [String] = []

        for path in paths {
            if !path.isEmpty && !path.hasPrefix("http") {
                // It's a storage path, get signed URL
                let signedURL = try await getSignedPhotoURL(path: path, expiresIn: expiresIn)
                signedURLs.append(signedURL)
            } else if path.hasPrefix("http") {
                // Already a URL (legacy), keep it
                signedURLs.append(path)
            } else {
                // Empty path
                signedURLs.append("")
            }
        }

        return signedURLs
    }

    /// Update user's photo URLs in database
    func updateUserPhotos(photoURLs: [String]) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        try await client.database
            .from("profiles")
            .update(["profile_photos": photoURLs])
            .eq("id", value: userId.uuidString)
            .execute()

        print("✅ Updated user photos in database")
    }

    /// Update user's photo captions in database
    func updatePhotoCaptions(captions: [String?]) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        try await client.database
            .from("profiles")
            .update(["photo_captions": captions])
            .eq("id", value: userId.uuidString)
            .execute()

        print("✅ Updated photo captions in database")
    }
}

// MARK: - Profile Methods
extension SupabaseService {

    /// Get current user's profile
    func getCurrentProfile() async throws -> ProfileResponse {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let response: ProfileResponse = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return response
    }

    /// Fetch a specific user's profile by ID
    func fetchUserProfile(userId: String) async throws -> User? {
        let response: ProfileResponse = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return response.toUser()
    }

    /// Check if current user has completed their profile (onboarding)
    /// Returns true if profile exists and has essential fields filled
    func hasCompletedProfile() async throws -> Bool {
        guard currentUserId != nil else {
            return false
        }

        do {
            let profile = try await getCurrentProfile()

            // Check if essential onboarding fields are filled
            let hasFirstName = !profile.firstName.isEmpty
            let hasNativeLanguage = !profile.nativeLanguage.isEmpty
            let hasLearningLanguages = profile.learningLanguages != nil && !profile.learningLanguages!.isEmpty

            let isProfileComplete = hasFirstName && hasNativeLanguage && hasLearningLanguages

            print("🔍 Profile check - First name: \(hasFirstName), Native: \(hasNativeLanguage), Learning: \(hasLearningLanguages)")

            return isProfileComplete
        } catch {
            // Profile doesn't exist or error fetching
            print("⚠️ Profile check failed: \(error)")
            return false
        }
    }

    /// Update current user's profile
    func updateProfile(_ profile: ProfileUpdate) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        try await client.database
            .from("profiles")
            .update(profile)
            .eq("id", value: userId.uuidString)
            .execute()

        print("✅ Profile updated")
    }

    /// Update current user's last_active timestamp to mark them as online
    func updateLastActive() async {
        guard let userId = currentUserId else { return }

        do {
            let now = ISO8601DateFormatter().string(from: Date())
            try await client.database
                .from("profiles")
                .update(["last_active": now])
                .eq("id", value: userId.uuidString)
                .execute()

            #if DEBUG
            print("✅ Updated last_active timestamp")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to update last_active: \(error)")
            #endif
        }
    }

    /// Update current user's bio
    func updateUserBio(bio: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        try await client.database
            .from("profiles")
            .update(["bio": bio])
            .eq("id", value: userId.uuidString)
            .execute()

        print("✅ Bio updated")
    }

    /// Create initial profile after sign up
    func createProfile(email: String, firstName: String, nativeLanguage: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let profile = ProfileCreate(
            id: userId.uuidString,
            email: email,
            firstName: firstName,
            nativeLanguage: nativeLanguage
        )

        try await client.database
            .from("profiles")
            .insert(profile)
            .execute()

        print("✅ Profile created")
    }

    /// Get profiles for discovery (with filters)
    func getDiscoveryProfiles(limit: Int = 20) async throws -> [ProfileResponse] {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Get profiles excluding current user and already swiped
        let response: [ProfileResponse] = try await client.database
            .from("profiles")
            .select()
            .neq("id", value: userId.uuidString)
            .eq("onboarding_completed", value: true)
            .limit(limit)
            .execute()
            .value

        return response
    }
}

// MARK: - Matching Methods
extension SupabaseService {

    /// Record a swipe
    /// Returns true if this swipe resulted in a mutual match
    func recordSwipe(swipedUserId: String, direction: String) async throws -> Bool {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let swipe = SwipeCreate(
            swiperId: userId.uuidString,
            swipedId: swipedUserId,
            direction: direction
        )

        try await client.database
            .from("swipes")
            .insert(swipe)
            .execute()

        // Check for mutual match if this was a right swipe
        if direction == "right" {
            let didMatch = try await checkForMatch(with: swipedUserId)
            print("✅ Swipe recorded: \(direction)\(didMatch ? " - MATCH!" : "")")
            return didMatch
        }

        print("✅ Swipe recorded: \(direction)")
        return false
    }

    /// Check if there's a mutual match
    /// Returns true if a match was created
    private func checkForMatch(with otherUserId: String) async throws -> Bool {
        guard let userId = currentUserId else { return false }

        // Check if other user swiped right on current user
        let response: [SwipeResponse] = try await client.database
            .from("swipes")
            .select()
            .eq("swiper_id", value: otherUserId)
            .eq("swiped_id", value: userId.uuidString)
            .eq("direction", value: "right")
            .execute()
            .value

        if !response.isEmpty {
            // It's a match! Create match record
            try await createMatch(with: otherUserId)
            return true
        }

        return false
    }

    /// Create a match
    private func createMatch(with otherUserId: String) async throws {
        guard let userId = currentUserId else { return }

        let match = MatchCreate(
            user1Id: userId.uuidString,
            user2Id: otherUserId,
            user1Liked: true,
            user2Liked: true
        )

        try await client.database
            .from("matches")
            .insert(match)
            .execute()

        print("✅ Match created with: \(otherUserId)")

        // Track first match for welcome screen logic
        UserEngagementTracker.shared.markFirstMatch()

        // TODO: Send push notification about match
    }

    /// Get all matches for current user
    func getMatches() async throws -> [MatchResponse] {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let response: [MatchResponse] = try await client.database
            .from("matches")
            .select("""
                *,
                user1:profiles!matches_user1_id_fkey(*),
                user2:profiles!matches_user2_id_fkey(*)
            """)
            .or("user1_id.eq.\(userId.uuidString),user2_id.eq.\(userId.uuidString)")
            .eq("is_mutual", value: true)
            .execute()
            .value

        return response
    }

    /// Delete a match (unmatch)
    func deleteMatch(matchId: String) async throws {
        guard currentUserId != nil else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Delete the match record
        try await client.database
            .from("matches")
            .delete()
            .eq("id", value: matchId)
            .execute()

        print("✅ Match deleted: \(matchId)")
    }

    /// Get already swiped user IDs (to exclude from discovery)
    func getSwipedUserIds() async throws -> Set<String> {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let response: [SwipeResponse] = try await client.database
            .from("swipes")
            .select()
            .eq("swiper_id", value: userId.uuidString)
            .execute()
            .value

        return Set(response.map { $0.swipedId })
    }

    /// Get already matched user IDs (to exclude from discovery)
    func getMatchedUserIds() async throws -> Set<String> {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Use a minimal response type for this query
        struct MatchUserIds: Codable {
            let user1Id: String
            let user2Id: String

            enum CodingKeys: String, CodingKey {
                case user1Id = "user1_id"
                case user2Id = "user2_id"
            }
        }

        let response: [MatchUserIds] = try await client.database
            .from("matches")
            .select("user1_id, user2_id")
            .or("user1_id.eq.\(userId.uuidString),user2_id.eq.\(userId.uuidString)")
            .eq("is_mutual", value: true)
            .execute()
            .value

        // Extract the other user's ID from each match
        var matchedIds = Set<String>()
        for match in response {
            if match.user1Id == userId.uuidString {
                matchedIds.insert(match.user2Id)
            } else {
                matchedIds.insert(match.user1Id)
            }
        }

        return matchedIds
    }

    /// Get matched user profiles for discover feed with scoring
    /// Returns profiles sorted by match score
    func getMatchedDiscoveryProfiles(limit: Int = 20) async throws -> [(user: User, score: Int, reasons: [String])] {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // 1. Get current user's profile
        let currentProfile = try await getCurrentProfile()
        guard let currentUser = currentProfile.toUser() else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert current profile"])
        }

        // 2. Get already swiped user IDs and matched user IDs to exclude
        async let swipedIds = getSwipedUserIds()
        async let matchedIds = getMatchedUserIds()
        let (swiped, matched) = try await (swipedIds, matchedIds)
        let excludedIds = swiped.union(matched)

        print("🔍 Excluding \(swiped.count) swiped users and \(matched.count) matched users from discovery")

        // 3. Fetch all potential candidate profiles
        let profiles = try await getDiscoveryProfiles(limit: 100) // Fetch more than needed for filtering

        // 4. Convert to User models and filter out swiped and matched profiles
        let candidateUsers = profiles.compactMap { profile -> User? in
            if excludedIds.contains(profile.id) {
                return nil // Skip already swiped or matched
            }
            return profile.toUser()
        }

        print("✅ Found \(candidateUsers.count) potential candidates after filtering")

        // 5. Use MatchingService to filter and score
        let scoredMatches = MatchingService.shared.findMatches(for: currentUser, from: candidateUsers)

        // 6. Return top matches up to limit
        return Array(scoredMatches.prefix(limit))
    }

    /// Simple version that returns just User models
    func getDiscoveryUsers(limit: Int = 20) async throws -> [User] {
        let scoredMatches = try await getMatchedDiscoveryProfiles(limit: limit)
        return scoredMatches.map { $0.user }
    }
}

// MARK: - Messaging Methods
extension SupabaseService {

    /// Get or create conversation for a match (using match ID directly)
    func getOrCreateConversation(forMatchId matchId: String) async throws -> ConversationResponse {
        // Check if this match already has a conversation
        struct MatchWithConversation: Codable {
            let id: String
            let conversationId: String?

            enum CodingKeys: String, CodingKey {
                case id
                case conversationId = "conversation_id"
            }
        }

        print("🔍 Fetching match: \(matchId)")
        let matches: [MatchWithConversation] = try await client.database
            .from("matches")
            .select("id,conversation_id")  // Remove space in select
            .eq("id", value: matchId)
            .limit(1)
            .execute()
            .value

        guard let match = matches.first else {
            throw NSError(domain: "SupabaseService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Match not found: \(matchId)"])
        }
        print("✅ Found match, conversation_id: \(match.conversationId ?? "nil")")

        // If match has a conversation, fetch and return it
        if let conversationId = match.conversationId, !conversationId.isEmpty {
            let conversations: [ConversationResponse] = try await client.database
                .from("conversations")
                .select()
                .eq("id", value: conversationId)
                .limit(1)
                .execute()
                .value

            // If we found the conversation, return it
            if let conversation = conversations.first {
                return conversation
            }

            // Otherwise fall through to create a new one
            print("⚠️ Conversation \(conversationId) not found, creating new one")
        }

        // Create new conversation for this match
        let newConversation = ConversationCreate(matchId: matchId)

        let response: ConversationResponse = try await client.database
            .from("conversations")
            .insert(newConversation)
            .select()
            .single()
            .execute()
            .value

        // Update the match with the conversation ID
        try await client.database
            .from("matches")
            .update(["conversation_id": response.id])
            .eq("id", value: matchId)
            .execute()

        print("✅ Created new conversation: \(response.id) for match: \(matchId)")
        return response
    }

    /// Get or create conversation between two users
    func getOrCreateConversation(with otherUserId: String) async throws -> ConversationResponse {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // First, find the match between these two users
        let matchQuery = """
            id,
            conversation_id,
            user1_id,
            user2_id
        """

        struct MatchWithConversation: Codable {
            let id: String
            let conversationId: String?
            let user1Id: String
            let user2Id: String

            enum CodingKeys: String, CodingKey {
                case id
                case conversationId = "conversation_id"
                case user1Id = "user1_id"
                case user2Id = "user2_id"
            }
        }

        // Find match where current user is either user1 or user2, and other user is the opposite
        let matches: [MatchWithConversation] = try await client.database
            .from("matches")
            .select()
            .or("and(user1_id.eq.\(userId.uuidString),user2_id.eq.\(otherUserId)),and(user1_id.eq.\(otherUserId),user2_id.eq.\(userId.uuidString))")
            .limit(1)
            .execute()
            .value

        guard let match = matches.first else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No match found between users"])
        }

        let matchId = match.id

        // Check if match already has a conversation
        if let conversationId = match.conversationId, !conversationId.isEmpty {
            // Fetch the conversation
            let conversations: [ConversationResponse] = try await client.database
                .from("conversations")
                .select()
                .eq("id", value: conversationId)
                .limit(1)
                .execute()
                .value

            // If we found the conversation, return it
            if let conversation = conversations.first {
                return conversation
            }

            // Otherwise fall through to create a new one
            print("⚠️ Conversation \(conversationId) not found, creating new one")
        }

        // Create new conversation for this match
        let newConversation = ConversationCreate(matchId: matchId)

        let response: ConversationResponse = try await client.database
            .from("conversations")
            .insert(newConversation)
            .select()
            .single()
            .execute()
            .value

        // Update the match with the conversation ID
        try await client.database
            .from("matches")
            .update(["conversation_id": response.id])
            .eq("id", value: matchId)
            .execute()

        return response
    }

    /// Send a message
    func sendMessage(conversationId: String, receiverId: String, text: String, language: String = "English") async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let message = MessageCreate(
            conversationId: conversationId,
            senderId: userId.uuidString,
            receiverId: receiverId,
            originalText: text,
            originalLanguage: language
        )

        try await client.database
            .from("messages")
            .insert(message)
            .execute()

        print("✅ Message sent")

        // Track first message for welcome screen logic
        UserEngagementTracker.shared.markFirstMessage()
    }

    /// Send a message as a specific sender (for AI responses)
    func sendMessageAs(senderId: String, conversationId: String, receiverId: String, text: String, language: String = "English") async throws {
        let message = MessageCreate(
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            originalText: text,
            originalLanguage: language
        )

        try await client.database
            .from("messages")
            .insert(message)
            .execute()

        print("✅ Message sent as \(senderId)")
    }

    /// Get messages for a conversation
    func getMessages(conversationId: String, limit: Int = 50) async throws -> [MessageResponse] {
        let response: [MessageResponse] = try await client.database
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: true)
            .limit(limit)
            .execute()
            .value

        return response
    }

    /// Subscribe to new messages in a conversation
    func subscribeToMessages(conversationId: String, onMessage: @escaping (MessageResponse) -> Void) -> RealtimeChannel {
        let channel = client.realtime.channel("messages:\(conversationId)")

        let subscription = channel
            .on("postgres_changes", filter: ChannelFilter(event: "INSERT", schema: "public", table: "messages", filter: "conversation_id=eq.\(conversationId)")) { message in
                if let payload = message.payload["record"] as? [String: Any] {
                    // Parse message
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: payload)
                        let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: jsonData)
                        onMessage(messageResponse)
                    } catch {
                        print("❌ Error parsing message: \(error)")
                    }
                }
            }

        subscription.subscribe()

        return channel
    }
}

// MARK: - Data Models

struct ProfileResponse: Codable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String?
    let bio: String?
    let birthYear: Int?
    let nativeLanguage: String
    let learningLanguages: [String]?
    let profilePhotos: [String]? // Storage paths, not URLs
    let photoCaptions: [String?]? // Captions for each photo
    let isPremium: Bool
    let granularityLevel: Int
    let onboardingCompleted: Bool
    let location: String?
    let lastActive: String?
    let allowNonNativeMatches: Bool?
    let minProficiencyLevel: String?
    let maxProficiencyLevel: String?

    // New matching preference fields
    let gender: String?
    let genderPreference: String?
    let minAge: Int?
    let maxAge: Int?
    let locationPreference: String?
    let latitude: Double?
    let longitude: Double?
    let preferredCountries: [String]?
    let travelDestination: TravelDestinationDB?
    let relationshipIntents: [String]?
    let learningContexts: [String]?

    enum CodingKeys: String, CodingKey {
        case id, email, bio, location, latitude, longitude
        case firstName = "first_name"
        case lastName = "last_name"
        case birthYear = "birth_year"
        case nativeLanguage = "native_language"
        case learningLanguages = "learning_languages"
        case profilePhotos = "profile_photos"
        case photoCaptions = "photo_captions"
        case isPremium = "is_premium"
        case granularityLevel = "granularity_level"
        case onboardingCompleted = "onboarding_completed"
        case lastActive = "last_active"
        case allowNonNativeMatches = "allow_non_native_matches"
        case minProficiencyLevel = "min_proficiency_level"
        case maxProficiencyLevel = "max_proficiency_level"
        case gender
        case genderPreference = "gender_preference"
        case minAge = "min_age"
        case maxAge = "max_age"
        case locationPreference = "location_preference"
        case preferredCountries = "preferred_countries"
        case travelDestination = "travel_destination"
        case relationshipIntents = "relationship_intents"
        case learningContexts = "learning_contexts"
    }

    /// Convert ProfileResponse to User model
    func toUser() -> User? {
        // Parse native language
        guard let nativeLang = Language.allCases.first(where: { $0.code == nativeLanguage || $0.name.lowercased() == nativeLanguage.lowercased() }) else {
            print("⚠️ Unknown native language: \(nativeLanguage)")
            return nil
        }

        let nativeUserLanguage = UserLanguage(
            language: nativeLang,
            proficiency: .native,
            isNative: true
        )

        // Parse learning languages
        let learningUserLanguages = (learningLanguages ?? []).compactMap { langString -> UserLanguage? in
            guard let lang = Language.allCases.first(where: { $0.code == langString || $0.name.lowercased() == langString.lowercased() }) else {
                return nil
            }

            // Try to get proficiency from minProficiencyLevel or default to intermediate
            let proficiency: LanguageProficiency
            if let profLevel = minProficiencyLevel, let level = LanguageProficiency.from(string: profLevel) {
                proficiency = level
            } else {
                proficiency = .intermediate
            }

            return UserLanguage(language: lang, proficiency: proficiency, isNative: false)
        }

        // Convert open to languages (same as learning for now)
        let openToLanguages = learningUserLanguages.map { $0.language }

        // Create matching preferences
        let matchingPrefs = createMatchingPreferences()

        // Split 7-photo array: indices 0-5 for grid, index 6 for profile
        let allPhotos = profilePhotos ?? []
        let profileImageURL = allPhotos.count > 6 ? allPhotos[6] : allPhotos.first
        let gridPhotoURLs = Array(allPhotos.prefix(6))

        return User(
            id: id,
            username: email.components(separatedBy: "@").first ?? "user",
            firstName: firstName,
            lastName: lastName,
            bio: bio,
            profileImageURL: profileImageURL,
            photoURLs: gridPhotoURLs,
            nativeLanguage: nativeUserLanguage,
            learningLanguages: learningUserLanguages,
            openToLanguages: openToLanguages,
            practiceLanguages: nil,
            location: location,
            showCityInProfile: true,
            matchedDate: nil,
            isOnline: isRecentlyActive(),
            isAI: false,
            birthYear: birthYear,
            matchingPreferences: matchingPrefs
        )
    }

    /// Check if user has been active recently (within 24 hours)
    private func isRecentlyActive() -> Bool {
        guard let lastActiveString = lastActive else { return false }

        let formatter = ISO8601DateFormatter()
        guard let lastActiveDate = formatter.date(from: lastActiveString) else { return false }

        let hoursSinceActive = Date().timeIntervalSince(lastActiveDate) / 3600
        return hoursSinceActive < 24
    }

    /// Create MatchingPreferences from profile data
    private func createMatchingPreferences() -> MatchingPreferences {
        // Parse gender
        let userGender = Gender.allCases.first(where: { $0.rawValue == gender }) ?? .preferNotToSay

        // Parse gender preference
        let userGenderPreference = GenderPreference.allCases.first(where: { $0.rawValue == genderPreference }) ?? .all

        // Parse location preference
        let userLocationPreference = LocationPreference.allCases.first(where: { $0.rawValue == locationPreference }) ?? .anywhere

        // Parse relationship intents
        let userRelationshipIntents = (relationshipIntents ?? []).compactMap { intentString in
            RelationshipIntent.allCases.first(where: { $0.rawValue == intentString })
        }
        let finalIntents = userRelationshipIntents.isEmpty ? [.languagePracticeOnly] : userRelationshipIntents

        // Parse learning contexts
        let userLearningContexts = (learningContexts ?? []).compactMap { contextString in
            LearningContext.allCases.first(where: { $0.rawValue == contextString })
        }
        let finalContexts = userLearningContexts.isEmpty ? [.fun] : userLearningContexts

        // Convert travel destination
        let userTravelDestination = travelDestination?.toModel()

        // Parse proficiency levels
        let minProf = minProficiencyLevel.flatMap { LanguageProficiency.from(string: $0) } ?? .beginner
        let maxProf = maxProficiencyLevel.flatMap { LanguageProficiency.from(string: $0) } ?? .advanced

        return MatchingPreferences(
            gender: userGender,
            genderPreference: userGenderPreference,
            minAge: minAge ?? 18,
            maxAge: maxAge ?? 80,
            locationPreference: userLocationPreference,
            latitude: latitude,
            longitude: longitude,
            preferredCountries: preferredCountries,
            travelDestination: userTravelDestination,
            relationshipIntents: finalIntents,
            learningContexts: finalContexts,
            allowNonNativeMatches: allowNonNativeMatches ?? false,
            minProficiencyLevel: minProf,
            maxProficiencyLevel: maxProf
        )
    }
}

struct ProfileCreate: Codable {
    let id: String
    let email: String
    let firstName: String
    let nativeLanguage: String

    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case nativeLanguage = "native_language"
    }
}

struct ProfileUpdate: Codable {
    var firstName: String?
    var lastName: String?
    var bio: String?
    var location: String?
    var learningLanguages: [String]?
    var granularityLevel: Int?

    enum CodingKeys: String, CodingKey {
        case bio, location
        case firstName = "first_name"
        case lastName = "last_name"
        case learningLanguages = "learning_languages"
        case granularityLevel = "granularity_level"
    }
}

struct SwipeCreate: Codable {
    let swiperId: String
    let swipedId: String
    let direction: String

    enum CodingKeys: String, CodingKey {
        case direction
        case swiperId = "swiper_id"
        case swipedId = "swiped_id"
    }
}

struct SwipeResponse: Codable {
    let id: String
    let swiperId: String
    let swipedId: String
    let direction: String

    enum CodingKeys: String, CodingKey {
        case id, direction
        case swiperId = "swiper_id"
        case swipedId = "swiped_id"
    }
}

struct MatchCreate: Codable {
    let user1Id: String
    let user2Id: String
    let user1Liked: Bool
    let user2Liked: Bool

    enum CodingKeys: String, CodingKey {
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case user1Liked = "user1_liked"
        case user2Liked = "user2_liked"
    }
}

struct MatchResponse: Codable {
    let id: String
    let user1Id: String
    let user2Id: String
    let isMutual: Bool
    let matchedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case isMutual = "is_mutual"
        case matchedAt = "matched_at"
    }
}

struct ConversationCreate: Codable {
    let matchId: String

    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
    }
}

struct ConversationResponse: Codable {
    let id: String
    let matchId: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case createdAt = "created_at"
    }
}

struct MessageCreate: Codable {
    let conversationId: String
    let senderId: String
    let receiverId: String
    let originalText: String
    let originalLanguage: String

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case originalText = "original_text"
        case originalLanguage = "original_language"
    }
}

struct MessageResponse: Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let text: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, text
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case createdAt = "created_at"
    }
}

// MARK: - Database Model Conversions

struct TravelDestinationDB: Codable {
    let city: String?
    let country: String
    let countryName: String
    let startDate: String?
    let endDate: String?

    enum CodingKeys: String, CodingKey {
        case city, country
        case countryName = "country_name"
        case startDate = "start_date"
        case endDate = "end_date"
    }

    func toModel() -> TravelDestination {
        let formatter = ISO8601DateFormatter()
        let start = startDate.flatMap { formatter.date(from: $0) }
        let end = endDate.flatMap { formatter.date(from: $0) }

        return TravelDestination(
            city: city,
            country: country,
            countryName: countryName,
            startDate: start,
            endDate: end
        )
    }
}

// MARK: - Model Evaluations Methods
extension SupabaseService {

    /// Get all model evaluations for a specific category
    func getModelEvaluations(category: String) async throws -> [ModelEvaluationResponse] {
        let response: [ModelEvaluationResponse] = try await client.database
            .from("model_evaluations")
            .select()
            .eq("category", value: category)
            .order("score", ascending: false)
            .execute()
            .value

        return response
    }

    /// Get the highest scoring evaluation for each model in a category
    func getBestModelEvaluations(category: String) async throws -> [String: ModelEvaluationResponse] {
        let allEvaluations = try await getModelEvaluations(category: category)

        var bestEvaluations: [String: ModelEvaluationResponse] = [:]

        for evaluation in allEvaluations {
            if let existing = bestEvaluations[evaluation.modelId] {
                if evaluation.score > existing.score {
                    bestEvaluations[evaluation.modelId] = evaluation
                }
            } else {
                bestEvaluations[evaluation.modelId] = evaluation
            }
        }

        return bestEvaluations
    }
}

// MARK: - Model Evaluation Data Models
struct ModelEvaluationResponse: Codable {
    let id: String
    let timestamp: String
    let testInput: String
    let sourceLang: String
    let targetLang: String
    let baselineType: String
    let baselineModelId: String?
    let baselineModelName: String?
    let googleTranslateOutput: String
    let modelId: String
    let modelName: String
    let modelOutput: String
    let responseTime: Double?
    let evaluationModelId: String
    let evaluationModelName: String
    let modelPrompt: String?
    let evaluationPrompt: String?
    let score: Double
    let scores: [String: Double]?
    let detailedScores: DetailedScores?
    let evaluation: String
    let category: String
    let error: String?
    let errorType: String?

    struct DetailedScores: Codable {
        let translationAccuracy: ScoreWithReason?
        let responseSpeed: ScoreWithReason?
        let combinedTotal: Double?

        struct ScoreWithReason: Codable {
            let score: Double
            let reason: String
        }

        enum CodingKeys: String, CodingKey {
            case translationAccuracy = "translation_accuracy"
            case responseSpeed = "response_speed"
            case combinedTotal = "combined_total"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, timestamp, category, error, evaluation
        case testInput = "test_input"
        case sourceLang = "source_lang"
        case targetLang = "target_lang"
        case baselineType = "baseline_type"
        case baselineModelId = "baseline_model_id"
        case baselineModelName = "baseline_model_name"
        case googleTranslateOutput = "google_translate_output"
        case modelId = "model_id"
        case modelName = "model_name"
        case modelOutput = "model_output"
        case responseTime = "response_time"
        case evaluationModelId = "evaluation_model_id"
        case evaluationModelName = "evaluation_model_name"
        case modelPrompt = "model_prompt"
        case evaluationPrompt = "evaluation_prompt"
        case score, scores
        case detailedScores = "detailed_scores"
        case errorType = "error_type"
    }
}

// MARK: - Reporting Methods
extension SupabaseService {

    /// Report a user's photo for inappropriate content
    func reportPhoto(
        reportedUserId: String,
        photoURL: String,
        reason: String,
        description: String? = nil
    ) async throws {
        guard let currentUserId = currentUserId?.uuidString else {
            throw NSError(domain: "SupabaseService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let report = ReportCreate(
            reporterId: currentUserId,
            reportedId: reportedUserId,
            reason: reason,
            description: description,
            photoUrl: photoURL
        )

        try await client.database
            .from("reported_users")
            .insert(report)
            .execute()

        print("✅ Photo reported successfully")
    }

    /// Get current user's reports
    func getUserReports() async throws -> [ReportResponse] {
        guard let currentUserId = currentUserId?.uuidString else {
            throw NSError(domain: "SupabaseService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let reports: [ReportResponse] = try await client.database
            .from("reported_users")
            .select()
            .eq("reporter_id", value: currentUserId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return reports
    }
}

// MARK: - Report Data Models

struct ReportCreate: Codable {
    let reporterId: String
    let reportedId: String
    let reason: String
    let description: String?
    let photoUrl: String?

    enum CodingKeys: String, CodingKey {
        case reporterId = "reporter_id"
        case reportedId = "reported_id"
        case reason
        case description
        case photoUrl = "photo_url"
    }
}

struct ReportResponse: Codable {
    let id: String
    let reporterId: String
    let reportedId: String
    let reason: String
    let description: String?
    let photoUrl: String?
    let status: String
    let createdAt: String
    let reviewedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case reporterId = "reporter_id"
        case reportedId = "reported_id"
        case reason
        case description
        case photoUrl = "photo_url"
        case status
        case createdAt = "created_at"
        case reviewedAt = "reviewed_at"
    }
}

// MARK: - Language Proficiency Extension

extension LanguageProficiency {
    static func from(string: String) -> LanguageProficiency? {
        switch string.lowercased() {
        case "beginner", "beg": return .beginner
        case "intermediate", "int": return .intermediate
        case "advanced", "adv": return .advanced
        case "native": return .native
        default: return nil
        }
    }
}
