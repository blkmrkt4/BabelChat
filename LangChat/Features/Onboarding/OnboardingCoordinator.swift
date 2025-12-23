import UIKit

enum OnboardingStep: Int, CaseIterable {
    case name = 0
    case birthYear
    case hometown
    case nativeLanguage
    case learningLanguages
    case languageProficiency
    case proficiencyRange  // NEW: Match proficiency preference
    case museLanguages     // Additional languages for AI Muse (beyond matching languages)
    case learningGoals
    case bio
    case gender
    case genderPreference
    case ageRange
    case locationPreference
    case travelPlans
    case relationshipIntent
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
        case .museLanguages: return "Explore Languages"
        case .learningGoals: return "Learning Goals"
        case .profilePhoto: return "Add Photos"
        case .bio: return "About You"
        case .gender: return "Your Gender"
        case .genderPreference: return "Match Preferences"
        case .ageRange: return "Age Preference"
        case .locationPreference: return "Location Range"
        case .travelPlans: return "Travel Plans"
        case .relationshipIntent: return "What You're Looking For"
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
        print("OnboardingCoordinator: Showing step \(step)")
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

        case .gender:
            let vc = GenderSelectionViewController()
            vc.delegate = self
            viewController = vc

        case .genderPreference:
            let vc = GenderPreferenceViewController()
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

        case .privacyPreferences:
            let vc = PrivacyPreferencesViewController()
            vc.delegate = self
            viewController = vc

        case .notifications:
            let vc = NotificationsPermissionViewController()
            vc.delegate = self
            viewController = vc
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    func nextStep() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        showStep(nextStep)
    }

    func previousStep() {
        guard currentStep.rawValue > 0,
              let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
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
        // Transition to main app with Language Lab
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let languageLabVC = LanguageLabViewController()
            let navController = UINavigationController(rootViewController: languageLabVC)

            // Create tab bar with Language Lab as first tab
            let tabBarController = MainTabBarController()

            // Insert Language Lab as first tab
            var viewControllers = tabBarController.viewControllers ?? []
            viewControllers.insert(navController, at: 0)
            tabBarController.viewControllers = viewControllers
            tabBarController.selectedIndex = 0

            // Update tab bar item
            navController.tabBarItem = UITabBarItem(
                title: "Lab",
                image: UIImage(systemName: "flask"),
                selectedImage: UIImage(systemName: "flask.fill")
            )

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
        UserDefaults.standard.set(userData.hometown, forKey: "location")
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

        if let preferredCountries = userData.preferredCountries {
            UserDefaults.standard.set(preferredCountries, forKey: "preferredCountries")
        }

        if let travelDestination = userData.travelDestination,
           let encoded = try? JSONEncoder().encode(travelDestination) {
            UserDefaults.standard.set(encoded, forKey: "travelDestination")
        }

        let intentRawValues = userData.relationshipIntents.map { $0.rawValue }
        UserDefaults.standard.set(intentRawValues, forKey: "relationshipIntents")

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
        print("OnboardingCoordinator: didCompleteStep called for \(currentStep) with data: \(String(describing: data))")
        // Store data based on current step
        switch currentStep {
        case .name:
            if let name = data as? (String, String) {
                userData.firstName = name.0
                userData.lastName = name.1
            }
        case .birthYear:
            if let year = data as? Int {
                userData.birthYear = year
            }
        case .hometown:
            if let hometown = data as? String {
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
            if let goals = data as? [String] {
                userData.learningGoals = goals
            }
        case .profilePhoto:
            if let photos = data as? [UIImage] {
                userData.profilePhotos = photos
            }
        case .bio:
            if let bio = data as? String {
                userData.bio = bio
            }
        case .gender:
            if let gender = data as? Gender {
                userData.gender = gender
            }
        case .genderPreference:
            if let preference = data as? GenderPreference {
                userData.genderPreference = preference
            }
        case .ageRange:
            if let ageRange = data as? (Int, Int) {
                userData.minAge = ageRange.0
                userData.maxAge = ageRange.1
            }
        case .locationPreference:
            if let locationPref = data as? (LocationPreference, [String]?) {
                userData.locationPreference = locationPref.0
                userData.preferredCountries = locationPref.1
            }
        case .travelPlans:
            if let travel = data as? TravelDestination? {
                userData.travelDestination = travel
            }
        case .relationshipIntent:
            if let intents = data as? [RelationshipIntent] {
                userData.relationshipIntents = intents
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

        nextStep()
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
    var hometown: String?
    var nativeLanguage: Language?
    var learningLanguages: [Language] = []
    var languageProficiencies: [(Language, LanguageProficiency)] = []
    var museLanguages: [Language] = []  // Additional languages for AI Muse exploration
    var learningGoals: [String] = []
    var profilePhotos: [UIImage] = []
    var bio: String?

    // Matching preferences
    var gender: Gender = .preferNotToSay
    var genderPreference: GenderPreference = .all
    var minAge: Int = 18
    var maxAge: Int = 80
    var locationPreference: LocationPreference = .anywhere
    var preferredCountries: [String]?
    var travelDestination: TravelDestination?
    var relationshipIntents: [RelationshipIntent] = [.languagePracticeOnly]
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