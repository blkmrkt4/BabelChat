#if DEBUG
import Foundation
import Supabase

/// Generates 40 diverse test profiles for matching algorithm testing
/// Usage: await TestDataGenerator.shared.insertTestProfiles()
class TestDataGenerator {

    static let shared = TestDataGenerator()
    private init() {}

    /// Insert all 40 test profiles to Supabase
    /// Returns a result message with success/failure details
    func insertTestProfiles() async throws -> String {
        print("🚀 Starting test profile generation...")

        let profiles = createAllTestProfiles()
        var successCount = 0
        var failureCount = 0
        var errorMessages: [String] = []

        for (index, profile) in profiles.enumerated() {
            do {
                try await insertProfile(profile)
                successCount += 1
                print("✅ [\(index + 1)/\(profiles.count)] Inserted: \(profile.firstName) from \(profile.location ?? "Unknown")")
            } catch {
                failureCount += 1
                let errorMsg = "\(profile.firstName): \(error.localizedDescription)"
                errorMessages.append(errorMsg)
                print("❌ [\(index + 1)/\(profiles.count)] Failed to insert \(errorMsg)")
            }

            // Small delay to avoid rate limiting
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        let summary = """
        📊 Insertion Results:
        ✅ Success: \(successCount)
        ❌ Failed: \(failureCount)
        📈 Total: \(profiles.count)

        \(failureCount > 0 ? "Errors:\n" + errorMessages.prefix(5).joined(separator: "\n") : "All profiles inserted successfully!")
        \(failureCount > 5 ? "\n... and \(failureCount - 5) more errors" : "")
        """

        print("\n" + summary)
        return summary
    }

    /// Insert a single profile to Supabase
    private func insertProfile(_ profile: TestProfile) async throws {
        let supabase = SupabaseService.shared.client

        // Don't include id - let database generate it to avoid foreign key constraint
        let profileData = ProfileInsertWithoutId(
            email: profile.email,
            phoneNumber: profile.phoneNumber,
            firstName: profile.firstName,
            lastName: profile.lastName,
            bio: profile.bio,
            birthYear: profile.birthYear,
            age: profile.age,
            location: profile.location,
            nativeLanguage: profile.nativeLanguage,
            learningLanguages: profile.learningLanguages,
            profilePhotos: profile.profilePhotos,
            onboardingCompleted: true,
            gender: profile.gender,
            genderPreference: profile.genderPreference,
            minAge: profile.minAge,
            maxAge: profile.maxAge,
            locationPreference: profile.locationPreference,
            latitude: profile.latitude,
            longitude: profile.longitude,
            relationshipIntents: profile.relationshipIntents,
            learningContexts: profile.learningContexts,
            allowNonNativeMatches: profile.allowNonNativeMatches,
            minProficiencyLevel: profile.minProficiencyLevel,
            maxProficiencyLevel: profile.maxProficiencyLevel,
            lastActive: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase.from("profiles").insert(profileData).execute()
    }

    /// Create all 40 test profiles
    private func createAllTestProfiles() -> [TestProfile] {
        // Returns all 40 profiles in one array
        return [
            // 10 English speakers
            TestProfile(id: "10000000-0000-0000-0000-000000000001", email: "sarah.johnson@test.com", phoneNumber: "+15551001", firstName: "Sarah", lastName: "Johnson", bio: "Love traveling and learning languages! Currently planning a trip to Barcelona 🇪🇸", birthYear: 1995, age: 30, location: "San Francisco, USA", nativeLanguage: "English", learningLanguages: ["Spanish", "French"], profilePhotos: ["https://picsum.photos/seed/sarah/400"], gender: "female", genderPreference: "all", minAge: 25, maxAge: 40, locationPreference: "anywhere", latitude: 37.7749, longitude: -122.4194, relationshipIntents: ["friendship", "language_practice_only"], learningContexts: ["travel", "cultural"]),

            TestProfile(id: "10000000-0000-0000-0000-000000000002", email: "mike.chen@test.com", phoneNumber: "+15551002", firstName: "Mike", lastName: "Chen", bio: "Software engineer who wants to learn Japanese. Anime fan!", birthYear: 1992, age: 33, location: "Seattle, USA", nativeLanguage: "English", learningLanguages: ["Japanese", "Mandarin"], profilePhotos: ["https://picsum.photos/seed/mike/400"], gender: "male", genderPreference: "all", minAge: 28, maxAge: 38, locationPreference: "anywhere", latitude: 47.6062, longitude: -122.3321, relationshipIntents: ["language_practice_only"], learningContexts: ["fun", "cultural"], allowNonNativeMatches: true),

            TestProfile(id: "10000000-0000-0000-0000-000000000003", email: "emma.davis@test.com", phoneNumber: "+15551003", firstName: "Emma", lastName: "Davis", bio: "Teacher passionate about languages. Learning Spanish for work!", birthYear: 1990, age: 35, location: "Austin, Texas", nativeLanguage: "English", learningLanguages: ["Spanish", "Portuguese"], profilePhotos: ["https://picsum.photos/seed/emma/400"], gender: "female", genderPreference: "all", minAge: 30, maxAge: 45, locationPreference: "regional_100km", latitude: 30.2672, longitude: -97.7431, relationshipIntents: ["friendship", "language_practice_only"], learningContexts: ["work", "cultural"]),

            TestProfile(id: "10000000-0000-0000-0000-000000000004", email: "james.wilson@test.com", phoneNumber: "+15551004", firstName: "James", lastName: "Wilson", bio: "NYC finance guy learning Mandarin for business. Let's practice!", birthYear: 1988, age: 37, location: "New York, USA", nativeLanguage: "English", learningLanguages: ["Mandarin"], profilePhotos: ["https://picsum.photos/seed/james/400"], gender: "male", genderPreference: "female", minAge: 32, maxAge: 42, locationPreference: "local_25km", latitude: 40.7128, longitude: -74.0060, relationshipIntents: ["open_to_dating", "friendship"], learningContexts: ["work", "travel"]),

            TestProfile(id: "10000000-0000-0000-0000-000000000005", email: "sophia.martinez@test.com", phoneNumber: "+15551005", firstName: "Sophia", lastName: "Martinez", bio: "Bilingual Spanish-English speaker. Happy to help English learners!", birthYear: 1997, age: 28, location: "Miami, Florida", nativeLanguage: "English", learningLanguages: ["Portuguese", "Italian"], profilePhotos: ["https://picsum.photos/seed/sophia/400"], gender: "female", genderPreference: "male", minAge: 24, maxAge: 35, locationPreference: "anywhere", latitude: 25.7617, longitude: -80.1918, relationshipIntents: ["open_to_dating", "friendship"], learningContexts: ["travel", "fun"], allowNonNativeMatches: true),

            TestProfile(id: "10000000-0000-0000-0000-000000000006", email: "david.kim@test.com", phoneNumber: "+15551006", firstName: "David", lastName: "Kim", bio: "Korean-American learning French. Love cooking and music!", birthYear: 1994, age: 31, location: "Los Angeles, USA", nativeLanguage: "English", learningLanguages: ["French", "Korean"], profilePhotos: ["https://picsum.photos/seed/david/400"], gender: "male", genderPreference: "all", minAge: 26, maxAge: 38, locationPreference: "regional_100km", latitude: 34.0522, longitude: -118.2437, relationshipIntents: ["friendship", "language_practice_only"], learningContexts: ["cultural", "fun"]),

            TestProfile(id: "10000000-0000-0000-0000-000000000007", email: "olivia.brown@test.com", phoneNumber: "+15551007", firstName: "Olivia", lastName: "Brown", bio: "Digital nomad currently in Bali. Learning Indonesian!", birthYear: 1993, age: 32, location: "Denver, Colorado", nativeLanguage: "English", learningLanguages: ["Indonesian", "Spanish"], profilePhotos: ["https://picsum.photos/seed/olivia/400"], gender: "female", genderPreference: "all", minAge: 28, maxAge: 40, locationPreference: "anywhere", latitude: 39.7392, longitude: -104.9903, relationshipIntents: ["friendship"], learningContexts: ["travel", "fun"], allowNonNativeMatches: true),

            TestProfile(id: "10000000-0000-0000-0000-000000000008", email: "alex.taylor@test.com", phoneNumber: "+15551008", firstName: "Alex", lastName: "Taylor", bio: "Non-binary language enthusiast. Learning multiple languages!", birthYear: 1996, age: 29, location: "Portland, Oregon", nativeLanguage: "English", learningLanguages: ["German", "Dutch"], profilePhotos: ["https://picsum.photos/seed/alex/400"], gender: "non_binary", genderPreference: "all", minAge: 25, maxAge: 35, locationPreference: "local_25km", latitude: 45.5152, longitude: -122.6784, relationshipIntents: ["friendship"], learningContexts: ["cultural", "academic"]),

            TestProfile(id: "10000000-0000-0000-0000-000000000009", email: "ryan.anderson@test.com", phoneNumber: "+15551009", firstName: "Ryan", lastName: "Anderson", bio: "Grad student studying abroad in Japan next year!", birthYear: 1998, age: 27, location: "Boston, Massachusetts", nativeLanguage: "English", learningLanguages: ["Japanese"], profilePhotos: ["https://picsum.photos/seed/ryan/400"], gender: "male", genderPreference: "all", minAge: 23, maxAge: 32, locationPreference: "anywhere", latitude: 42.3601, longitude: -71.0589, relationshipIntents: ["language_practice_only"], learningContexts: ["academic", "travel"]),

            TestProfile(id: "10000000-0000-0000-0000-000000000010", email: "mia.white@test.com", phoneNumber: "+15551010", firstName: "Mia", lastName: "White", bio: "Yoga instructor learning Hindi and Sanskrit. Spiritual journey!", birthYear: 1991, age: 34, location: "San Diego, California", nativeLanguage: "English", learningLanguages: ["Hindi"], profilePhotos: ["https://picsum.photos/seed/mia/400"], gender: "female", genderPreference: "all", minAge: 28, maxAge: 42, locationPreference: "regional_100km", latitude: 32.7157, longitude: -117.1611, relationshipIntents: ["friendship"], learningContexts: ["cultural", "fun"], allowNonNativeMatches: true),

            // 8 Spanish speakers
            TestProfile(id: "20000000-0000-0000-0000-000000000001", email: "carlos.garcia@test.com", phoneNumber: "+34551001", firstName: "Carlos", lastName: "García", bio: "¡Hola! From Madrid. Want to practice English and meet new people!", birthYear: 1994, age: 31, location: "Madrid, Spain", nativeLanguage: "Spanish", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/carlos/400"], gender: "male", genderPreference: "female", minAge: 26, maxAge: 38, locationPreference: "anywhere", latitude: 40.4168, longitude: -3.7038, relationshipIntents: ["open_to_dating", "friendship"], learningContexts: ["travel", "fun"]),

            TestProfile(id: "20000000-0000-0000-0000-000000000002", email: "maria.rodriguez@test.com", phoneNumber: "+34551002", firstName: "María", lastName: "Rodríguez", bio: "Barcelona native. Love architecture and art! Learning English.", birthYear: 1992, age: 33, location: "Barcelona, Spain", nativeLanguage: "Spanish", learningLanguages: ["English", "French"], profilePhotos: ["https://picsum.photos/seed/maria/400"], gender: "female", genderPreference: "all", minAge: 28, maxAge: 40, locationPreference: "local_25km", latitude: 41.3851, longitude: 2.1734, relationshipIntents: ["friendship"], learningContexts: ["cultural", "fun"]),

            TestProfile(id: "20000000-0000-0000-0000-000000000003", email: "diego.lopez@test.com", phoneNumber: "+52551003", firstName: "Diego", lastName: "López", bio: "From Mexico City! Software dev wanting to improve English.", birthYear: 1995, age: 30, location: "Mexico City, Mexico", nativeLanguage: "Spanish", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/diego/400"], gender: "male", genderPreference: "all", minAge: 25, maxAge: 38, locationPreference: "anywhere", latitude: 19.4326, longitude: -99.1332, relationshipIntents: ["language_practice_only", "friendship"], learningContexts: ["work", "travel"]),

            TestProfile(id: "20000000-0000-0000-0000-000000000004", email: "lucia.fernandez@test.com", phoneNumber: "+54551004", firstName: "Lucía", lastName: "Fernández", bio: "Argentine teacher. Learning English to teach better! ❤️", birthYear: 1990, age: 35, location: "Buenos Aires, Argentina", nativeLanguage: "Spanish", learningLanguages: ["English", "Portuguese"], profilePhotos: ["https://picsum.photos/seed/lucia/400"], gender: "female", genderPreference: "all", minAge: 30, maxAge: 45, locationPreference: "regional_100km", latitude: -34.6037, longitude: -58.3816, relationshipIntents: ["friendship"], learningContexts: ["work", "academic"], allowNonNativeMatches: true),

            TestProfile(id: "20000000-0000-0000-0000-000000000005", email: "pablo.martinez@test.com", phoneNumber: "+57551005", firstName: "Pablo", lastName: "Martínez", bio: "Bogotá. Coffee lover ☕ Learning English for travel!", birthYear: 1996, age: 29, location: "Bogotá, Colombia", nativeLanguage: "Spanish", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/pablo/400"], gender: "male", genderPreference: "all", minAge: 25, maxAge: 35, locationPreference: "anywhere", latitude: 4.7110, longitude: -74.0721, relationshipIntents: ["friendship", "language_practice_only"], learningContexts: ["travel", "fun"]),

            TestProfile(id: "20000000-0000-0000-0000-000000000006", email: "sofia.torres@test.com", phoneNumber: "+56551006", firstName: "Sofía", lastName: "Torres", bio: "From Santiago! Learning English and French. Wine enthusiast 🍷", birthYear: 1993, age: 32, location: "Santiago, Chile", nativeLanguage: "Spanish", learningLanguages: ["English", "French"], profilePhotos: ["https://picsum.photos/seed/sofia/400"], gender: "female", genderPreference: "male", minAge: 27, maxAge: 40, locationPreference: "anywhere", latitude: -33.4489, longitude: -70.6693, relationshipIntents: ["open_to_dating", "friendship"], learningContexts: ["cultural", "travel"]),

            TestProfile(id: "20000000-0000-0000-0000-000000000007", email: "javier.santos@test.com", phoneNumber: "+51551007", firstName: "Javier", lastName: "Santos", bio: "Lima, Peru. Traveling to USA next month! Need English practice.", birthYear: 1997, age: 28, location: "Lima, Peru", nativeLanguage: "Spanish", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/javier/400"], gender: "male", genderPreference: "all", minAge: 24, maxAge: 35, locationPreference: "anywhere", latitude: -12.0464, longitude: -77.0428, relationshipIntents: ["language_practice_only"], learningContexts: ["travel", "work"]),

            TestProfile(id: "20000000-0000-0000-0000-000000000008", email: "valentina.ruiz@test.com", phoneNumber: "+58551008", firstName: "Valentina", lastName: "Ruiz", bio: "Venezuelan in Miami! Bilingual and happy to help Spanish learners.", birthYear: 1994, age: 31, location: "Miami, Florida", nativeLanguage: "Spanish", learningLanguages: ["English", "Portuguese"], profilePhotos: ["https://picsum.photos/seed/valentina/400"], gender: "female", genderPreference: "all", minAge: 26, maxAge: 38, locationPreference: "local_25km", latitude: 25.7617, longitude: -80.1918, relationshipIntents: ["friendship", "open_to_dating"], learningContexts: ["fun", "cultural"], allowNonNativeMatches: true),

            // 6 French speakers
            TestProfile(id: "30000000-0000-0000-0000-000000000001", email: "pierre.dubois@test.com", phoneNumber: "+33551001", firstName: "Pierre", lastName: "Dubois", bio: "Parisien chef learning English. Food lover! 🥖", birthYear: 1991, age: 34, location: "Paris, France", nativeLanguage: "French", learningLanguages: ["English", "Italian"], profilePhotos: ["https://picsum.photos/seed/pierre/400"], gender: "male", genderPreference: "all", minAge: 28, maxAge: 42, locationPreference: "local_25km", latitude: 48.8566, longitude: 2.3522, relationshipIntents: ["friendship", "open_to_dating"], learningContexts: ["work", "cultural"]),

            TestProfile(id: "30000000-0000-0000-0000-000000000002", email: "amelie.martin@test.com", phoneNumber: "+33551002", firstName: "Amélie", lastName: "Martin", bio: "From Lyon. Fashion designer learning English and Spanish!", birthYear: 1995, age: 30, location: "Lyon, France", nativeLanguage: "French", learningLanguages: ["English", "Spanish"], profilePhotos: ["https://picsum.photos/seed/amelie/400"], gender: "female", genderPreference: "all", minAge: 26, maxAge: 38, locationPreference: "anywhere", latitude: 45.7640, longitude: 4.8357, relationshipIntents: ["friendship"], learningContexts: ["work", "travel"]),

            TestProfile(id: "30000000-0000-0000-0000-000000000003", email: "lucas.bernard@test.com", phoneNumber: "+33551003", firstName: "Lucas", lastName: "Bernard", bio: "Marseille native. Learning English for tech career!", birthYear: 1996, age: 29, location: "Marseille, France", nativeLanguage: "French", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/lucas/400"], gender: "male", genderPreference: "all", minAge: 25, maxAge: 35, locationPreference: "regional_100km", latitude: 43.2965, longitude: 5.3698, relationshipIntents: ["language_practice_only"], learningContexts: ["work", "fun"]),

            TestProfile(id: "30000000-0000-0000-0000-000000000004", email: "chloe.laurent@test.com", phoneNumber: "+33551004", firstName: "Chloé", lastName: "Laurent", bio: "Bordeaux wine country! Learning English and German.", birthYear: 1993, age: 32, location: "Bordeaux, France", nativeLanguage: "French", learningLanguages: ["English", "German"], profilePhotos: ["https://picsum.photos/seed/chloe/400"], gender: "female", genderPreference: "male", minAge: 27, maxAge: 40, locationPreference: "anywhere", latitude: 44.8378, longitude: -0.5792, relationshipIntents: ["open_to_dating", "friendship"], learningContexts: ["travel", "cultural"]),

            TestProfile(id: "30000000-0000-0000-0000-000000000005", email: "antoine.moreau@test.com", phoneNumber: "+33551005", firstName: "Antoine", lastName: "Moreau", bio: "Nice. Beach lover 🏖️ Learning English for international friends!", birthYear: 1994, age: 31, location: "Nice, France", nativeLanguage: "French", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/antoine/400"], gender: "male", genderPreference: "all", minAge: 26, maxAge: 38, locationPreference: "local_25km", latitude: 43.7102, longitude: 7.2620, relationshipIntents: ["friendship"], learningContexts: ["fun", "travel"], allowNonNativeMatches: true),

            TestProfile(id: "30000000-0000-0000-0000-000000000006", email: "emma.rousseau@test.com", phoneNumber: "+33551006", firstName: "Emma", lastName: "Rousseau", bio: "Toulouse student. Learning English and Spanish!", birthYear: 1998, age: 27, location: "Toulouse, France", nativeLanguage: "French", learningLanguages: ["English", "Spanish"], profilePhotos: ["https://picsum.photos/seed/emma2/400"], gender: "female", genderPreference: "all", minAge: 23, maxAge: 33, locationPreference: "regional_100km", latitude: 43.6047, longitude: 1.4442, relationshipIntents: ["friendship"], learningContexts: ["academic", "fun"]),

            // 6 Japanese speakers
            TestProfile(id: "40000000-0000-0000-0000-000000000001", email: "yuki.tanaka@test.com", phoneNumber: "+81551001", firstName: "Yuki", lastName: "Tanaka", bio: "Tokyo software engineer. Anime and manga fan! Learning English.", birthYear: 1995, age: 30, location: "Tokyo, Japan", nativeLanguage: "Japanese", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/yuki/400"], gender: "male", genderPreference: "all", minAge: 26, maxAge: 38, locationPreference: "anywhere", latitude: 35.6762, longitude: 139.6503, relationshipIntents: ["friendship", "language_practice_only"], learningContexts: ["work", "fun"]),

            TestProfile(id: "40000000-0000-0000-0000-000000000002", email: "sakura.yamamoto@test.com", phoneNumber: "+81551002", firstName: "Sakura", lastName: "Yamamoto", bio: "From Kyoto. Traditional tea ceremony instructor. Learning English!", birthYear: 1992, age: 33, location: "Kyoto, Japan", nativeLanguage: "Japanese", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/sakura/400"], gender: "female", genderPreference: "all", minAge: 28, maxAge: 40, locationPreference: "local_25km", latitude: 35.0116, longitude: 135.7681, relationshipIntents: ["friendship"], learningContexts: ["cultural", "work"]),

            TestProfile(id: "40000000-0000-0000-0000-000000000003", email: "kenji.sato@test.com", phoneNumber: "+81551003", firstName: "Kenji", lastName: "Sato", bio: "Osaka. Food blogger learning English to reach more people!", birthYear: 1994, age: 31, location: "Osaka, Japan", nativeLanguage: "Japanese", learningLanguages: ["English", "Korean"], profilePhotos: ["https://picsum.photos/seed/kenji/400"], gender: "male", genderPreference: "female", minAge: 27, maxAge: 38, locationPreference: "regional_100km", latitude: 34.6937, longitude: 135.5023, relationshipIntents: ["open_to_dating", "friendship"], learningContexts: ["work", "fun"]),

            TestProfile(id: "40000000-0000-0000-0000-000000000004", email: "hana.nakamura@test.com", phoneNumber: "+81551004", firstName: "Hana", lastName: "Nakamura", bio: "Traveling to California soon! Need English practice 🌸", birthYear: 1996, age: 29, location: "Yokohama, Japan", nativeLanguage: "Japanese", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/hana/400"], gender: "female", genderPreference: "all", minAge: 25, maxAge: 35, locationPreference: "anywhere", latitude: 35.4437, longitude: 139.6380, relationshipIntents: ["friendship"], learningContexts: ["travel", "fun"]),

            TestProfile(id: "40000000-0000-0000-0000-000000000005", email: "ryo.suzuki@test.com", phoneNumber: "+81551005", firstName: "Ryo", lastName: "Suzuki", bio: "Sapporo. Ski instructor learning English for international guests!", birthYear: 1993, age: 32, location: "Sapporo, Japan", nativeLanguage: "Japanese", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/ryo/400"], gender: "male", genderPreference: "all", minAge: 27, maxAge: 40, locationPreference: "local_25km", latitude: 43.0642, longitude: 141.3469, relationshipIntents: ["friendship"], learningContexts: ["work", "fun"], allowNonNativeMatches: true),

            TestProfile(id: "40000000-0000-0000-0000-000000000006", email: "miyu.ishikawa@test.com", phoneNumber: "+81551006", firstName: "Miyu", lastName: "Ishikawa", bio: "From Fukuoka. Fashion student going to Paris next year!", birthYear: 1997, age: 28, location: "Fukuoka, Japan", nativeLanguage: "Japanese", learningLanguages: ["English", "French"], profilePhotos: ["https://picsum.photos/seed/miyu/400"], gender: "female", genderPreference: "all", minAge: 24, maxAge: 34, locationPreference: "anywhere", latitude: 33.5904, longitude: 130.4017, relationshipIntents: ["friendship"], learningContexts: ["academic", "travel"]),

            // 5 German speakers
            TestProfile(id: "50000000-0000-0000-0000-000000000001", email: "max.mueller@test.com", phoneNumber: "+49551001", firstName: "Max", lastName: "Müller", bio: "Berlin tech startup founder. Learning English and Spanish!", birthYear: 1991, age: 34, location: "Berlin, Germany", nativeLanguage: "German", learningLanguages: ["English", "Spanish"], profilePhotos: ["https://picsum.photos/seed/max/400"], gender: "male", genderPreference: "all", minAge: 28, maxAge: 42, locationPreference: "anywhere", latitude: 52.5200, longitude: 13.4050, relationshipIntents: ["friendship"], learningContexts: ["work", "travel"]),

            TestProfile(id: "50000000-0000-0000-0000-000000000002", email: "anna.schmidt@test.com", phoneNumber: "+49551002", firstName: "Anna", lastName: "Schmidt", bio: "From Munich. Oktoberfest guide learning English!", birthYear: 1994, age: 31, location: "Munich, Germany", nativeLanguage: "German", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/anna/400"], gender: "female", genderPreference: "male", minAge: 26, maxAge: 38, locationPreference: "local_25km", latitude: 48.1351, longitude: 11.5820, relationshipIntents: ["open_to_dating", "friendship"], learningContexts: ["work", "fun"]),

            TestProfile(id: "50000000-0000-0000-0000-000000000003", email: "felix.wagner@test.com", phoneNumber: "+49551003", firstName: "Felix", lastName: "Wagner", bio: "Hamburg musician. Learning English for international tours!", birthYear: 1995, age: 30, location: "Hamburg, Germany", nativeLanguage: "German", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/felix/400"], gender: "male", genderPreference: "all", minAge: 26, maxAge: 38, locationPreference: "regional_100km", latitude: 53.5511, longitude: 9.9937, relationshipIntents: ["friendship"], learningContexts: ["work", "fun"], allowNonNativeMatches: true),

            TestProfile(id: "50000000-0000-0000-0000-000000000004", email: "lena.weber@test.com", phoneNumber: "+49551004", firstName: "Lena", lastName: "Weber", bio: "Frankfurt banker learning English and French for work.", birthYear: 1990, age: 35, location: "Frankfurt, Germany", nativeLanguage: "German", learningLanguages: ["English", "French"], profilePhotos: ["https://picsum.photos/seed/lena/400"], gender: "female", genderPreference: "all", minAge: 30, maxAge: 45, locationPreference: "anywhere", latitude: 50.1109, longitude: 8.6821, relationshipIntents: ["language_practice_only"], learningContexts: ["work"]),

            TestProfile(id: "50000000-0000-0000-0000-000000000005", email: "lukas.fischer@test.com", phoneNumber: "+49551005", firstName: "Lukas", lastName: "Fischer", bio: "Cologne university student. Learning English and Dutch!", birthYear: 1997, age: 28, location: "Cologne, Germany", nativeLanguage: "German", learningLanguages: ["English", "Dutch"], profilePhotos: ["https://picsum.photos/seed/lukas/400"], gender: "male", genderPreference: "all", minAge: 24, maxAge: 34, locationPreference: "local_25km", latitude: 50.9375, longitude: 6.9603, relationshipIntents: ["friendship"], learningContexts: ["academic", "fun"]),

            // 5 Mandarin/Korean speakers
            TestProfile(id: "60000000-0000-0000-0000-000000000001", email: "wei.zhang@test.com", phoneNumber: "+86551001", firstName: "Wei", lastName: "Zhang", bio: "Shanghai software developer. Learning English for career!", birthYear: 1993, age: 32, location: "Shanghai, China", nativeLanguage: "Mandarin", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/wei/400"], gender: "male", genderPreference: "all", minAge: 27, maxAge: 40, locationPreference: "anywhere", latitude: 31.2304, longitude: 121.4737, relationshipIntents: ["language_practice_only"], learningContexts: ["work"]),

            TestProfile(id: "60000000-0000-0000-0000-000000000002", email: "li.wang@test.com", phoneNumber: "+86551002", firstName: "Li", lastName: "Wang", bio: "From Beijing. University teacher learning English!", birthYear: 1990, age: 35, location: "Beijing, China", nativeLanguage: "Mandarin", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/li/400"], gender: "female", genderPreference: "all", minAge: 30, maxAge: 45, locationPreference: "regional_100km", latitude: 39.9042, longitude: 116.4074, relationshipIntents: ["friendship"], learningContexts: ["work", "academic"]),

            TestProfile(id: "60000000-0000-0000-0000-000000000003", email: "jimin.park@test.com", phoneNumber: "+82551003", firstName: "Jimin", lastName: "Park", bio: "Seoul K-pop fan! Learning English and Japanese 🎵", birthYear: 1996, age: 29, location: "Seoul, South Korea", nativeLanguage: "Korean", learningLanguages: ["English", "Japanese"], profilePhotos: ["https://picsum.photos/seed/jimin/400"], gender: "non_binary", genderPreference: "all", minAge: 25, maxAge: 35, locationPreference: "anywhere", latitude: 37.5665, longitude: 126.9780, relationshipIntents: ["friendship"], learningContexts: ["fun", "cultural"], allowNonNativeMatches: true),

            TestProfile(id: "60000000-0000-0000-0000-000000000004", email: "soo-jin.kim@test.com", phoneNumber: "+82551004", firstName: "Soo-Jin", lastName: "Kim", bio: "Busan. Fashion blogger moving to LA next month!", birthYear: 1994, age: 31, location: "Busan, South Korea", nativeLanguage: "Korean", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/soojin/400"], gender: "female", genderPreference: "all", minAge: 26, maxAge: 38, locationPreference: "anywhere", latitude: 35.1796, longitude: 129.0756, relationshipIntents: ["friendship", "open_to_dating"], learningContexts: ["work", "travel"]),

            TestProfile(id: "60000000-0000-0000-0000-000000000005", email: "xiao.chen@test.com", phoneNumber: "+86551005", firstName: "Xiao", lastName: "Chen", bio: "Guangzhou. Learning English to study abroad!", birthYear: 1997, age: 28, location: "Guangzhou, China", nativeLanguage: "Mandarin", learningLanguages: ["English"], profilePhotos: ["https://picsum.photos/seed/xiao/400"], gender: "female", genderPreference: "all", minAge: 24, maxAge: 34, locationPreference: "regional_100km", latitude: 23.1291, longitude: 113.2644, relationshipIntents: ["language_practice_only"], learningContexts: ["academic", "travel"])
        ]
    }
}

// MARK: - Test Profile Model
struct TestProfile {
    let id, email, phoneNumber, firstName: String
    let lastName: String?
    let bio: String
    let birthYear, age: Int
    let location: String?
    let nativeLanguage: String
    let learningLanguages, profilePhotos: [String]
    let gender, genderPreference: String
    let minAge, maxAge: Int
    let locationPreference: String
    let latitude, longitude: Double?
    let relationshipIntents, learningContexts: [String]
    let allowNonNativeMatches: Bool
    let minProficiencyLevel, maxProficiencyLevel: String

    init(id: String, email: String, phoneNumber: String, firstName: String, lastName: String? = nil, bio: String, birthYear: Int, age: Int, location: String? = nil, nativeLanguage: String, learningLanguages: [String], profilePhotos: [String], gender: String, genderPreference: String, minAge: Int, maxAge: Int, locationPreference: String, latitude: Double? = nil, longitude: Double? = nil, relationshipIntents: [String], learningContexts: [String], allowNonNativeMatches: Bool = false, minProficiencyLevel: String = "beginner", maxProficiencyLevel: String = "advanced") {
        self.id = id
        self.email = email
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.bio = bio
        self.birthYear = birthYear
        self.age = age
        self.location = location
        self.nativeLanguage = nativeLanguage
        self.learningLanguages = learningLanguages
        self.profilePhotos = profilePhotos
        self.gender = gender
        self.genderPreference = genderPreference
        self.minAge = minAge
        self.maxAge = maxAge
        self.locationPreference = locationPreference
        self.latitude = latitude
        self.longitude = longitude
        self.relationshipIntents = relationshipIntents
        self.learningContexts = learningContexts
        self.allowNonNativeMatches = allowNonNativeMatches
        self.minProficiencyLevel = minProficiencyLevel
        self.maxProficiencyLevel = maxProficiencyLevel
    }
}

// MARK: - Profile Insert Model (Encodable for Supabase)
struct ProfileInsertWithoutId: Codable {
    let email: String
    let phoneNumber: String
    let firstName: String
    let lastName: String?
    let bio: String
    let birthYear: Int
    let age: Int
    let location: String?
    let nativeLanguage: String
    let learningLanguages: [String]
    let profilePhotos: [String]
    let onboardingCompleted: Bool
    let gender: String
    let genderPreference: String
    let minAge: Int
    let maxAge: Int
    let locationPreference: String
    let latitude: Double?
    let longitude: Double?
    let relationshipIntents: [String]
    let learningContexts: [String]
    let allowNonNativeMatches: Bool
    let minProficiencyLevel: String
    let maxProficiencyLevel: String
    let lastActive: String

    enum CodingKeys: String, CodingKey {
        case email, bio, age, location, gender, latitude, longitude
        case phoneNumber = "phone_number"
        case firstName = "first_name"
        case lastName = "last_name"
        case birthYear = "birth_year"
        case nativeLanguage = "native_language"
        case learningLanguages = "learning_languages"
        case profilePhotos = "profile_photos"
        case onboardingCompleted = "onboarding_completed"
        case genderPreference = "gender_preference"
        case minAge = "min_age"
        case maxAge = "max_age"
        case locationPreference = "location_preference"
        case relationshipIntents = "relationship_intents"
        case learningContexts = "learning_contexts"
        case allowNonNativeMatches = "allow_non_native_matches"
        case minProficiencyLevel = "min_proficiency_level"
        case maxProficiencyLevel = "max_proficiency_level"
        case lastActive = "last_active"
    }
}
#endif
