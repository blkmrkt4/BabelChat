# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fluenca** (codebase name: LangChat) is a completed MVP iOS native app for language exchange, published by PainKiller Labs. Users swipe through profiles to match with language partners, chat with built-in translation and grammar analysis, and practice with AI conversation partners (Muses). The app is localized into 22 languages via `Localizable.xcstrings` with runtime bundle switching (`LocalizationService`).

## Key Documentation

- **Product Requirements**: [PRD.md](./PRD.md) — Product specifications, UI/UX requirements, monetization strategy
- **Database Architecture**: [DBApproach.md](./DBApproach.md) — Database implementation guide (Supabase as sole backend; UserDefaults for local state)
- **Auth Flow Guides** (`GuideDocs/`):
  - [AuthOverview.md](./GuideDocs/AuthOverview.md) — Master auth flow from app launch
  - [AppleSignInFlow.md](./GuideDocs/AppleSignInFlow.md) — Apple Sign In with nonce security
  - [EmailSignInFlow.md](./GuideDocs/EmailSignInFlow.md) — Email auth + comparison to Apple
  - [CredentialStorage.md](./GuideDocs/CredentialStorage.md) — Where tokens/credentials live
  - [SessionRestoreAndReturningUser.md](./GuideDocs/SessionRestoreAndReturningUser.md) — Returning user flows
  - [SignOutAndAccountDeletion.md](./GuideDocs/SignOutAndAccountDeletion.md) — Sign out vs account deletion

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

### Swift Package Manager
```bash
# Resolve dependencies
xcodebuild -resolvePackageDependencies -project LangChat.xcodeproj

# Update packages
xcodebuild -project LangChat.xcodeproj -scheme LangChat -resolvePackageDependencies
```

## Architecture Overview

- **Pattern**: MVC with one Coordinator (`OnboardingCoordinator`) and one ViewModel (`MatchCardViewModel`). Not MVVM-C.
- **UI**: Programmatic UIKit throughout (95+ view controllers). One SwiftUI view (`OnboardingRippleBackground`) embedded via `UIHostingController`. No storyboards used beyond the Xcode template.
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Realtime). No CloudKit or Core Data usage.
- **Async**: Swift `async/await` + `NotificationCenter`. No Combine.
- **Real-time**: Supabase Realtime (WebSocket-based Postgres changes) for messaging.
- **Translation**: OpenRouter API routing to LLMs for translation, grammar analysis, and scoring. No Google Translate.
- **TTS**: Google Cloud TTS (Neural2/Chirp) for premium tiers, `AVSpeechSynthesizer` for free tier.
- **Image caching**: Custom `ImageService` with `NSCache` + `URLSession`. No third-party image libraries.
- **Subscriptions**: RevenueCat (`purchases-ios` v5.51.0). Not direct StoreKit 2.
- **Crash reporting**: Sentry SDK v9.1.0.
- **Local storage**: UserDefaults for auth state, profile cache, engagement flags. No Core Data entities in use.

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| supabase-swift | 2.35.0 | Auth, database, storage, realtime |
| purchases-ios (RevenueCat) | 5.51.0 | In-app purchases / subscriptions |
| sentry-cocoa | 9.1.0 | Crash reporting |

## Project Structure

```
LangChat/
├── AppDelegate.swift / SceneDelegate.swift
├── Core/
│   ├── Config.swift, Config/DebugConfig.swift
│   ├── Controllers/MainTabBarController.swift
│   ├── Models/              (15 models: User, Match, Message, Language, AIModel, etc.)
│   ├── Services/            (18 services — see Key Services below)
│   └── Views/               (Shared UI components)
├── Features/
│   ├── AISetup/             AI model config & testing
│   ├── Authentication/      Sign in with Apple + Email
│   ├── Chat/                Messaging with swipeable translation/grammar
│   ├── Debug/               Supabase test tools
│   ├── LanguageLab/         Learning analytics dashboard
│   ├── Matching/            Swipe cards, match list, profiles
│   ├── Offline/             Offline state with auto-retry
│   ├── Onboarding/          20-step wizard + coordinator
│   ├── Profile/             16 view controllers for profile/settings
│   ├── Subscription/        Upgrade prompts
│   └── Tutorial/            Multi-page tutorial
├── Legal/                   Privacy Policy, ToS, EULA, Community Guidelines, Licenses
├── Resources/               Localizable.xcstrings (22 languages, 1050+ keys)
GuideDocs/                   Auth flow documentation (Mermaid diagrams)
supabase/migrations/         26 migration files
web-admin/                   Next.js admin dashboard
scripts/                     Security hooks, localization tools
```

## Key Services

Services in `Core/Services/` with brief descriptions:

- **SupabaseService** — Central backend: auth, profiles, matching, chat, storage
- **OpenRouterService** — AI translation, grammar analysis, scoring via LLMs
- **SignInWithAppleService** — Native Apple credential acquisition
- **SubscriptionService** — RevenueCat IAP management
- **TTSService** — Text-to-speech (Google Cloud TTS + Apple native fallback)
- **ImageService** — Photo loading with NSCache
- **NetworkMonitor** — Supabase connectivity monitoring
- **LocalizationService** — Runtime language bundle switching
- **AIConfigService** — Remote AI model/prompt configuration
- **AIConfigurationManager** — Local AI configuration coordination
- **ContentFilterService** — UGC profanity filtering
- **CrashReportingService** — Sentry integration
- **UserEngagementTracker** — First-time vs returning user detection
- **AnalyticsService** — Event tracking
- **MatchingService** — Match algorithm and swipe logic
- **LanguageLabStatsService** — Learning progress statistics
- **PushNotificationService** — APNs registration and handling
- **UsageLimitService** — Free-tier usage cap enforcement

## Subscription Tiers

| Feature | Free | Premium ($9.99/mo) | Pro ($19.99/mo) |
|---------|------|---------------------|-----------------|
| Daily swipes | Limited | Unlimited | Unlimited |
| Translation | Limited | Unlimited | Unlimited |
| Grammar analysis | — | Basic | Advanced |
| TTS voices | Apple native | Google Neural2 | Google Chirp |
| Muse conversations | Limited | Extended | Unlimited |
| Photo blur reveal | — | Yes | Yes |
| Priority matching | — | — | Yes |

## Onboarding Flow

20-step onboarding wizard managed by `OnboardingCoordinator` with conditional step skipping. Steps include: name, birthday, location, native language, learning languages, proficiency levels, matching preferences, dating preferences, relationship intent, age range, proficiency range, location preference, travel plans, bio, profile photo, privacy preferences, Muse language selection, notifications permission, pricing, and welcome.

## Security

- API keys stored in `Secrets.xcconfig` → `Info.plist` at runtime. Not in Keychain.
- Pre-commit hook blocks secret commits (`scripts/pre-commit-hook.sh`).
- No certificate pinning implemented.
- Supabase SDK handles token persistence internally.
- Content filtering for UGC compliance (Apple Guideline 1.2).
- Account deletion fully cascades (11 tables + storage + `auth.users` via `SECURITY DEFINER` RPC).

## Web Admin Dashboard

Next.js admin app at `web-admin/` for managing the live product:
- AI model management, evaluation, and round-robin config
- Content moderation and user management (bans, reports)
- Localization editor with export/import
- Pricing configuration (per-country, weekly/monthly)
- TTS voice configuration
- Monitoring and support tools

## Testing

- No automated tests currently (Xcode template placeholders only).
- In-app debug tools: `SupabaseTestViewController`, `TestDataGenerator`, debug quick login.

## App Store

- Published by **PainKiller Labs** as **Fluenca**
- Deployment target: iOS 16.0
- Required capabilities: Push Notifications, Sign in with Apple
- Minimum user age: 18
