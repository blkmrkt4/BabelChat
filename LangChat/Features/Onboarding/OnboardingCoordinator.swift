import UIKit

enum OnboardingStep: Int, CaseIterable {
    case name = 0
    case birthYear
    case hometown
    case nativeLanguage
    case learningLanguages
    case languageProficiency
    case proficiencyRange  // Match proficiency preference
    case museLanguages     // Additional languages for AI Muse (beyond matching languages)
    case learningGoals
    case bio
    case ageRange
    case locationPreference
    case travelPlans
    case relationshipIntent
    case datingPreferences  // Only shown if user selects "Open to dating"
    case privacyPreferences
    case profilePhoto
    case notifications

    var title: String {
        switch self {
        case .name: return "Your Name"
        case .birthYear: return "Birth Year"
        case .hometown: return "Hometown"
        case .nativeLanguage: return "Native Language"
        case .learningLanguages: return "Languages to Learn"
        case .languageProficiency: return "Language Skills"
        case .proficiencyRange: return "Match Preferences"
        case .museLanguages: return "Muse Languages"
        case .learningGoals: return "Learning Goals"
        case .profilePhoto: return "Add Photos"
        case .bio: return "About You"
        case .ageRange: return "Age Preference"
        case .locationPreference: return "Location Range"
        case .travelPlans: return "Travel Plans"
        case .relationshipIntent: return "What You're Looking For"
        case .datingPreferences: return "Dating Preferences"
        case .privacyPreferences: return "Privacy Settings"
        case .notifications: return "Stay Connected"
        }
    }

    var progress: Float {
        return Float(self.rawValue + 1) / Float(OnboardingStep.allCases.count)
    }
}

class OnboardingCoordinator {
    private weak var navigationController: UINavigationController?
    private var currentStep: OnboardingStep = .name
    private var userData: OnboardingUserData = OnboardingUserData()

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func start() {
        print("OnboardingCoordinator: Starting onboarding")
        showStep(.name)
    }

    func showStep(_ step: OnboardingStep) {
        print("📍 OnboardingCoordinator: showStep(\(step)) called")
        print("📍 OnboardingCoordinator: Navigation controller: \(navigationController != nil ? "exists" : "NIL!")")
        currentStep = step

        let viewController: UIViewController

        switch step {
        case .name:
            let vc = NameInputViewController()
            vc.delegate = self
            viewController = vc

        case .birthYear:
            let vc = BirthYearViewController()
            vc.delegate = self
            viewController = vc

        case .hometown:
            let vc = HometownViewController()
            vc.delegate = self
            viewController = vc

        case .nativeLanguage:
            let vc = NativeLanguageViewController()
            vc.delegate = self
            viewController = vc

        case .learningLanguages:
            let vc = LearningLanguagesViewController()
            vc.nativeLanguage = userData.nativeLanguage  // Pass native language to exclude it
            vc.delegate = self
            viewController = vc

        case .languageProficiency:
            let vc = LanguageProficiencyViewController()
            vc.languages = userData.learningLanguages
            vc.delegate = self
            viewController = vc

        case .proficiencyRange:
            let vc = ProficiencyRangeViewController()
            vc.delegate = self
            viewController = vc

        case .museLanguages:
            let vc = MuseLanguageSelectionViewController()
            vc.learningLanguages = userData.learningLanguages
            vc.nativeLanguage = userData.nativeLanguage
            vc.delegate = self
            viewController = vc

        case .learningGoals:
            let vc = LearningGoalsViewController()
            vc.delegate = self
            viewController = vc

        case .profilePhoto:
            let vc = ProfilePhotoViewController()
            vc.delegate = self
            viewController = vc

        case .bio:
            let vc = BioViewController()
            vc.delegate = self
            viewController = vc

        case .ageRange:
            let vc = AgeRangeViewController()
            vc.delegate = self
            viewController = vc

        case .locationPreference:
            let vc = LocationPreferenceViewController()
            vc.delegate = self
            viewController = vc

        case .travelPlans:
            let vc = TravelPlansViewController()
            vc.delegate = self
            viewController = vc

        case .relationshipIntent:
            let vc = RelationshipIntentViewController()
            vc.delegate = self
            viewController = vc

        case .datingPreferences:
            let vc = DatingPreferencesViewController()
            vc.delegate = self
            viewController = vc

        case .privacyPreferences:
            let vc = PrivacyPreferencesViewController()
            vc.delegate = self
            viewController = vc

        case .notifications:
            let vc = NotificationsPermissionViewController()
            vc.delegate = self
            viewController = vc
        }

        print("📍 OnboardingCoordinator: About to push \(type(of: viewController))")
        navigationController?.pushViewController(viewController, animated: true)
        print("📍 OnboardingCoordinator: Push completed for \(type(of: viewController))")
    }

    func nextStep() {
        print("📍 OnboardingCoordinator: nextStep() called from step \(currentStep)")
        guard var nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            print("📍 OnboardingCoordinator: No more steps, completing onboarding")
            completeOnboarding()
            return
        }

        // Skip datingPreferences if user didn't select "Open to dating"
        if nextStep == .datingPreferences {
            let isOpenToDating = userData.relationshipIntent == .openToDating
            if !isOpenToDating {
                print("📍 OnboardingCoordinator: Skipping datingPreferences (not open to dating)")
                // Skip to next step after datingPreferences
                if let skipToStep = OnboardingStep(rawValue: nextStep.rawValue + 1) {
                    nextStep = skipToStep
                } else {
                    completeOnboarding()
                    return
                }
            }
        }

        // Skip privacyPreferences if user selected "Language Practice Only" (they already saw privacy options)
        if nextStep == .privacyPreferences {
            let hasLanguagePracticeOnly = userData.relationshipIntent == .languagePracticeOnly
            if hasLanguagePracticeOnly {
                print("📍 OnboardingCoordinator: Skipping privacyPreferences (already shown with language practice)")
                if let skipToStep = OnboardingStep(rawValue: nextStep.rawValue + 1) {
                    nextStep = skipToStep
                } else {
                    completeOnboarding()
                    return
                }
            }
        }

        print("📍 OnboardingCoordinator: Moving to step \(nextStep)")
        showStep(nextStep)
    }

    func previousStep() {
        guard currentStep.rawValue > 0,
              var previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }

        // Skip datingPreferences when going back if user didn't select "Open to dating"
        if previousStep == .datingPreferences {
            let isOpenToDating = userData.relationshipIntent == .openToDating
            if !isOpenToDating {
                if let skipToStep = OnboardingStep(rawValue: previousStep.rawValue - 1) {
                    previousStep = skipToStep
                }
            }
        }

        // Skip privacyPreferences when going back if user selected "Language Practice Only"
        if previousStep == .privacyPreferences {
            let hasLanguagePracticeOnly = userData.relationshipIntent == .languagePracticeOnly
            if hasLanguagePracticeOnly {
                if let skipToStep = OnboardingStep(rawValue: previousStep.rawValue - 1) {
                    previousStep = skipToStep
                }
            }
        }

        navigationController?.popViewController(animated: true)
        currentStep = previousStep
    }

    private func completeOnboarding() {
        // Save user data
        saveUserData()

        // Mark that user has engaged with the app (completed onboarding = profile filled)
        UserEngagementTracker.shared.markOnboardingCompleted()
        UserEngagementTracker.shared.markProfileFilled()

        // Mark onboarding as complete (for session persistence)
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        print("✅ Onboarding marked as complete")

        // Show pricing page before transitioning to main app
        showPricingPage()
    }

    private func showPricingPage() {
        let pricingVC = PricingViewController()
        pricingVC.delegate = self
        pricingVC.modalPresentationStyle = .fullScreen
        navigationController?.present(pricingVC, animated: true)
    }

    private func transitionToMainApp() {
        // Transition to main app
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let tabBarController = MainTabBarController()
            window.rootViewController = tabBarController

            UIView.transition(with: window,
                            duration: 0.5,
                            options: .transitionCrossDissolve,
                            animations: nil,
                            completion: nil)
        }
    }

    private func saveUserData() {
        // Save to UserDefaults for now (later will integrate with backend)
        UserDefaults.standard.set(userData.firstName, forKey: "firstName")
        UserDefaults.standard.set(userData.lastName, forKey: "lastName")
        UserDefaults.standard.set(userData.email, forKey: "email")
        UserDefaults.standard.set(userData.birthYear, forKey: "birthYear")
        UserDefaults.standard.set(userData.birthMonth, forKey: "birthMonth")
        UserDefaults.standard.set(userData.hometown, forKey: "location")
        UserDefaults.standard.set(userData.city, forKey: "city")
        UserDefaults.standard.set(userData.country, forKey: "country")
        if let lat = userData.latitude {
            UserDefaults.standard.set(lat, forKey: "latitude")
        }
        if let lon = userData.longitude {
            UserDefaults.standard.set(lon, forKey: "longitude")
        }
        UserDefaults.standard.set(userData.bio, forKey: "bio")

        // Save language data
        if let encoded = try? JSONEncoder().encode(userData.toUserLanguageData()) {
            UserDefaults.standard.set(encoded, forKey: "userLanguages")
        }

        // Save Muse languages (additional languages for AI exploration)
        let museLanguageCodes = userData.museLanguages.map { $0.rawValue }
        UserDefaults.standard.set(museLanguageCodes, forKey: "museLanguages")

        // Save matching preferences
        UserDefaults.standard.set(userData.gender.rawValue, forKey: "gender")
        UserDefaults.standard.set(userData.genderPreference.rawValue, forKey: "genderPreference")
        UserDefaults.standard.set(userData.minAge, forKey: "minAge")
        UserDefaults.standard.set(userData.maxAge, forKey: "maxAge")
        UserDefaults.standard.set(userData.locationPreference.rawValue, forKey: "locationPreference")

        if let customDistanceKm = userData.customDistanceKm {
            UserDefaults.standard.set(customDistanceKm, forKey: "customDistanceKm")
        }

        if let preferredCountries = userData.preferredCountries {
            UserDefaults.standard.set(preferredCountries, forKey: "preferredCountries")
        }

        if let excludedCountries = userData.excludedCountries {
            UserDefaults.standard.set(excludedCountries, forKey: "excludedCountries")
        }

        if let travelDestination = userData.travelDestination,
           let encoded = try? JSONEncoder().encode(travelDestination) {
            UserDefaults.standard.set(encoded, forKey: "travelDestination")
        }

        UserDefaults.standard.set(userData.relationshipIntent.rawValue, forKey: "relationshipIntent")

        // Save proficiency range preference
        userData.matchProficiencyRange.saveToDefaults(
            minKey: "minProficiencyLevel",
            maxKey: "maxProficiencyLevel"
        )

        // Save privacy preferences
        UserDefaults.standard.set(userData.strictlyPlatonic, forKey: "strictlyPlatonic")
        UserDefaults.standard.set(userData.blurPhotosUntilMatch, forKey: "blurPhotosUntilMatch")

        // Generate a temporary user ID
        let userId = UUID().uuidString
        UserDefaults.standard.set(userId, forKey: "userId")
    }
}

// MARK: - Delegate Extensions
extension OnboardingCoordinator: OnboardingStepDelegate {
    func didCompleteStep(withData data: Any?) {
        print("📍 OnboardingCoordinator: didCompleteStep START for \(currentStep)")
        print("📍 OnboardingCoordinator: Data received: \(String(describing: data))")
        print("📍 OnboardingCoordinator: Navigation controller exists: \(navigationController != nil)")
        // Store data based on current step
        switch currentStep {
        case .name:
            if let name = data as? (String, String) {
                userData.firstName = name.0
                userData.lastName = name.1
            }
        case .birthYear:
            if let birthDate = data as? BirthDate {
                userData.birthYear = birthDate.year
                userData.birthMonth = birthDate.month
            } else if let year = data as? Int {
                // Legacy fallback for just year
                userData.birthYear = year
            }
        case .hometown:
            if let locationData = data as? [String: Any] {
                userData.hometown = locationData["name"] as? String
                userData.city = locationData["city"] as? String
                userData.country = locationData["country"] as? String
                userData.latitude = locationData["latitude"] as? Double
                userData.longitude = locationData["longitude"] as? Double
                print("📍 Location stored: \(userData.hometown ?? "nil"), coords: (\(userData.latitude ?? 0), \(userData.longitude ?? 0))")
            } else if let hometown = data as? String {
                // Legacy fallback for string-only location
                userData.hometown = hometown
            }
        case .nativeLanguage:
            if let language = data as? Language {
                userData.nativeLanguage = language
            }
        case .learningLanguages:
            if let languages = data as? [Language] {
                userData.learningLanguages = languages
            }
        case .languageProficiency:
            if let proficiencies = data as? [(Language, LanguageProficiency)] {
                userData.languageProficiencies = proficiencies
            }
        case .proficiencyRange:
            if let range = data as? ProficiencyRange {
                userData.matchProficiencyRange = range
            }
        case .museLanguages:
            if let languages = data as? [Language] {
                userData.museLanguages = languages
            }
        case .learningGoals:
            if let contexts = data as? [LearningContext] {
                userData.learningContexts = contexts
            } else if let goals = data as? [String] {
                // Legacy fallback - convert strings to LearningContext
                userData.learningContexts = goals.compactMap { LearningContext(rawValue: $0) }
            }
        case .profilePhoto:
            if let photos = data as? [UIImage] {
                userData.profilePhotos = photos
            }
        case .bio:
            if let bio = data as? String {
                userData.bio = bio
            }
        case .ageRange:
            if let ageRange = data as? (Int, Int) {
                userData.minAge = ageRange.0
                userData.maxAge = ageRange.1
            }
        case .locationPreference:
            if let locationData = data as? [String: Any] {
                if let preference = locationData["preference"] as? LocationPreference {
                    userData.locationPreference = preference
                }
                userData.customDistanceKm = locationData["customDistanceKm"] as? Int
                userData.preferredCountries = locationData["preferredCountries"] as? [String]
                userData.excludedCountries = locationData["excludedCountries"] as? [String]
            } else if let locationPref = data as? (LocationPreference, [String]?) {
                // Legacy fallback
                userData.locationPreference = locationPref.0
                userData.preferredCountries = locationPref.1
            }
        case .travelPlans:
            if let travel = data as? TravelDestination? {
                userData.travelDestination = travel
            }
        case .relationshipIntent:
            if let intentData = data as? [String: Any] {
                // New format with privacy options included
                if let intent = intentData["intent"] as? RelationshipIntent {
                    userData.relationshipIntent = intent
                }
                if let strictlyPlatonic = intentData["strictlyPlatonic"] as? Bool {
                    userData.strictlyPlatonic = strictlyPlatonic
                }
                if let blurPhotos = intentData["blurPhotosUntilMatch"] as? Bool {
                    userData.blurPhotosUntilMatch = blurPhotos
                }
            } else if let intent = data as? RelationshipIntent {
                // Legacy format fallback
                userData.relationshipIntent = intent
            }
        case .datingPreferences:
            // Combined gender + preference from dating preferences screen
            if let prefs = data as? (Gender, GenderPreference) {
                userData.gender = prefs.0
                userData.genderPreference = prefs.1
            }
        case .privacyPreferences:
            if let prefs = data as? (strictlyPlatonic: Bool, blurPhotosUntilMatch: Bool) {
                userData.strictlyPlatonic = prefs.strictlyPlatonic
                userData.blurPhotosUntilMatch = prefs.blurPhotosUntilMatch
            }
        case .notifications:
            // Permission handled
            break
        }

        print("📍 OnboardingCoordinator: About to call nextStep()")
        nextStep()
        print("📍 OnboardingCoordinator: didCompleteStep END")
    }

    func didRequestPreviousStep() {
        previousStep()
    }
}

// MARK: - OnboardingUserData
struct OnboardingUserData {
    var firstName: String?
    var lastName: String?
    var email: String? // Populated from authentication (Apple Sign In or email login)
    var birthYear: Int?
    var birthMonth: Int?         // 1-12, for accurate age calculation
    var hometown: String?        // Full location name (e.g., "Toronto, ON, Canada")
    var city: String?            // City name (e.g., "Toronto")
    var country: String?         // Country name (e.g., "Canada")
    var latitude: Double?        // GPS latitude for distance matching
    var longitude: Double?       // GPS longitude for distance matching
    var nativeLanguage: Language?
    var learningLanguages: [Language] = []
    var languageProficiencies: [(Language, LanguageProficiency)] = []
    var museLanguages: [Language] = []  // Additional languages for AI Muse exploration
    var learningContexts: [LearningContext] = []  // Learning style preferences
    var profilePhotos: [UIImage] = []
    var bio: String?

    // Matching preferences
    var gender: Gender = .preferNotToSay
    var genderPreference: GenderPreference = .all
    var minAge: Int = 18
    var maxAge: Int = 80
    var locationPreference: LocationPreference = .anywhere
    var customDistanceKm: Int?        // For localRegional option (10-200km)
    var preferredCountries: [String]? // For specificCountries option
    var excludedCountries: [String]?  // For excludeCountries option
    var travelDestination: TravelDestination?
    var relationshipIntent: RelationshipIntent = .languagePracticeOnly
    var matchProficiencyRange: ProficiencyRange = .all

    // Privacy preferences
    var strictlyPlatonic: Bool = false
    var blurPhotosUntilMatch: Bool = false

    func toUserLanguageData() -> UserLanguageData {
        let native = UserLanguage(
            language: nativeLanguage ?? .english,
            proficiency: .native,
            isNative: true
        )

        let learning = learningLanguages.enumerated().map { index, language in
            let proficiency = languageProficiencies.first(where: { $0.0 == language })?.1 ?? .beginner
            return UserLanguage(
                language: language,
                proficiency: proficiency,
                isNative: false
            )
        }

        return UserLanguageData(
            nativeLanguage: native,
            learningLanguages: learning,
            openToLanguages: learningLanguages,
            practiceLanguages: nil
        )
    }
}

// MARK: - PricingViewControllerDelegate
extension OnboardingCoordinator: PricingViewControllerDelegate {
    func didSelectFreeTier() {
        print("✅ User selected Free tier")
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.transitionToMainApp()
        }
    }

    func didSelectPremiumTier() {
        print("✅ User purchased Premium tier")
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.transitionToMainApp()
        }
    }

    func didSelectProTier() {
        print("✅ User purchased Pro tier")
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.transitionToMainApp()
        }
    }

    func didSkipPricing() {
        print("✅ User skipped pricing (continuing with Free tier)")
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.transitionToMainApp()
        }
    }
}

// MARK: - Delegate Protocol
protocol OnboardingStepDelegate: AnyObject {
    func didCompleteStep(withData data: Any?)
    func didRequestPreviousStep()
}