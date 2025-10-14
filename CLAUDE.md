# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LangChat (LangMatcher) is an iOS native app for language exchange and learning through matched conversations. The app uses a swipe-based matching interface similar to dating apps, but focused on connecting language learners with native speakers for practice.

## Key Documentation

- **Product Requirements**: [PRD.md](./PRD.md) - Complete product specifications, UI/UX requirements, monetization strategy, and implementation examples
- **Database Architecture**: [DBApproach.md](./DBApproach.md) - Comprehensive database and storage implementation guide using:
  - **Supabase**: Primary backend (PostgreSQL with real-time capabilities)
  - **Core Data**: Local iOS storage for offline support and caching
  - **CloudKit**: Apple cloud storage for user-owned data and photos

## Development Commands

### Build and Run
```bash
# Build the project
xcodebuild -project LangChat.xcodeproj -scheme LangChat -configuration Debug build

# Run on iOS Simulator
xcodebuild -project LangChat.xcodeproj -scheme LangChat -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild -project LangChat.xcodeproj -scheme LangChat clean
```

### Testing
```bash
# Run unit tests
xcodebuild test -project LangChat.xcodeproj -scheme LangChat -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project LangChat.xcodeproj -scheme LangChatUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Swift Package Manager (if packages are added)
```bash
# Resolve dependencies
xcodebuild -resolvePackageDependencies -project LangChat.xcodeproj

# Update packages
xcodebuild -project LangChat.xcodeproj -scheme LangChat -resolvePackageDependencies
```

## Architecture Overview

### Current State
The project is in initial setup phase with:
- Basic UIKit structure (AppDelegate, SceneDelegate, ViewController)
- Core Data model (`LangChat.xcdatamodeld`)
- CloudKit entitlements configured
- Push notifications enabled (development environment)
- Storyboard-based UI (Main.storyboard)

### Target Architecture (see PRD.md for full details)
The app will follow an MVVM-C (Model-View-ViewModel-Coordinator) pattern with:

1. **Hybrid UI Approach**: UIKit for navigation and complex gestures, SwiftUI for modern UI components
2. **CloudKit Integration**: Primary backend for user profiles, preferences, and data sync
3. **External Services**: Real-time messaging via Socket.IO/Firebase, translation APIs via OpenRouter/Google
4. **Reactive Programming**: Combine framework for data binding and async operations

### Key Components to Implement

Refer to PRD.md for detailed implementation examples and code snippets for:

1. **Matching System**: Swipeable card interface for user matching (see PRD.md section "Matching Interface")
2. **Chat Interface**: Multi-pane messaging with swipeable translation views (see PRD.md section "Chat Interface with Swipeable Messages")
3. **User Profiles**: CloudKit-backed profile management with language preferences (see PRD.md "Data Architecture" section)
4. **Translation Service**: AI-powered message translation with grammar insights (see PRD.md "AI Integration Architecture")
5. **Subscription Management**: StoreKit 2 integration for premium features (see PRD.md "Monetization Implementation")

## Project Structure

The PRD.md outlines the following directory structure to implement:
```
LangChat/
├── App/                     # App lifecycle and configuration
├── Core/                    # Models, networking, services
├── Features/               # Feature modules (Onboarding, Matching, Chat, etc.)
├── Resources/              # Assets, localization, fonts
└── Tests/                  # Unit and UI tests
```

## Key Technical Considerations

### CloudKit Setup
- Container identifier should be: `iCloud.com.langmatcher.app` (or your bundle ID)
- Requires both private and public database access
- Used for user profiles, match history, saved phrases, and message backup

### Real-time Messaging
- Implement Socket.IO or Firebase for instant messaging
- Maintain local Core Data cache for offline access
- Sync to CloudKit for cross-device backup

### Translation Integration
- Primary: Google Translate API for basic translations
- Enhanced: OpenRouter API for context and grammar insights
- Implement caching layer to reduce API calls

### Security
- API keys must be stored in Keychain, never in code
- Implement certificate pinning for API communication
- Use CloudKit for secure data storage

### Performance
- Image caching for profile photos (SDWebImage recommended)
- Message pagination (load 50 at a time)
- Lazy loading for match cards
- Background fetch for new messages

## Development Priorities

Based on the phases defined in PRD.md:

1. **Phase 1 (MVP)**: Focus on CloudKit setup, basic auth, profile creation, and simple chat
2. **Phase 2**: Add real-time features, swipe gestures, AI translations
3. **Phase 3**: Polish UI, optimize performance, prepare for App Store
4. **Phase 4**: Post-launch improvements based on user feedback

## Testing Requirements

- Unit test coverage targets: Models (90%), ViewModels (80%), Services (85%)
- Critical UI test flows: Onboarding, matching, first message, subscription purchase
- Use TestFlight for beta testing with 100+ initial testers

## App Store Preparation

- Bundle ID: Use reverse domain (e.g., `com.yourcompany.langchat`)
- Deployment target: iOS 16.0+
- Required capabilities: CloudKit, Push Notifications, Sign in with Apple
- Privacy requirements: Clear photo library and notification permissions