# LangMatcher iOS App - Product Requirements Document for Xcode Development

## Executive Summary
**App Name:** LangMatcher  
**Platform:** iOS Native App (iPhone primary, iPad compatible)  
**Development Environment:** Xcode 15+  
**Target iOS Version:** iOS 16.0+  
**App Type:** Standard iOS App (not Document-based or iMessage)

## App Architecture Decision

### Why Standard iOS App (Not Document or iMessage App)
- **Standard App** is the correct choice because:
  - Full control over UI/UX for matching and chat features
  - Access to all iOS frameworks and capabilities
  - Push notifications for messages and matches
  - Background refresh for real-time messaging
  - Camera access for profile photos
  - Complex navigation patterns (tabs, modals, swipes)
  
- **Not Document App** because we're not primarily editing/managing documents
- **Not iMessage App** because we need our own user system, matching algorithm, and custom chat interface

## Core Technical Stack for iOS

### Frontend Architecture
```
- UIKit + SwiftUI hybrid approach
  - UIKit: Navigation structure, complex gestures
  - SwiftUI: Modern UI components, profile setup flows
- MVVM-C Pattern (Model-View-ViewModel-Coordinator)
- Combine Framework for reactive programming
```

### Key Frameworks & Libraries
```swift
// Core Frameworks
import UIKit
import SwiftUI
import Combine
import CoreData // Local data persistence
import CloudKit // User sync across devices

// Networking & Real-time
import Network // Network monitoring
import URLSession // API calls
import UserNotifications // Push notifications

// UI/UX
import AVFoundation // Camera for profile photos
import Photos // Photo library access
import MessageUI // Share invites via native share sheet

// Third-party (via Swift Package Manager)
- Alamofire // Advanced networking
- Socket.IO-Client-Swift // Real-time messaging
- KeychainSwift // Secure storage
- Lottie // Animations
- SDWebImage // Image caching
```

### Data Architecture: CloudKit + External Services Hybrid

#### Use CloudKit For:
- **User profiles & preferences**: Profile data, photos, language selections
- **Match history**: All matches, likes, passes for recommendation algorithm
- **Offline message cache**: Store messages locally for offline viewing
- **Settings sync**: Granularity preferences, notification settings across devices
- **Saved phrases/vocabulary**: User's saved translations and learning progress

#### Use External Services For:
- **Real-time messaging**: Socket.io or Firebase Realtime Database for instant chat
- **Translation API calls**: OpenRouter/Google Translate API for message translation
- **Push notifications**: Apple Push Notification Service (APNS) with custom server
- **Payment processing**: StoreKit 2 for IAP + custom server for receipt validation

```swift
// CloudKitManager.swift
class CloudKitManager {
    private let container = CKContainer(identifier: "iCloud.com.langmatcher.app")
    private let privateDatabase = container.privateCloudDatabase
    
    // User Profile in CloudKit
    func saveUserProfile(_ profile: UserProfile) async throws {
        let record = CKRecord(recordType: "UserProfile")
        record["nativeLanguage"] = profile.nativeLanguage
        record["learningLanguages"] = profile.learningLanguages
        record["proficiencyLevels"] = profile.proficiencyLevels
        record["granularityLevel"] = profile.granularityLevel
        record["profileImageURL"] = profile.imageAsset
        
        try await privateDatabase.save(record)
    }
    
    // Sync saved phrases across devices
    func syncSavedPhrases() async throws -> [SavedPhrase] {
        let query = CKQuery(recordType: "SavedPhrase", 
                           predicate: NSPredicate(value: true))
        let results = try await privateDatabase.records(matching: query)
        return results.matchResults.compactMap { SavedPhrase(from: $0) }
    }
}

// Real-time Messaging with External Service
class MessageService {
    private let socketManager: SocketManager
    private let realtimeDB: DatabaseReference // Firebase
    
    func sendMessage(_ message: Message) {
        // Send via Socket.io for real-time delivery
        socket.emit("message", message.toJSON())
        
        // Store in Firebase for persistence
        realtimeDB.child("messages").child(message.id).setValue(message.toDict())
        
        // Cache in Core Data for offline
        CoreDataManager.shared.saveMessage(message)
        
        // Sync to CloudKit for backup
        CloudKitManager.shared.backupMessage(message)
    }
}
```

## Project Structure in Xcode

```
LangMatcher/
├── App/
│   ├── LangMatcherApp.swift
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Info.plist
│   └── LangMatcher.entitlements (CloudKit capability)
├── Core/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Match.swift
│   │   ├── Message.swift
│   │   └── Language.swift
│   ├── Networking/
│   │   ├── APIClient.swift
│   │   ├── WebSocketManager.swift
│   │   ├── TranslationAPIService.swift
│   │   └── Endpoints.swift
│   ├── Services/
│   │   ├── CloudKitManager.swift
│   │   ├── AuthenticationService.swift
│   │   ├── TranslationService.swift
│   │   ├── MatchingService.swift
│   │   ├── RealtimeMessagingService.swift
│   │   └── AIAssistantService.swift
│   └── Utilities/
│       ├── Constants.swift
│       ├── Extensions/
│       └── Helpers/
├── Features/
│   ├── Onboarding/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Coordinators/
│   ├── Authentication/
│   │   ├── LoginView.swift
│   │   ├── SignUpView.swift
│   │   └── AuthViewModel.swift
│   ├── Profile/
│   │   ├── ProfileSetupView.swift
│   │   ├── LanguageSelectionView.swift
│   │   └── ProfileViewModel.swift
│   ├── Matching/
│   │   ├── SwipeCardView.swift
│   │   ├── MatchingViewController.swift
│   │   └── MatchingViewModel.swift
│   ├── Chat/
│   │   ├── ChatListView.swift
│   │   ├── ChatViewController.swift
│   │   ├── MessageCell.swift
│   │   ├── TranslationPaneView.swift
│   │   └── ChatViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SubscriptionView.swift
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.strings (multi-language support)
│   └── Fonts/
└── Tests/
    ├── LangMatcherTests/
    └── LangMatcherUITests/
```

## Core Features Implementation

### 1. User Onboarding Flow
```swift
// OnboardingCoordinator.swift
class OnboardingCoordinator {
    func start() {
        // 1. Welcome screen with app benefits
        // 2. Sign up with Apple/Google/Email
        // 3. Profile photo capture/selection
        // 4. Native language selection (searchable list)
        // 5. Target languages selection (multi-select)
        // 6. Proficiency level selection (per language)
        // 7. Learning goals selection
        // 8. Connection preferences (age, location, etc.)
        // 9. Push notification permissions
        // 10. Subscription selection
    }
}
```

### 2. Matching Interface (Swipe Cards)
```swift
// SwipeCardViewController.swift
class SwipeCardViewController: UIViewController {
    @IBOutlet weak var cardStackView: UIView!
    var cardViews: [ProfileCardView] = []
    
    // Profile card with swipe gestures for matching
    class ProfileCardView: UIView {
        @IBOutlet weak var profileImageView: UIImageView!
        @IBOutlet weak var nameLabel: UILabel!
        @IBOutlet weak var nativeLanguageLabel: UILabel!
        @IBOutlet weak var learningLanguagesLabel: UILabel!
        @IBOutlet weak var proficiencyIndicators: UIStackView!
        
        func configurePanGesture() {
            let panGesture = UIPanGestureRecognizer(target: self, 
                                                    action: #selector(handlePan))
            addGestureRecognizer(panGesture)
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: superview)
            let velocity = gesture.velocity(in: superview)
            
            switch gesture.state {
            case .changed:
                // Move card with finger
                center = CGPoint(x: originalCenter.x + translation.x,
                               y: originalCenter.y + translation.y)
                
                // Rotate card based on horizontal position
                let rotationAngle = translation.x / (superview!.frame.width / 2) * 0.2
                transform = CGAffineTransform(rotationAngle: rotationAngle)
                
                // Show like/nope overlays
                updateOverlays(translation: translation.x)
                
            case .ended:
                // Determine action based on velocity and position
                if abs(translation.x) > 100 || abs(velocity.x) > 500 {
                    if translation.x > 0 {
                        // Swipe right - LIKE/MATCH
                        animateCardOff(direction: .right)
                        delegate?.didSwipeRight(user: profileUser)
                    } else {
                        // Swipe left - PASS
                        animateCardOff(direction: .left)
                        delegate?.didSwipeLeft(user: profileUser)
                    }
                } else {
                    // Snap back to center
                    animateToCenter()
                }
            default:
                break
            }
        }
    }
    
    func handleSwipe(direction: SwipeDirection, user: User) {
        switch direction {
        case .right:
            // Send like to server
            MatchingService.shared.sendLike(to: user)
            // Check for mutual match
            checkForMatch(with: user)
        case .left:
            // Record pass (for algorithm)
            MatchingService.shared.recordPass(user: user)
        case .up:
            // Super like (premium feature)
            if SubscriptionManager.shared.isPremium {
                MatchingService.shared.sendSuperLike(to: user)
            }
        }
    }
}
```

### 3. Chat Interface with Swipeable Messages
```swift
// ChatViewController.swift
class ChatViewController: UIViewController {
    @IBOutlet weak var messagesCollectionView: UICollectionView!
    @IBOutlet weak var inputToolbar: MessageInputToolbar!
    
    // Swipeable message bubble with multiple content layers
    class MessageBubbleCell: UICollectionViewCell {
        @IBOutlet weak var scrollView: UIScrollView! // Horizontal scroll
        @IBOutlet weak var stackView: UIStackView! // Contains all panes
        
        // Content Panes (arranged horizontally)
        @IBOutlet weak var leftPane: UIView!      // Grammar/Alternatives
        @IBOutlet weak var centerPane: UIView!    // Original message (default)
        @IBOutlet weak var rightPane: UIView!     // Native translation
        
        var granularityLevel: Int = 1 // 1-3 from settings
        
        func configure(with message: Message) {
            // Center pane: Always shows original message
            centerPane.messageLabel.text = message.originalText
            
            // Right pane: Native language translation
            rightPane.translationLabel.text = message.translatedText
            
            // Left pane: Based on granularity setting
            switch granularityLevel {
            case 1: // Basic
                leftPane.showBasicCorrections(message.corrections)
            case 2: // Moderate
                leftPane.showGrammarSuggestions(message.grammar)
                leftPane.showCommonAlternatives(message.alternatives)
            case 3: // Verbose
                leftPane.showDetailedGrammar(message.grammar)
                leftPane.showAllAlternatives(message.alternatives)
                leftPane.showCulturalContext(message.culturalNotes)
            }
            
            // Start with center pane visible
            scrollView.setContentOffset(CGPoint(x: centerPane.frame.width, y: 0))
        }
        
        func configureGestures() {
            // Swipe on the message bubble itself
            let rightSwipe = UISwipeGestureRecognizer(target: self, 
                                                       action: #selector(showTranslation))
            rightSwipe.direction = .right
            
            let leftSwipe = UISwipeGestureRecognizer(target: self, 
                                                      action: #selector(showSuggestions))
            leftSwipe.direction = .left
            
            let doubleTap = UITapGestureRecognizer(target: self, 
                                                   action: #selector(pronounceMessage))
            doubleTap.numberOfTapsRequired = 2
            
            let longPress = UILongPressGestureRecognizer(target: self,
                                                         action: #selector(savePhrase))
            
            contentView.addGestureRecognizer(rightSwipe)
            contentView.addGestureRecognizer(leftSwipe)
            contentView.addGestureRecognizer(doubleTap)
            contentView.addGestureRecognizer(longPress)
        }
        
        @objc func showTranslation() {
            // Animate scroll to right pane (native translation)
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
        
        @objc func showSuggestions() {
            // Animate scroll to left pane (grammar/alternatives)
            scrollView.setContentOffset(CGPoint(x: centerPane.frame.width * 2, y: 0), 
                                       animated: true)
        }
        
        @objc func pronounceMessage() {
            // Use AVSpeechSynthesizer with original language
            let utterance = AVSpeechUtterance(string: message.originalText)
            utterance.voice = AVSpeechSynthesisVoice(language: message.originalLanguageCode)
            utterance.rate = 0.5 // Slower for language learning
            speechSynthesizer.speak(utterance)
        }
    }
}
```

### 4. Invite Link System
```swift
// InviteLinkService.swift
class InviteLinkService {
    func generateInviteLink() -> URL {
        // Format: https://langmatcher.com/invite/{unique_code}
        // Deep linking setup in Info.plist
        // Universal Links configuration
    }
    
    func shareInvite() {
        let activityVC = UIActivityViewController(
            activityItems: [inviteURL, customMessage],
            applicationActivities: nil
        )
        // Share to Instagram Stories, WhatsApp, iMessage, etc.
    }
}
```

## AI Integration Architecture

### Translation Service Layer
```swift
// TranslationService.swift
protocol TranslationServiceProtocol {
    func translateMessage(_ text: String, 
                         from: Language, 
                         to: Language) async throws -> TranslationResult
    
    func getGrammarInsights(_ text: String,
                           language: Language) async throws -> GrammarAnalysis
    
    func getCulturalContext(_ text: String,
                           from: Language,
                           to: Language) async throws -> CulturalContext
}

class TranslationService: TranslationServiceProtocol {
    private let openRouterAPI: OpenRouterClient
    private let googleTranslateAPI: GoogleTranslateClient
    
    func translateMessage() {
        // 1. Check cache for common phrases
        // 2. Use Google Translate for basic translation
        // 3. Enhance with OpenRouter for context
        // 4. Cache result
    }
}
```

### API Security
```swift
// APIKeyManager.swift
class APIKeyManager {
    // Store in Keychain, never in code
    // Use CloudKit for server-side key rotation
    // Implement certificate pinning
    
    func getSecureAPIKey() -> String {
        // Retrieve from secure storage
        // Never expose in client code
    }
}
```

## Core User Flows

### 1. First-Time User Experience
1. **App Launch** → Animated logo
2. **Welcome Carousel** → 3 slides explaining concept
3. **Sign Up** → Apple Sign In priority
4. **Payment** → StoreKit 2 integration ($9.99/month)
5. **Profile Setup** → Step-by-step wizard
6. **Tutorial Match** → AI-powered demo conversation
7. **First Real Match** → Algorithmic best match

### 2. Daily Active User Flow
1. **App Open** → Check new matches/messages
2. **Tab Bar Navigation**:
   - Discover (swipe cards)
   - Matches (grid view)
   - Chats (active conversations)
   - Profile (edit/settings)
3. **Background Refresh** → New match notifications

### 3. Chat Interaction Flow with Swipeable Messages
```swift
// User receives message → Push notification
// Open chat → Load conversation history
// View message → Original language displayed (center position)
// Swipe RIGHT on message → Reveal native language translation
// Swipe LEFT on message → Show grammar/alternative expressions
// Double-tap message → Pronounce in original language
// Long press → Save phrase to vocabulary
// Type response → Real-time suggestions based on granularity setting
// Send → Delivery confirmation
```

## Monetization Implementation

### StoreKit 2 Integration
```swift
// SubscriptionManager.swift
class SubscriptionManager {
    enum Tier: String, CaseIterable {
        case free = "com.langmatcher.free"
        case premium = "com.langmatcher.premium.monthly"
        case pro = "com.langmatcher.pro.monthly"
    }
    
    func purchaseSubscription(_ tier: Tier) async {
        // StoreKit 2 async/await API
        // Receipt validation
        // Unlock features
    }
}
```

### Feature Gates
```swift
// Free Tier Limits
struct FreeTierLimits {
    static let dailySwipes = 5
    static let dailyAIExplanations = 3
    static let activeChats = 3
}

// Premium Features
struct PremiumFeatures {
    static let unlimitedSwipes = true
    static let seeWhoLikedYou = true
    static let advancedFilters = true
    static let unlimitedAI = true
}
```

## Key iOS-Specific Considerations

### 1. App Store Optimization
- **Keywords**: language exchange, chat translator, learn languages
- **Category**: Education (primary), Social Networking (secondary)
- **Age Rating**: 12+ (for social features)
- **In-App Purchases**: Clear disclosure required

### 2. iOS Guidelines Compliance
- **Safety**: Report/block features prominent
- **Privacy**: Clear data usage disclosure
- **Photos**: Must respect photo library permissions
- **Payments**: Must use Apple IAP for digital goods

### 3. Performance Optimization
```swift
// Image caching for profile photos
// Message pagination (load 50 at a time)
// Lazy loading for match cards
// Background fetch for new messages
// Push notification handling
```

### 4. Localization Strategy
```swift
// Support from launch:
let supportedLanguages = [
    "en", // English
    "es", // Spanish
    "fr", // French
    "de", // German
    "zh", // Chinese
    "ja", // Japanese
    "pt", // Portuguese
    "ar", // Arabic
]
```

## Development Phases for iOS

### Phase 1: MVP with CloudKit Foundation (Weeks 1-6)
- [ ] CloudKit container setup and configuration
- [ ] Basic authentication (Sign in with Apple + CloudKit)
- [ ] Profile creation with photos (stored in CloudKit)
- [ ] Language selection UI
- [ ] Simple matching algorithm (CloudKit queries)
- [ ] Basic chat interface (Core Data + CloudKit backup)
- [ ] Google Translate API integration
- [ ] TestFlight beta

### Phase 2: Real-time & External Services (Weeks 7-12)
- [ ] Socket.io or Firebase integration for real-time chat
- [ ] Swipe gestures for translation panes
- [ ] AI-powered suggestions via OpenRouter
- [ ] Invite link system with Universal Links
- [ ] Push notifications (APNS + custom server)
- [ ] StoreKit integration with receipt validation
- [ ] Cultural context features
- [ ] CloudKit sync for offline support

### Phase 3: Polish & Launch (Weeks 13-16)
- [ ] UI animations and transitions
- [ ] Performance optimization (caching, pagination)
- [ ] CloudKit conflict resolution
- [ ] Comprehensive testing across devices
- [ ] App Store submission
- [ ] Marketing website
- [ ] Press kit preparation

### Phase 4: Post-Launch Scaling (Weeks 17+)
- [ ] Migrate heavy traffic features from CloudKit to custom backend
- [ ] User feedback integration
- [ ] A/B testing framework
- [ ] Analytics implementation (Firebase/Mixpanel)
- [ ] Feature iterations based on usage
- [ ] Android development start
- [ ] Consider dedicated backend for scale

## Testing Strategy

### Unit Tests
```swift
// Test coverage targets:
// - Models: 90%
// - ViewModels: 80%
// - Services: 85%
// - Utilities: 95%
```

### UI Tests
```swift
// Critical user journeys:
// - Onboarding flow
// - Matching and swiping
// - Sending first message
// - Purchasing subscription
// - Inviting a friend
```

### Beta Testing
- **TestFlight**: 100 initial testers
- **Focus Groups**: Language learners, travelers
- **A/B Tests**: Onboarding variants, pricing

## Analytics & Metrics

### Firebase Analytics Integration
```swift
// Key events to track:
Analytics.logEvent("user_signed_up", parameters: [:])
Analytics.logEvent("profile_completed", parameters: [:])
Analytics.logEvent("first_match", parameters: [:])
Analytics.logEvent("first_message_sent", parameters: [:])
Analytics.logEvent("translation_revealed", parameters: [:])
Analytics.logEvent("subscription_started", parameters: [:])
Analytics.logEvent("invite_sent", parameters: [:])
```

## Security Considerations

### Data Protection
- **Keychain**: API keys, tokens
- **Core Data Encryption**: Local message cache
- **Certificate Pinning**: API communication
- **Biometric Authentication**: Optional app lock

### Privacy
- **Photo Access**: Only when needed
- **Location**: Optional, coarse only
- **Contacts**: Never required
- **IDFA**: Not collected

## Launch Checklist

### Pre-Launch
- [ ] App Store Connect setup
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] Support URL
- [ ] App screenshots (6.5", 5.5")
- [ ] App preview video
- [ ] Keywords research
- [ ] Description optimization

### Technical Requirements
- [ ] Push notification certificates (APNS)
- [ ] CloudKit container configuration
- [ ] Universal Links configuration
- [ ] App Transport Security settings
- [ ] Background modes configuration
- [ ] CloudKit entitlements
- [ ] Sign in with Apple capability

### Marketing Assets
- [ ] App icon variations
- [ ] Launch screen
- [ ] Onboarding graphics
- [ ] Social media templates
- [ ] Press release draft

## Support & Maintenance

### Customer Support
- **In-app**: Help center, FAQ
- **Email**: support@langmatcher.com
- **Response Time**: <24 hours

### Update Cadence
- **Bug fixes**: Bi-weekly
- **Feature updates**: Monthly
- **Major releases**: Quarterly

## Success Metrics

### Launch Goals (Month 1)
- 10,000 downloads
- 1,000 paying subscribers
- 4.5+ App Store rating
- 500 daily active users

### Growth Goals (Month 6)
- 100,000 downloads
- 10,000 paying subscribers
- 20% monthly growth rate
- 50% day-7 retention

## Risk Mitigation

### Technical Risks
- **API Rate Limits**: Implement caching, queuing
- **Translation Quality**: User feedback system
- **Server Costs**: Progressive pricing model

### App Store Risks
- **Rejection**: Review guidelines thoroughly
- **Competition**: Unique AI features
- **Discovery**: ASO optimization

## Conclusion

LangMatcher as an iOS app leverages native capabilities for the best user experience. The swipe-based interface, real-time messaging, and AI-powered translations create a unique value proposition in the language learning space. Focus on viral growth through invite links and social proof will drive organic acquisition while keeping costs manageable.