import UIKit

enum OnboardingStep: Int, CaseIterable {
    case phoneNumber = 0
    case phoneVerification
    case name
    case email
    case birthYear
    case hometown
    case nativeLanguage
    case learningLanguages
    case languageProficiency
    case learningGoals
    case profilePhoto
    case bio
    case notifications

    var title: String {
        switch self {
        case .phoneNumber: return "Phone Number"
        case .phoneVerification: return "Verify Phone"
        case .name: return "Your Name"
        case .email: return "Email Address"
        case .birthYear: return "Birth Year"
        case .hometown: return "Location"
        case .nativeLanguage: return "Native Language"
        case .learningLanguages: return "Languages to Learn"
        case .languageProficiency: return "Language Skills"
        case .learningGoals: return "Learning Goals"
        case .profilePhoto: return "Add Photos"
        case .bio: return "About You"
        case .notifications: return "Stay Connected"
        }
    }

    var progress: Float {
        return Float(self.rawValue + 1) / Float(OnboardingStep.allCases.count)
    }
}

class OnboardingCoordinator {
    private weak var navigationController: UINavigationController?
    private var currentStep: OnboardingStep = .phoneNumber
    private var userData: OnboardingUserData = OnboardingUserData()

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func start() {
        print("OnboardingCoordinator: Starting onboarding")
        showStep(.phoneNumber)
    }

    func showStep(_ step: OnboardingStep) {
        print("OnboardingCoordinator: Showing step \(step)")
        currentStep = step

        let viewController: UIViewController

        switch step {
        case .phoneNumber:
            let vc = PhoneNumberViewController()
            vc.delegate = self
            viewController = vc

        case .phoneVerification:
            let vc = PhoneVerificationViewController()
            vc.phoneNumber = userData.phoneNumber
            vc.delegate = self
            viewController = vc

        case .name:
            let vc = NameInputViewController()
            vc.delegate = self
            viewController = vc

        case .email:
            let vc = EmailInputViewController()
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
            vc.delegate = self
            viewController = vc

        case .languageProficiency:
            let vc = LanguageProficiencyViewController()
            vc.languages = userData.learningLanguages
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

        // Set user as signed in
        UserDefaults.standard.set(true, forKey: "isUserSignedIn")

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
        UserDefaults.standard.set(userData.phoneNumber, forKey: "phoneNumber")
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
        case .phoneNumber:
            if let phone = data as? String {
                userData.phoneNumber = phone
            }
        case .phoneVerification:
            // Verification confirmed
            break
        case .name:
            if let name = data as? (String, String) {
                userData.firstName = name.0
                userData.lastName = name.1
            }
        case .email:
            if let email = data as? String {
                userData.email = email
            }
        case .birthYear:
            if let year = data as? Int {
                userData.birthYear = year
            }
        case .hometown:
            if let location = data as? String {
                userData.hometown = location
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
    var phoneNumber: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var birthYear: Int?
    var hometown: String?
    var nativeLanguage: Language?
    var learningLanguages: [Language] = []
    var languageProficiencies: [(Language, LanguageProficiency)] = []
    var learningGoals: [String] = []
    var profilePhotos: [UIImage] = []
    var bio: String?

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

// MARK: - Delegate Protocol
protocol OnboardingStepDelegate: AnyObject {
    func didCompleteStep(withData data: Any?)
    func didRequestPreviousStep()
}