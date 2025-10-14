import Foundation
import Supabase

/// Central service for managing all Supabase interactions
class SupabaseService {

    // MARK: - Singleton
    static let shared = SupabaseService()

    // MARK: - Supabase Client
    let client: SupabaseClient

    // MARK: - Initialization
    private init() {
        // Validate configuration
        SupabaseConfig.validateConfiguration()

        // Initialize Supabase client
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )

        print("✅ Supabase initialized: \(SupabaseConfig.supabaseURL)")
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
    func signInWithApple() async throws {
        // Implement Sign in with Apple OAuth flow
        // Reference: https://supabase.com/docs/guides/auth/social-login/auth-apple
        throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in with Apple not yet implemented"])
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
    func recordSwipe(swipedUserId: String, direction: String) async throws {
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
            try await checkForMatch(with: swipedUserId)
        }

        print("✅ Swipe recorded: \(direction)")
    }

    /// Check if there's a mutual match
    private func checkForMatch(with otherUserId: String) async throws {
        guard let userId = currentUserId else { return }

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
        }
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
}

// MARK: - Messaging Methods
extension SupabaseService {

    /// Get or create conversation between two users
    func getOrCreateConversation(with otherUserId: String) async throws -> ConversationResponse {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Try to find existing conversation
        let existing: [ConversationResponse] = try await client.database
            .from("conversations")
            .select()
            .or("user1_id.eq.\(userId.uuidString),user2_id.eq.\(userId.uuidString)")
            .or("user1_id.eq.\(otherUserId),user2_id.eq.\(otherUserId)")
            .limit(1)
            .execute()
            .value

        if let conversation = existing.first {
            return conversation
        }

        // Create new conversation
        let newConversation = ConversationCreate(
            user1Id: userId.uuidString,
            user2Id: otherUserId
        )

        let response: ConversationResponse = try await client.database
            .from("conversations")
            .insert(newConversation)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Send a message
    func sendMessage(conversationId: String, text: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let message = MessageCreate(
            conversationId: conversationId,
            senderId: userId.uuidString,
            text: text
        )

        try await client.database
            .from("messages")
            .insert(message)
            .execute()

        print("✅ Message sent")
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
    let profilePhotos: [String]?
    let isPremium: Bool
    let granularityLevel: Int
    let onboardingCompleted: Bool
    let location: String?
    let lastActive: String?

    enum CodingKeys: String, CodingKey {
        case id, email, bio, location
        case firstName = "first_name"
        case lastName = "last_name"
        case birthYear = "birth_year"
        case nativeLanguage = "native_language"
        case learningLanguages = "learning_languages"
        case profilePhotos = "profile_photos"
        case isPremium = "is_premium"
        case granularityLevel = "granularity_level"
        case onboardingCompleted = "onboarding_completed"
        case lastActive = "last_active"
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
    let user1Id: String
    let user2Id: String

    enum CodingKeys: String, CodingKey {
        case user1Id = "user1_id"
        case user2Id = "user2_id"
    }
}

struct ConversationResponse: Codable {
    let id: String
    let user1Id: String
    let user2Id: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case createdAt = "created_at"
    }
}

struct MessageCreate: Codable {
    let conversationId: String
    let senderId: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case text
        case conversationId = "conversation_id"
        case senderId = "sender_id"
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
