# Authentication Overview

This document provides a high-level map of every authentication scenario in LangChat, how credentials flow, and where state is stored.

## Master Auth Flow — App Launch

```mermaid
flowchart TD
    A[App Launch - SceneDelegate] --> B[showLoadingScreen]
    B --> C[checkConnectivityAndProceed]
    C --> D{NetworkMonitor: Supabase reachable?}
    D -->|No| E[OfflineViewController]
    D -->|Yes| F[proceedWithAppFlow]
    F --> G[SupabaseService.restoreSession]
    G --> H{client.auth.session valid?}
    H -->|Yes — session restored| I{hasCompletedProfile?}
    H -->|No — no session| M{First-time user?}

    I -->|Yes| J[syncProfileToUserDefaults]
    J --> K[Process pending invite codes]
    K --> L[MainTabBarController]
    I -->|No — incomplete profile| O[OnboardingCoordinator.start]
    I -->|Network error| E

    M -->|Yes — shouldShowWelcomeScreen| N[OnboardingCarouselViewController]
    M -->|No — returning user| P[AuthenticationViewController]
    N -->|Get Started| P

    P --> Q{User chooses auth method}
    Q -->|Apple Sign In| R[Apple Sign In Flow]
    Q -->|Email Sign In| S[Email Sign In Flow]
    Q -->|Email Sign Up| T[Email Sign Up Flow]
    Q -->|Debug Quick Login| U[Debug Auth Flow]

    R --> V{hasCompletedProfile?}
    S --> V
    T --> V
    U --> V

    V -->|Yes| L
    V -->|No| O

    O --> W[20-step onboarding wizard]
    W --> X[PricingViewController]
    X --> Y[syncOnboardingDataToSupabase]
    Y --> Z[Upload profile photos]
    Z --> L
```

## Key Decision Points

| Decision | Where | Logic |
|----------|-------|-------|
| Network available? | `SceneDelegate.checkConnectivityAndProceed` | `NetworkMonitor` pings Supabase URL |
| Session valid? | `SupabaseService.restoreSession` | Supabase SDK loads persisted session, auto-refreshes expired tokens |
| Profile complete? | `SupabaseService.hasCompletedProfile` | Checks `firstName`, `nativeLanguage`, `learningLanguages` exist in Supabase |
| First-time user? | `UserEngagementTracker.shouldShowWelcomeScreen` | Checks UserDefaults flags for prior engagement |

## File Reference

| File | Role |
|------|------|
| `SceneDelegate.swift` | App launch routing, auth state check |
| `Core/Services/SupabaseService.swift` | All Supabase auth methods, session restore, profile sync |
| `Core/Services/SignInWithAppleService.swift` | Native Apple credential acquisition |
| `Core/Config.swift` | Supabase URL & anon key from Info.plist |
| `Features/Authentication/AuthenticationViewController.swift` | Primary auth screen (Apple + Email) |
| `Features/Onboarding/LandingViewController.swift` | Legacy auth screen (same methods) |
| `Features/Onboarding/OnboardingCarouselViewController.swift` | First-time carousel → pushes to auth |
| `Features/Onboarding/WelcomeViewController.swift` | Feature showcase → pushes to auth |
| `Features/Onboarding/OnboardingCoordinator.swift` | Post-auth onboarding wizard |
| `Core/Services/UserEngagementTracker.swift` | Tracks first-time vs returning user |
