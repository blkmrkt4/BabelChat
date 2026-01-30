import Foundation
import UIKit
import Supabase

/// Type-erased Encodable wrapper for building dynamic dictionaries
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

/// Central service for managing all Supabase interactions
class SupabaseService {

    // MARK: - Singleton
    static let shared = SupabaseService()

    // MARK: - Supabase Client
    let client: SupabaseClient

    // MARK: - Configuration Status
    private(set) var isConfigured: Bool = false

    // MARK: - Placeholder URL (safe, guaranteed to parse)
    // swiftlint:disable:next force_unwrapping
    private static let placeholderURL = URL(string: "https://placeholder.supabase.co")!

    // MARK: - Initialization
    private init() {
        // Initialize Supabase client with credentials from Config.swift
        // Config.swift loads from environment variables (Xcode scheme or .env file)
        if Config.supabaseURL.isEmpty || Config.supabaseAnonKey.isEmpty {
            print("⚠️ Supabase credentials not configured - using placeholder URL")
            // Use a placeholder URL - operations will fail gracefully
            self.client = SupabaseClient(
                supabaseURL: Self.placeholderURL,
                supabaseKey: "placeholder"
            )
            self.isConfigured = false
            return
        }

        guard let url = URL(string: Config.supabaseURL) else {
            print("❌ Invalid Supabase URL in Config.swift: \(Config.supabaseURL)")
            self.client = SupabaseClient(
                supabaseURL: Self.placeholderURL,
                supabaseKey: "placeholder"
            )
            self.isConfigured = false
            return
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.supabaseAnonKey
        )
        self.isConfigured = true

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

    /// Restore persisted session on app launch.
    /// Call this before checking isAuthenticated on cold start.
    func restoreSession() async {
        do {
            _ = try await client.auth.session
            print("✅ Session restored: \(currentUser?.id.uuidString ?? "nil")")
        } catch {
            print("⚠️ No valid session to restore: \(error.localizedDescription)")
        }
    }
}

// MARK: - Authentication Methods
extension SupabaseService {

    /// Sign in with Apple
    /// - Parameter presentingViewController: The view controller to present the Apple sign in sheet from
    func signInWithApple(from presentingViewController: UIViewController) async throws {
        // Use SignInWithAppleService to get Apple credentials
        let appleResult = try await SignInWithAppleService.shared.signIn(from: presentingViewController)

        // Persist Apple-provided data IMMEDIATELY before any network calls.
        // Apple only provides name/email on the FIRST sign-in ever — if we lose it, it's gone forever.
        if let email = appleResult.email {
            print("📧 Apple provided email: \(email)")
            UserDefaults.standard.set(email, forKey: "appleProvidedEmail")
            UserDefaults.standard.set(email, forKey: "email")
        }

        if let fullName = appleResult.fullName {
            let firstName = fullName.givenName ?? ""
            let lastName = fullName.familyName ?? ""
            if !firstName.isEmpty {
                print("👤 Apple provided name: \(firstName) \(lastName)")
                UserDefaults.standard.set(firstName, forKey: "appleProvidedFirstName")
                UserDefaults.standard.set(lastName, forKey: "appleProvidedLastName")
                UserDefaults.standard.set(firstName, forKey: "firstName")
                UserDefaults.standard.set(lastName, forKey: "lastName")
            }
        }
        UserDefaults.standard.synchronize()

        // Sign in to Supabase using Apple ID token
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: appleResult.idToken,
                nonce: appleResult.nonce
            )
        )

        print("✅ Signed in with Apple via Supabase")
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

    /// Delete the current user's account and all associated data
    func deleteAccount() async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        let userIdString = userId.uuidString
        print("🗑️ Starting account deletion for user: \(userIdString)")

        // Delete user data from all tables (order matters for foreign key constraints)
        // Messages first (references conversations and users)
        try? await client
            .from("messages")
            .delete()
            .or("sender_id.eq.\(userIdString),receiver_id.eq.\(userIdString)")
            .execute()
        print("  ✅ Messages deleted")

        // Conversations
        try? await client
            .from("conversations")
            .delete()
            .or("user1_id.eq.\(userIdString),user2_id.eq.\(userIdString)")
            .execute()
        print("  ✅ Conversations deleted")

        // Reported users (both reporter and reported)
        try? await client
            .from("reported_users")
            .delete()
            .or("reporter_id.eq.\(userIdString),reported_user_id.eq.\(userIdString)")
            .execute()
        print("  ✅ Reports deleted")

        // Muse interactions
        try? await client
            .from("muse_interactions")
            .delete()
            .eq("user_id", value: userIdString)
            .execute()
        print("  ✅ Muse interactions deleted")

        // Feedback
        try? await client
            .from("feedback")
            .delete()
            .eq("user_id", value: userIdString)
            .execute()
        print("  ✅ Feedback deleted")

        // Matches
        try? await client
            .from("matches")
            .delete()
            .or("user1_id.eq.\(userIdString),user2_id.eq.\(userIdString)")
            .execute()
        print("  ✅ Matches deleted")

        // Swipes
        try? await client
            .from("swipes")
            .delete()
            .or("swiper_id.eq.\(userIdString),swiped_id.eq.\(userIdString)")
            .execute()
        print("  ✅ Swipes deleted")

        // User languages
        try? await client
            .from("user_languages")
            .delete()
            .eq("user_id", value: userIdString)
            .execute()
        print("  ✅ User languages deleted")

        // User preferences
        try? await client
            .from("user_preferences")
            .delete()
            .eq("user_id", value: userIdString)
            .execute()
        print("  ✅ User preferences deleted")

        // Invites
        try? await client
            .from("invites")
            .delete()
            .eq("inviter_id", value: userIdString)
            .execute()
        print("  ✅ Invites deleted")

        // Delete profile (this is the main user record)
        try? await client
            .from("profiles")
            .delete()
            .eq("id", value: userIdString)
            .execute()
        print("  ✅ Profile deleted")

        // Delete profile photos from storage
        do {
            let files = try await client.storage.from("profile-photos").list(path: userIdString)
            if !files.isEmpty {
                let filePaths = files.map { "\(userIdString)/\($0.name)" }
                try await client.storage.from("profile-photos").remove(paths: filePaths)
                print("  ✅ Profile photos deleted")
            }
        } catch {
            print("  ⚠️ Could not delete photos: \(error.localizedDescription)")
        }

        // Delete the auth.users row via server-side function (must be called while still authenticated)
        do {
            try await client.rpc("delete_auth_user").execute()
            print("  ✅ Auth user deleted")
        } catch {
            print("  ⚠️ Could not delete auth user: \(error.localizedDescription)")
        }

        // Sign out (clears local session tokens)
        try await client.auth.signOut()
        print("✅ Account deletion complete, signed out")
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

    /// Check if current user is banned
    /// Returns ban info if banned, nil if not banned
    func checkBanStatus() async throws -> BanInfo? {
        guard let userId = currentUserId else {
            return nil
        }

        struct ProfileBanStatus: Decodable {
            let is_banned: Bool?
            let ban_reason: String?
            let banned_at: String?
        }

        let response: ProfileBanStatus = try await client
            .from("profiles")
            .select("is_banned, ban_reason, banned_at")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        if response.is_banned == true {
            return BanInfo(
                isBanned: true,
                reason: response.ban_reason,
                bannedAt: response.banned_at
            )
        }

        return nil
    }
}

/// Information about a user ban
struct BanInfo {
    let isBanned: Bool
    let reason: String?
    let bannedAt: String?
}

// MARK: - Storage Methods
extension SupabaseService {

    /// Base URL for public storage bucket
    private static var publicStorageBaseURL: String {
        return "\(Config.supabaseURL)/storage/v1/object/public/user-photos"
    }

    /// Upload a photo to Supabase Storage (PUBLIC bucket)
    /// Returns the permanent public URL that never expires
    func uploadPhoto(_ imageData: Data, userId: String, photoIndex: Int) async throws -> String {
        let fileName = "\(userId)/photo_\(photoIndex)_\(Date().timeIntervalSince1970).jpg"
        let bucketName = "user-photos"

        // Upload to public storage
        _ = try await client.storage
            .from(bucketName)
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        // Return the permanent public URL (never expires)
        return "\(Self.publicStorageBaseURL)/\(fileName)"
    }

    /// Convert a storage path to a permanent public URL
    /// This is a synchronous operation - no network call needed
    func getPublicPhotoURL(path: String) -> String {
        // If it's already a full URL, return as-is
        if path.hasPrefix("http") {
            return path
        }
        // If it's empty, return empty
        if path.isEmpty {
            return ""
        }
        // Convert storage path to public URL
        return "\(Self.publicStorageBaseURL)/\(path)"
    }

    /// Convert multiple storage paths to permanent public URLs
    /// This is a synchronous operation - no network calls needed
    func getPublicPhotoURLs(paths: [String]) -> [String] {
        return paths.map { getPublicPhotoURL(path: $0) }
    }

    // MARK: - Legacy Support (deprecated, use getPublicPhotoURL instead)

    /// Get a signed URL for a private photo (expires in 1 hour)
    /// @available(*, deprecated, message: "Use getPublicPhotoURL instead - bucket is now public")
    func getSignedPhotoURL(path: String, expiresIn: Int = 3600) async throws -> String {
        // For backwards compatibility, just return the public URL
        return getPublicPhotoURL(path: path)
    }

    /// Get signed URLs for multiple photos
    /// @available(*, deprecated, message: "Use getPublicPhotoURLs instead - bucket is now public")
    func getSignedPhotoURLs(paths: [String], expiresIn: Int = 3600) async throws -> [String] {
        // For backwards compatibility, just return public URLs
        return getPublicPhotoURLs(paths: paths)
    }

    /// Update user's photo URLs in database
    func updateUserPhotos(photoURLs: [String]) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        try await client
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

        try await client
            .from("profiles")
            .update(["photo_captions": captions])
            .eq("id", value: userId.uuidString)
            .execute()

        print("✅ Updated photo captions in database")
    }

    func updatePhotoBlurSettings(blurSettings: [Bool]) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        try await client
            .from("profiles")
            .update(["photo_blur_settings": blurSettings])
            .eq("id", value: userId.uuidString)
            .execute()

        print("✅ Updated photo blur settings in database")
    }
}

// MARK: - Profile Methods
extension SupabaseService {

    /// Get current user's profile
    func getCurrentProfile() async throws -> ProfileResponse {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        print("🔍 getCurrentProfile: Fetching profile for user \(userId)...")

        let response: ProfileResponse = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        print("🔍 getCurrentProfile returned:")
        print("   firstName: '\(response.firstName)'")
        print("   bio: '\(response.bio?.prefix(30) ?? "nil")...'")
        print("   learningLanguages: \(response.learningLanguages ?? [])")

        return response
    }

    /// Fetch a specific user's profile by ID
    func fetchUserProfile(userId: String) async throws -> User? {
        let response: ProfileResponse = try await client
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
    /// Throws on network errors so caller can show offline screen
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
            // Check if this is a network error - if so, throw it so caller can handle appropriately
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain ||
               nsError.domain == "NSPOSIXErrorDomain" ||
               nsError.code == -1009 || // No internet
               nsError.code == -1001 || // Timeout
               nsError.code == -1004 || // Could not connect
               nsError.code == -1005 || // Network connection lost
               nsError.code == -1020 {  // Data not allowed
                print("❌ Network error during profile check: \(error)")
                throw error
            }

            // Profile doesn't exist or other non-network error - return false
            print("⚠️ Profile check failed (non-network): \(error)")
            return false
        }
    }

    /// Update current user's profile
    func updateProfile(_ profile: ProfileUpdate) async throws {
        guard let userId = currentUserId else {
            print("❌ updateProfile: Not authenticated")
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        print("📤 updateProfile: Updating profile for user \(userId)...")

        // Encode to JSON to see what's being sent
        if let jsonData = try? JSONEncoder().encode(profile),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 JSON payload: \(jsonString)")
        }

        try await client
            .from("profiles")
            .update(profile)
            .eq("id", value: userId.uuidString)
            .execute()

        print("✅ Profile updated successfully for user \(userId)")
    }

    /// Update current user's last_active timestamp to mark them as online
    func updateLastActive() async {
        guard let userId = currentUserId else { return }

        do {
            let now = ISO8601DateFormatter().string(from: Date())
            try await client
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

    /// Sync profile data from Supabase to UserDefaults
    /// Call this on app startup to ensure local cache is up-to-date
    func syncProfileToUserDefaults() async throws {
        let profile = try await getCurrentProfile()

        await MainActor.run {
            // Basic profile info
            UserDefaults.standard.set(profile.firstName, forKey: "firstName")
            UserDefaults.standard.set(profile.lastName, forKey: "lastName")
            UserDefaults.standard.set(profile.email, forKey: "email")
            UserDefaults.standard.set(profile.bio, forKey: "bio")
            UserDefaults.standard.set(profile.location, forKey: "location")
            UserDefaults.standard.set(profile.birthYear, forKey: "birthYear")
            UserDefaults.standard.set(profile.birthMonth, forKey: "birthMonth")

            // Language data
            UserDefaults.standard.set(profile.nativeLanguage, forKey: "nativeLanguage")
            if let learningLanguages = profile.learningLanguages {
                UserDefaults.standard.set(learningLanguages, forKey: "learningLanguages")
            }

            // Privacy preferences
            UserDefaults.standard.set(profile.strictlyPlatonic ?? false, forKey: "strictlyPlatonic")
            UserDefaults.standard.set(profile.blurPhotosUntilMatch ?? false, forKey: "blurPhotosUntilMatch")
            UserDefaults.standard.set(profile.photoBlurSettings ?? [], forKey: "photoBlurSettings")

            // Matching preferences
            if let minProf = profile.minProficiencyLevel {
                UserDefaults.standard.set(minProf, forKey: "minProficiencyLevel")
            }
            if let maxProf = profile.maxProficiencyLevel {
                UserDefaults.standard.set(maxProf, forKey: "maxProficiencyLevel")
            }
            UserDefaults.standard.set(profile.allowNonNativeMatches ?? false, forKey: "allowNonNativeMatches")

            // Demographics
            if let gender = profile.gender {
                UserDefaults.standard.set(gender, forKey: "gender")
            }
            if let genderPref = profile.genderPreference {
                UserDefaults.standard.set(genderPref, forKey: "genderPreference")
            }
            if let minAge = profile.minAge {
                UserDefaults.standard.set(minAge, forKey: "minAge")
            }
            if let maxAge = profile.maxAge {
                UserDefaults.standard.set(maxAge, forKey: "maxAge")
            }

            // Location preferences
            if let locationPref = profile.locationPreference {
                UserDefaults.standard.set(locationPref, forKey: "locationPreference")
            }
            if let latitude = profile.latitude {
                UserDefaults.standard.set(latitude, forKey: "latitude")
            }
            if let longitude = profile.longitude {
                UserDefaults.standard.set(longitude, forKey: "longitude")
            }

            // User ID
            UserDefaults.standard.set(profile.id, forKey: "userId")

            // Mark that profile has been synced
            UserDefaults.standard.set(true, forKey: "profileSynced")

            print("✅ Synced profile to UserDefaults: \(profile.firstName) (\(profile.email))")
        }
    }

    /// Sync onboarding data from UserDefaults to Supabase
    /// Call this after completing onboarding to save all collected data to the backend
    func syncOnboardingDataToSupabase() async throws {
        guard let userId = currentUserId else {
            print("❌ syncOnboardingDataToSupabase: Not authenticated - no currentUserId")
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        print("📤 Syncing onboarding data to Supabase for user: \(userId)")

        // Basic info - with detailed logging
        let firstName = UserDefaults.standard.string(forKey: "firstName")
        let lastName = UserDefaults.standard.string(forKey: "lastName")
        let bio = UserDefaults.standard.string(forKey: "bio")

        print("📤 UserDefaults values:")
        print("   firstName: '\(firstName ?? "nil")'")
        print("   lastName: '\(lastName ?? "nil")'")
        print("   bio: '\(bio?.prefix(30) ?? "nil")...'")

        // Get language data
        var nativeLanguage: String?
        var learningLanguages: [String]?

        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let userLanguageData = try? JSONDecoder().decode(UserLanguageData.self, from: data) {
            nativeLanguage = userLanguageData.nativeLanguage.language.code
            learningLanguages = userLanguageData.learningLanguages.map { $0.language.code }
            print("   nativeLanguage: '\(nativeLanguage ?? "nil")'")
            print("   learningLanguages: \(learningLanguages ?? [])")
        } else {
            print("   ⚠️ No userLanguages data found in UserDefaults")
        }

        // MINIMAL SYNC: Only send fields that definitely exist in Supabase
        // This avoids "column not found" errors from missing schema columns
        let location = UserDefaults.standard.string(forKey: "location")
        let birthYear = UserDefaults.standard.integer(forKey: "birthYear")

        // Build a minimal dictionary with only essential fields
        var updateData: [String: AnyEncodable] = [:]

        if let firstName = firstName {
            updateData["first_name"] = AnyEncodable(firstName)
        }
        if let lastName = lastName {
            updateData["last_name"] = AnyEncodable(lastName)
        }
        if let bio = bio {
            updateData["bio"] = AnyEncodable(bio)
        }
        if let nativeLanguage = nativeLanguage {
            updateData["native_language"] = AnyEncodable(nativeLanguage)
        }
        if let learningLanguages = learningLanguages {
            updateData["learning_languages"] = AnyEncodable(learningLanguages)
        }
        if let location = location {
            updateData["location"] = AnyEncodable(location)
        }
        if birthYear > 0 {
            updateData["birth_year"] = AnyEncodable(birthYear)
        }
        updateData["onboarding_completed"] = AnyEncodable(true)

        print("📤 Minimal sync - updating \(updateData.count) fields")

        do {
            try await client
                .from("profiles")
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
            print("✅ Onboarding data synced to Supabase for user \(userId)")
        } catch {
            print("❌ Failed to update profile in Supabase: \(error)")
            throw error
        }
    }

    /// Sync ALL onboarding data from UserDefaults to Supabase (extended version)
    /// NOTE: This requires all columns to exist in the database.
    /// If you get "column not found" errors, add the missing columns or use syncOnboardingDataToSupabase() instead.
    func syncAllOnboardingDataToSupabase() async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        print("📤 Full sync of onboarding data to Supabase for user: \(userId)")

        var profileUpdate = ProfileUpdate()

        // Basic info
        profileUpdate.firstName = UserDefaults.standard.string(forKey: "firstName")
        profileUpdate.lastName = UserDefaults.standard.string(forKey: "lastName")
        profileUpdate.bio = UserDefaults.standard.string(forKey: "bio")

        let birthYear = UserDefaults.standard.integer(forKey: "birthYear")
        if birthYear > 0 {
            profileUpdate.birthYear = birthYear
        }

        // Location
        profileUpdate.location = UserDefaults.standard.string(forKey: "location")
        profileUpdate.city = UserDefaults.standard.string(forKey: "city")
        profileUpdate.country = UserDefaults.standard.string(forKey: "country")
        if UserDefaults.standard.object(forKey: "latitude") != nil {
            profileUpdate.latitude = UserDefaults.standard.double(forKey: "latitude")
        }
        if UserDefaults.standard.object(forKey: "longitude") != nil {
            profileUpdate.longitude = UserDefaults.standard.double(forKey: "longitude")
        }

        // Language data
        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let userLanguageData = try? JSONDecoder().decode(UserLanguageData.self, from: data) {
            profileUpdate.nativeLanguage = userLanguageData.nativeLanguage.language.code
            profileUpdate.learningLanguages = userLanguageData.learningLanguages.map { $0.language.code }
            var proficiencyLevels: [String: String] = [:]
            for userLang in userLanguageData.learningLanguages {
                proficiencyLevels[userLang.language.code] = userLang.proficiency.rawValue
            }
            profileUpdate.proficiencyLevels = proficiencyLevels
        }

        // Matching preferences
        if let gender = UserDefaults.standard.string(forKey: "gender") {
            profileUpdate.gender = gender
        }
        if let genderPref = UserDefaults.standard.string(forKey: "genderPreference") {
            profileUpdate.genderPreference = genderPref
        }
        let minAge = UserDefaults.standard.integer(forKey: "minAge")
        let maxAge = UserDefaults.standard.integer(forKey: "maxAge")
        if minAge > 0 { profileUpdate.minAge = minAge }
        if maxAge > 0 { profileUpdate.maxAge = maxAge }

        if let minProf = UserDefaults.standard.string(forKey: "minProficiencyLevel") {
            profileUpdate.minProficiencyLevel = minProf
        }
        if let maxProf = UserDefaults.standard.string(forKey: "maxProficiencyLevel") {
            profileUpdate.maxProficiencyLevel = maxProf
        }

        // Location preference
        if let locationPref = UserDefaults.standard.string(forKey: "locationPreference") {
            profileUpdate.locationPreference = locationPref
        }
        if let preferredCountries = UserDefaults.standard.stringArray(forKey: "preferredCountries") {
            profileUpdate.preferredCountries = preferredCountries
        }
        if let excludedCountries = UserDefaults.standard.stringArray(forKey: "excludedCountries") {
            profileUpdate.excludedCountries = excludedCountries
        }

        // Travel destination
        if let travelData = UserDefaults.standard.data(forKey: "travelDestination"),
           let travelDestination = try? JSONDecoder().decode(TravelDestination.self, from: travelData) {
            profileUpdate.travelDestination = TravelDestinationDB(
                city: travelDestination.city,
                country: travelDestination.country,
                countryName: travelDestination.countryName,
                startDate: travelDestination.startDate.map { ISO8601DateFormatter().string(from: $0) },
                endDate: travelDestination.endDate.map { ISO8601DateFormatter().string(from: $0) }
            )
        }

        // Privacy preferences
        profileUpdate.strictlyPlatonic = UserDefaults.standard.bool(forKey: "strictlyPlatonic")
        profileUpdate.blurPhotosUntilMatch = UserDefaults.standard.bool(forKey: "blurPhotosUntilMatch")

        // Relationship intent
        if let intentString = UserDefaults.standard.string(forKey: "relationshipIntent") {
            profileUpdate.relationshipIntents = [intentString]
        }

        // Learning contexts
        if let learningContexts = UserDefaults.standard.stringArray(forKey: "learningContexts") {
            profileUpdate.learningContexts = learningContexts
        }

        // Muse languages
        if let museLanguages = UserDefaults.standard.stringArray(forKey: "museLanguages") {
            profileUpdate.museLanguages = museLanguages
        }

        profileUpdate.onboardingCompleted = true

        try await updateProfile(profileUpdate)
        print("✅ Full onboarding data synced to Supabase for user \(userId)")
    }

    /// Upload onboarding photos to Supabase storage and update profile
    /// Call this after completing onboarding if photos were selected
    func uploadOnboardingPhotos(_ photos: [UIImage]) async throws {
        guard let userId = currentUserId?.uuidString else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        guard !photos.isEmpty else {
            print("ℹ️ No photos to upload")
            return
        }

        print("📤 Uploading \(photos.count) onboarding photos...")

        var uploadedPaths: [String] = Array(repeating: "", count: 7) // 6 grid + 1 profile photo

        for (index, image) in photos.enumerated() {
            // Resize image to max 1200px
            let resizedImage = resizeImage(image, maxDimension: 1200)

            guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
                print("⚠️ Could not compress image at index \(index)")
                continue
            }

            do {
                let storagePath = try await uploadPhoto(imageData, userId: userId, photoIndex: index)
                uploadedPaths[index] = storagePath
                print("✅ Uploaded photo \(index + 1)/\(photos.count)")
            } catch {
                print("❌ Failed to upload photo \(index): \(error)")
            }
        }

        // Also set the first photo as the profile photo (index 6)
        if !uploadedPaths[0].isEmpty {
            uploadedPaths[6] = uploadedPaths[0]
        }

        // Update profile with photo paths
        try await updateUserPhotos(photoURLs: uploadedPaths)

        print("✅ All onboarding photos uploaded and profile updated")
    }

    /// Resize image to fit within maxDimension while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // If image is already small enough, return it
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // Use UIGraphicsImageRenderer for efficient memory handling
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage
    }

    /// Update current user's bio
    func updateUserBio(bio: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        try await client
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

        try await client
            .from("profiles")
            .insert(profile)
            .execute()

        print("✅ Profile created")
    }

    /// Get a specific profile by user ID
    func getProfile(userId: String) async throws -> ProfileResponse {
        let response: ProfileResponse = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return response
    }

    /// Get profiles for discovery (with filters)
    func getDiscoveryProfiles(limit: Int = 20) async throws -> [ProfileResponse] {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Get profiles excluding current user and already swiped
        let response: [ProfileResponse] = try await client
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

        try await client
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
        let response: [SwipeResponse] = try await client
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

        try await client
            .from("matches")
            .insert(match)
            .execute()

        print("✅ Match created with: \(otherUserId)")

        // Track first match for welcome screen logic
        UserEngagementTracker.shared.markFirstMatch()

        // Note: Push notifications are handled server-side via database trigger
        // See: supabase/migrations/add_push_notification_triggers.sql
    }

    /// Get all matches for current user
    func getMatches() async throws -> [MatchResponse] {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let response: [MatchResponse] = try await client
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
        try await client
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

        let response: [SwipeResponse] = try await client
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

        let response: [MatchUserIds] = try await client
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

// MARK: - Feedback Methods
extension SupabaseService {

    /// Submit user feedback (feature request, bug report, etc.)
    func submitFeedback(type: String, message: String) async throws {
        let userId = currentUserId?.uuidString

        // Get app version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let appVersion = "\(version) (\(build))"

        // Get device info
        let device = UIDevice.current
        let deviceInfo = "\(device.model) - iOS \(device.systemVersion)"

        struct FeedbackInsert: Encodable {
            let user_id: String?
            let type: String
            let message: String
            let app_version: String
            let device_info: String
            let status: String
        }

        let feedback = FeedbackInsert(
            user_id: userId,
            type: type,
            message: message,
            app_version: appVersion,
            device_info: deviceInfo,
            status: "pending"
        )

        try await client
            .from("feedback")
            .insert(feedback)
            .execute()

        print("✅ Feedback submitted: \(type)")
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
        let matches: [MatchWithConversation] = try await client
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
            let conversations: [ConversationResponse] = try await client
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

        let response: ConversationResponse = try await client
            .from("conversations")
            .insert(newConversation)
            .select()
            .single()
            .execute()
            .value

        // Update the match with the conversation ID
        try await client
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
        let matches: [MatchWithConversation] = try await client
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
            let conversations: [ConversationResponse] = try await client
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

        let response: ConversationResponse = try await client
            .from("conversations")
            .insert(newConversation)
            .select()
            .single()
            .execute()
            .value

        // Update the match with the conversation ID
        try await client
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

        try await client
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

        try await client
            .from("messages")
            .insert(message)
            .execute()

        print("✅ Message sent as \(senderId)")
    }

    /// Get messages for a conversation
    func getMessages(conversationId: String, limit: Int = 50) async throws -> [MessageResponse] {
        let response: [MessageResponse] = try await client
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
    let birthMonth: Int?
    let nativeLanguage: String
    let learningLanguages: [String]?
    let profilePhotos: [String]? // Storage paths, not URLs
    let photoCaptions: [String?]? // Captions for each photo
    let photoBlurSettings: [Bool]? // Per-photo blur until match settings
    let isPremium: Bool
    let granularityLevel: Int
    let onboardingCompleted: Bool
    let location: String?
    let city: String?
    let country: String?
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

    // Platonic and blur preferences
    let strictlyPlatonic: Bool?
    let blurPhotosUntilMatch: Bool?

    enum CodingKeys: String, CodingKey {
        case id, email, bio, location, city, country, latitude, longitude
        case firstName = "first_name"
        case lastName = "last_name"
        case birthYear = "birth_year"
        case birthMonth = "birth_month"
        case nativeLanguage = "native_language"
        case learningLanguages = "learning_languages"
        case profilePhotos = "profile_photos"
        case photoCaptions = "photo_captions"
        case photoBlurSettings = "photo_blur_settings"
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
        case strictlyPlatonic = "strictly_platonic"
        case blurPhotosUntilMatch = "blur_photos_until_match"
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
            strictlyPlatonic: strictlyPlatonic ?? false,
            blurPhotosUntilMatch: blurPhotosUntilMatch ?? false,
            photoBlurSettings: photoBlurSettings ?? [],
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

        // Parse relationship intent (single selection, take first from array)
        let userRelationshipIntents = (relationshipIntents ?? []).compactMap { intentString in
            RelationshipIntent.allCases.first(where: { $0.rawValue == intentString })
        }
        let finalIntent = userRelationshipIntents.first ?? .languagePracticeOnly

        // Parse learning contexts (empty array = open to all styles)
        let userLearningContexts = (learningContexts ?? []).compactMap { contextString in
            LearningContext.allCases.first(where: { $0.rawValue == contextString })
        }
        let finalContexts = userLearningContexts

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
            relationshipIntent: finalIntent,
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
    var birthYear: Int?
    var birthMonth: Int?
    var location: String?
    var city: String?
    var country: String?
    var latitude: Double?
    var longitude: Double?
    var showCityInProfile: Bool?
    var nativeLanguage: String?
    var learningLanguages: [String]?
    var proficiencyLevels: [String: String]?
    var gender: String?
    var genderPreference: String?
    var minAge: Int?
    var maxAge: Int?
    var granularityLevel: Int?
    var strictlyPlatonic: Bool?
    var blurPhotosUntilMatch: Bool?
    var minProficiencyLevel: String?
    var maxProficiencyLevel: String?
    var openToLanguages: [String]?
    var profilePhotos: [String]?
    var relationshipIntents: [String]?
    var onboardingCompleted: Bool?
    var locationPreference: String?
    var preferredCountries: [String]?
    var excludedCountries: [String]?
    var travelDestination: TravelDestinationDB?
    var learningContexts: [String]?
    var museLanguages: [String]?

    enum CodingKeys: String, CodingKey {
        case bio, location, city, country, latitude, longitude, gender
        case firstName = "first_name"
        case lastName = "last_name"
        case birthYear = "birth_year"
        case birthMonth = "birth_month"
        case showCityInProfile = "show_city_in_profile"
        case nativeLanguage = "native_language"
        case learningLanguages = "learning_languages"
        case proficiencyLevels = "proficiency_levels"
        case genderPreference = "gender_preference"
        case minAge = "min_age"
        case maxAge = "max_age"
        case granularityLevel = "granularity_level"
        case strictlyPlatonic = "strictly_platonic"
        case blurPhotosUntilMatch = "blur_photos_until_match"
        case minProficiencyLevel = "min_proficiency_level"
        case maxProficiencyLevel = "max_proficiency_level"
        case openToLanguages = "open_to_languages"
        case profilePhotos = "profile_photos"
        case relationshipIntents = "relationship_intents"
        case onboardingCompleted = "onboarding_completed"
        case locationPreference = "location_preference"
        case preferredCountries = "preferred_countries"
        case excludedCountries = "excluded_countries"
        case travelDestination = "travel_destination"
        case learningContexts = "learning_contexts"
        case museLanguages = "muse_languages"
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
    let user1: ProfileResponse?
    let user2: ProfileResponse?

    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case isMutual = "is_mutual"
        case matchedAt = "matched_at"
        case user1
        case user2
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
        let response: [ModelEvaluationResponse] = try await client
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

        try await client
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

        let reports: [ReportResponse] = try await client
            .from("reported_users")
            .select()
            .eq("reporter_id", value: currentUserId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return reports
    }

    /// Report a user's profile (not just a photo)
    func reportUser(
        reportedUserId: String,
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
            photoUrl: nil  // No photo URL for profile reports
        )

        try await client
            .from("reported_users")
            .insert(report)
            .execute()

        print("✅ User profile reported successfully")
    }

    /// Block a user - adds them to the blocked_users list and removes from matches
    func blockUser(userId: String) async throws {
        guard let currentUserId = currentUserId?.uuidString else {
            throw NSError(domain: "SupabaseService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Call the database function to handle blocking
        // This adds to blocked_users array and removes any existing matches
        try await client
            .rpc("block_user", params: ["blocker_id": currentUserId, "blocked_id": userId])
            .execute()

        print("✅ User blocked successfully: \(userId)")
    }

    /// Unblock a user - removes them from the blocked_users list
    func unblockUser(userId: String) async throws {
        guard let currentUserId = currentUserId?.uuidString else {
            throw NSError(domain: "SupabaseService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Call the database function to handle unblocking
        try await client
            .rpc("unblock_user", params: ["unblocker_id": currentUserId, "unblocked_id": userId])
            .execute()

        print("✅ User unblocked successfully: \(userId)")
    }

    /// Get list of blocked user IDs
    func getBlockedUsers() async throws -> [String] {
        guard let currentUserId = currentUserId?.uuidString else {
            return []
        }

        struct BlockedUsersResponse: Codable {
            let blockedUsers: [String]?

            enum CodingKeys: String, CodingKey {
                case blockedUsers = "blocked_users"
            }
        }

        let response: [BlockedUsersResponse] = try await client
            .from("user_preferences")
            .select("blocked_users")
            .eq("user_id", value: currentUserId)
            .execute()
            .value

        return response.first?.blockedUsers ?? []
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

// MARK: - TTS Methods
extension SupabaseService {

    /// Get TTS usage info for current user
    func getTTSUsageInfo() async throws -> TTSUsageInfo {
        guard let userId = currentUserId else {
            // Return default free tier info if not logged in
            return TTSUsageInfo(
                playsUsed: 0,
                playsLimit: 10,
                billingCycleStart: nil,
                voiceQuality: .appleNative
            )
        }

        struct TTSUsageResponse: Codable {
            let ttsPlaysUsedThisMonth: Int?
            let ttsBillingCycleStart: String?
            let subscriptionTier: String?

            enum CodingKeys: String, CodingKey {
                case ttsPlaysUsedThisMonth = "tts_plays_used_this_month"
                case ttsBillingCycleStart = "tts_billing_cycle_start"
                case subscriptionTier = "subscription_tier"
            }
        }

        let response: [TTSUsageResponse] = try await client
            .from("profiles")
            .select("tts_plays_used_this_month, tts_billing_cycle_start, subscription_tier")
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        guard let usage = response.first else {
            return TTSUsageInfo(
                playsUsed: 0,
                playsLimit: 10,
                billingCycleStart: nil,
                voiceQuality: .appleNative
            )
        }

        let tier = SubscriptionTier(rawValue: usage.subscriptionTier ?? "free") ?? .free

        // Parse billing cycle start date
        var billingStart: Date? = nil
        if let dateString = usage.ttsBillingCycleStart {
            let formatter = ISO8601DateFormatter()
            billingStart = formatter.date(from: dateString)
        }

        return TTSUsageInfo(
            playsUsed: usage.ttsPlaysUsedThisMonth ?? 0,
            playsLimit: tier.monthlyTTSLimit,
            billingCycleStart: billingStart,
            voiceQuality: tier.ttsVoiceQuality
        )
    }

    /// Get current user's subscription tier
    func getCurrentSubscriptionTier() async throws -> SubscriptionTier {
        guard let userId = currentUserId else {
            print("⚠️ getCurrentSubscriptionTier: No userId, returning .free")
            return .free
        }

        struct TierResponse: Codable {
            let subscriptionTier: String?

            enum CodingKeys: String, CodingKey {
                case subscriptionTier = "subscription_tier"
            }
        }

        let response: [TierResponse] = try await client
            .from("profiles")
            .select("subscription_tier")
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        guard let result = response.first,
              let tierString = result.subscriptionTier else {
            print("⚠️ getCurrentSubscriptionTier: No tier found for \(userId), returning .free")
            return .free
        }

        let tier = SubscriptionTier(rawValue: tierString) ?? .free
        print("✅ getCurrentSubscriptionTier: User \(userId) has tier '\(tierString)' -> \(tier)")
        return tier
    }

    /// Increment TTS usage count for current user
    func incrementTTSUsage() async throws {
        guard let userId = currentUserId else { return }

        // First check if we need to reset the counter (new billing cycle)
        try await checkAndResetTTSCycle()

        // Fetch current value and increment manually
        struct CurrentUsage: Codable {
            let ttsPlaysUsedThisMonth: Int?

            enum CodingKeys: String, CodingKey {
                case ttsPlaysUsedThisMonth = "tts_plays_used_this_month"
            }
        }

        let current: [CurrentUsage] = try await client
            .from("profiles")
            .select("tts_plays_used_this_month")
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        let currentCount = current.first?.ttsPlaysUsedThisMonth ?? 0

        struct TTSUpdate: Encodable {
            let tts_plays_used_this_month: Int
        }

        try await client
            .from("profiles")
            .update(TTSUpdate(tts_plays_used_this_month: currentCount + 1))
            .eq("id", value: userId.uuidString)
            .execute()

        print("✅ TTS usage incremented")
    }

    /// Check if billing cycle has reset and reset counter if needed
    private func checkAndResetTTSCycle() async throws {
        guard let userId = currentUserId else { return }

        struct BillingInfo: Codable {
            let ttsBillingCycleStart: String?

            enum CodingKeys: String, CodingKey {
                case ttsBillingCycleStart = "tts_billing_cycle_start"
            }
        }

        let response: [BillingInfo] = try await client
            .from("profiles")
            .select("tts_billing_cycle_start")
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        let formatter = ISO8601DateFormatter()
        let now = Date()
        let calendar = Calendar.current

        if let billingStartStr = response.first?.ttsBillingCycleStart,
           let billingStart = formatter.date(from: billingStartStr) {
            // Check if we're in a new month
            let billingMonth = calendar.component(.month, from: billingStart)
            let billingYear = calendar.component(.year, from: billingStart)
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)

            if currentYear > billingYear || (currentYear == billingYear && currentMonth > billingMonth) {
                // New billing cycle - reset counter
                try await resetTTSUsage()
            }
        } else {
            // No billing cycle set - initialize it
            try await resetTTSUsage()
        }
    }

    /// Reset TTS usage for new billing cycle
    private func resetTTSUsage() async throws {
        guard let userId = currentUserId else { return }

        struct TTSReset: Encodable {
            let tts_plays_used_this_month: Int
            let tts_billing_cycle_start: String
        }

        let formatter = ISO8601DateFormatter()

        try await client
            .from("profiles")
            .update(TTSReset(
                tts_plays_used_this_month: 0,
                tts_billing_cycle_start: formatter.string(from: Date())
            ))
            .eq("id", value: userId.uuidString)
            .execute()

        print("✅ TTS usage reset for new billing cycle")
    }
}

// MARK: - Pricing Config Methods
extension SupabaseService {

    /// Fetch pricing configuration from Supabase
    func fetchPricingConfig() async throws -> PricingConfig {
        let response: [PricingConfig] = try await client
            .from("pricing_config")
            .select("*")
            .eq("id", value: "00000000-0000-0000-0000-000000000001")
            .execute()
            .value

        guard let config = response.first else {
            print("⚠️ No pricing config found, using defaults")
            return PricingConfig.defaultConfig
        }

        print("✅ Loaded pricing config from Supabase")
        return config
    }
}

// MARK: - TTS Voice Config Methods
extension SupabaseService {

    /// TTS voice configuration from Supabase
    struct TTSVoiceConfig: Codable {
        let languageCode: String
        let languageName: String
        let googleLanguageCode: String
        let googleVoiceName: String
        let voiceGender: String
        let speakingRate: Double
        let pitch: Double
        let enabled: Bool
        let maleVoiceName: String?
        let femaleVoiceName: String?
        // Muse configuration
        let maleMuseName: String?
        let femaleMuseName: String?
        let isMuseLanguage: Bool?

        /// Whether this is a Muse language (defaults to false if nil)
        var isMuseLanguageEnabled: Bool {
            return isMuseLanguage ?? false
        }

        enum CodingKeys: String, CodingKey {
            case languageCode = "language_code"
            case languageName = "language_name"
            case googleLanguageCode = "google_language_code"
            case googleVoiceName = "google_voice_name"
            case voiceGender = "voice_gender"
            case speakingRate = "speaking_rate"
            case pitch = "pitch"
            case enabled = "enabled"
            case maleVoiceName = "male_voice_name"
            case femaleVoiceName = "female_voice_name"
            case maleMuseName = "male_muse_name"
            case femaleMuseName = "female_muse_name"
            case isMuseLanguage = "is_muse_language"
        }

        /// Get the appropriate voice name based on speaker gender
        func voiceName(forGender gender: String?) -> String {
            switch gender?.lowercased() {
            case "male", "m":
                return maleVoiceName ?? googleVoiceName
            case "female", "f":
                return femaleVoiceName ?? googleVoiceName
            default:
                return googleVoiceName
            }
        }

        /// Get the Muse name based on gender preference
        func museName(forGender gender: MuseGenderPreference) -> String? {
            switch gender {
            case .male:
                return maleMuseName
            case .female:
                return femaleMuseName
            }
        }
    }

    /// Fetch all TTS voice configurations
    func fetchTTSVoiceConfigs() async throws -> [TTSVoiceConfig] {
        let response: [TTSVoiceConfig] = try await client
            .from("tts_voices")
            .select("*")
            .eq("enabled", value: true)
            .execute()
            .value

        print("✅ Loaded \(response.count) TTS voice configs from Supabase")
        return response
    }

    /// Fetch TTS voice config for a specific language
    func fetchTTSVoiceConfig(forLanguage language: String) async throws -> TTSVoiceConfig? {
        let languageLower = language.lowercased()

        // Try exact match first
        let exactMatch: [TTSVoiceConfig] = try await client
            .from("tts_voices")
            .select("*")
            .eq("language_code", value: languageLower)
            .eq("enabled", value: true)
            .execute()
            .value

        if let config = exactMatch.first {
            return config
        }

        // Try matching by language name
        let nameMatch: [TTSVoiceConfig] = try await client
            .from("tts_voices")
            .select("*")
            .ilike("language_name", value: "%\(languageLower)%")
            .eq("enabled", value: true)
            .execute()
            .value

        return nameMatch.first
    }

    /// Alias for fetchTTSVoiceConfigs - used by AIBotFactory for Muse configuration
    func getTTSVoices() async throws -> [TTSVoiceConfig] {
        // Include all voices (not just enabled) so we can get Muse configurations
        let response: [TTSVoiceConfig] = try await client
            .from("tts_voices")
            .select("*")
            .execute()
            .value

        print("✅ Loaded \(response.count) TTS voices for Muse configuration")
        return response
    }
}

// MARK: - Muse Interaction Tracking
extension SupabaseService {

    /// Track a Muse interaction (message sent to AI bot)
    func trackMuseInteraction(museId: String, museName: String, language: String, interactionType: String = "message") async {
        guard let userId = currentUserId else {
            print("⚠️ Cannot track Muse interaction: No user logged in")
            return
        }

        struct MuseInteraction: Encodable {
            let user_id: String
            let muse_id: String
            let muse_name: String
            let language: String
            let interaction_type: String
        }

        let interaction = MuseInteraction(
            user_id: userId.uuidString,
            muse_id: museId,
            muse_name: museName,
            language: language,
            interaction_type: interactionType
        )

        do {
            try await client
                .from("muse_interactions")
                .insert(interaction)
                .execute()

            print("✅ Tracked Muse interaction: \(museName) (\(language)) - \(interactionType)")
        } catch {
            // Don't fail silently but don't crash either - tracking is non-critical
            print("⚠️ Failed to track Muse interaction: \(error.localizedDescription)")
        }
    }
}

// MARK: - Invite Methods

extension SupabaseService {

    /// Result of accepting an invite
    struct InviteResult {
        let success: Bool
        let matchId: String?
        let inviterName: String?
        let inviterId: String?
        let error: String?
    }

    /// Generate an invite code for the current user
    func generateInviteCode() async throws -> String {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Call the database function to generate invite code
        // The function returns a plain TEXT value
        let response: PostgrestResponse<String> = try await client.rpc(
            "create_invite",
            params: ["p_inviter_id": userId.uuidString]
        ).single().execute()

        let code = response.value

        guard !code.isEmpty else {
            throw NSError(domain: "SupabaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to generate invite code"])
        }

        print("✅ Generated invite code: \(code)")
        return code
    }

    /// Get all invites created by the current user
    func getMyInvites() async throws -> [Invite] {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let response: [Invite] = try await client
            .from("invites")
            .select()
            .eq("inviter_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Validate an invite code (check if it exists and is valid)
    func validateInviteCode(_ code: String) async throws -> InviteValidation? {
        let response: [InviteValidation] = try await client
            .from("invites")
            .select("id, code, status, expires_at, inviter_id, profiles!invites_inviter_id_fkey(name)")
            .eq("code", value: code)
            .eq("status", value: "pending")
            .execute()
            .value

        guard let invite = response.first else {
            return nil
        }

        // Check if expired
        if let expiresAt = invite.expiresAt, expiresAt < Date() {
            return nil
        }

        return invite
    }

    /// Accept an invite code and create auto-match
    func acceptInvite(code: String) async throws -> InviteResult {
        guard let userId = currentUserId else {
            return InviteResult(success: false, matchId: nil, inviterName: nil, inviterId: nil, error: "Not authenticated")
        }

        // Call the database function to accept invite
        struct AcceptInviteResponse: Decodable {
            let success: Bool
            let match_id: String?
            let inviter_name: String?
            let inviter_id: String?
            let error: String?
        }

        let response: PostgrestResponse<AcceptInviteResponse> = try await client.rpc(
            "accept_invite",
            params: ["p_code": code, "p_new_user_id": userId.uuidString]
        ).single().execute()

        let result = response.value
        return InviteResult(
            success: result.success,
            matchId: result.match_id,
            inviterName: result.inviter_name,
            inviterId: result.inviter_id,
            error: result.error
        )
    }

    /// Build a shareable invite link URL
    func buildInviteLink(code: String) -> URL? {
        // Format: fluenca://invite/FLU-ABC123
        return URL(string: "fluenca://invite/\(code)")
    }

    /// Build a shareable invite link with fallback web URL
    func buildShareableInviteText(code: String, inviterName: String) -> String {
        let appLink = "fluenca://invite/\(code)"
        let webLink = "https://ByZyB.ai/invite/\(code)"

        return """
        \(inviterName) has invited you to connect on Fluenca!

        Open this link to connect: \(appLink)

        Or visit: \(webLink)

        Invite code: \(code)
        """
    }
}

// MARK: - Invite Data Models

struct Invite: Codable {
    let id: String
    let inviterId: String
    let code: String
    let status: String
    let invitedUserId: String?
    let matchId: String?
    let createdAt: Date?
    let expiresAt: Date?
    let acceptedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case inviterId = "inviter_id"
        case code
        case status
        case invitedUserId = "invited_user_id"
        case matchId = "match_id"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case acceptedAt = "accepted_at"
    }
}

struct InviteValidation: Codable {
    let id: String
    let code: String
    let status: String
    let expiresAt: Date?
    let inviterId: String
    let profiles: InviterProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case status
        case expiresAt = "expires_at"
        case inviterId = "inviter_id"
        case profiles
    }

    struct InviterProfile: Codable {
        let name: String?
    }

    var inviterName: String? {
        return profiles?.name
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
