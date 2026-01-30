# Session Restore & Returning User Flows

How the app handles users coming back — cold launch, warm launch, and edge cases.

## Cold Launch — Returning Authenticated User

```mermaid
sequenceDiagram
    participant iOS as iOS System
    participant SD as SceneDelegate
    participant NM as NetworkMonitor
    participant SS as SupabaseService
    participant SDK as Supabase SDK
    participant Remote as Supabase Server

    iOS->>SD: scene(_:willConnectTo:)
    SD->>SD: showLoadingScreen()
    SD->>SD: checkConnectivityAndProceed()
    SD->>NM: checkSupabaseConnectivity()

    NM->>Remote: HEAD request to Supabase URL
    Remote-->>NM: 200 OK

    NM-->>SD: Connected

    SD->>SS: restoreSession()
    SS->>SDK: client.auth.session
    SDK->>SDK: Load persisted tokens
    SDK-->>SS: Session restored (currentUser exists)

    SD->>SD: isAuthenticated = true
    SD->>SS: hasCompletedProfile()
    SS->>Remote: Query profiles table for user
    Remote-->>SS: Profile data

    alt Profile has firstName + nativeLanguage + learningLanguages
        SS-->>SD: true
        SD->>SS: syncProfileToUserDefaults()
        SS->>Remote: Fetch full profile
        Remote-->>SS: Profile fields
        SS->>SS: Write to UserDefaults
        SD->>SD: processInviteCodeIfNeeded()
        SD->>SD: showMainApp() → MainTabBarController
    else Missing required fields
        SS-->>SD: false
        SD->>SD: showOnboarding() → OnboardingCoordinator
    end
```

## Cold Launch — Session Expired

```mermaid
sequenceDiagram
    participant SD as SceneDelegate
    participant SS as SupabaseService
    participant SDK as Supabase SDK
    participant Remote as Supabase Server

    SD->>SS: restoreSession()
    SS->>SDK: client.auth.session
    SDK->>SDK: Load tokens — access_token expired
    SDK->>Remote: Attempt token refresh

    alt Refresh token still valid
        Remote-->>SDK: New tokens
        SDK-->>SS: Session restored
        SS-->>SD: isAuthenticated = true
        SD->>SD: Continue to profile check...
    else Refresh token expired
        Remote-->>SDK: 401 Unauthorized
        SDK-->>SS: Error — no session
        SS-->>SD: isAuthenticated = false
        SD->>SD: showAuthenticationFlow()
    end
```

## Cold Launch — No Network

```mermaid
flowchart TD
    A[App Launch] --> B[checkConnectivityAndProceed]
    B --> C{NetworkMonitor:<br/>Supabase reachable?}
    C -->|No| D[OfflineViewController]
    D --> E["Retry" button]
    E --> B

    C -->|Yes| F[proceedWithAppFlow]
    F --> G[restoreSession]
    G --> H{hasCompletedProfile?}
    H -->|Network error<br/>during profile check| D
```

## First-Time User vs Returning User

```mermaid
flowchart TD
    A[No valid session] --> B{UserEngagementTracker<br/>shouldShowWelcomeScreen}

    B -->|true — never seen app before| C[OnboardingCarouselViewController<br/>4-page feature carousel]
    C --> D["Get Started" button]
    D --> E[AuthenticationViewController]

    B -->|false — has opened app before| E

    E --> F{User authenticates}
    F --> G{hasCompletedProfile?}
    G -->|Yes — they signed out<br/>and signed back in| H[MainTabBarController]
    G -->|No — they started but<br/>didn't finish onboarding| I[OnboardingCoordinator<br/>resumes from beginning]
```

## App Foregrounded (Warm Launch)

```mermaid
flowchart TD
    A[sceneDidBecomeActive] --> B{Already showing<br/>main app?}
    B -->|Yes| C[NetworkMonitor continues<br/>background monitoring]
    B -->|No — still on loading/auth| D[No action — user<br/>continues where they were]

    C --> E{Connection lost?}
    E -->|Yes| F[NetworkMonitor posts<br/>.connectivityChanged notification]
    F --> G[App can show offline banner]
    E -->|No| H[Normal operation]
```

## Debug: Force Onboarding Reset

```mermaid
flowchart TD
    A["DebugConfig.forceOnboardingReset = true"] --> B[SceneDelegate detects flag]
    B --> C[Clear UserDefaults<br/>— preserves Apple name cache]
    C --> D[Sign out from Supabase]
    D --> E[Show OnboardingCoordinator<br/>from step 1]

    style A fill:#8b0000,color:#fff
```

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| User reinstalls app | SDK tokens lost → no session → auth screen. Apple name cache also lost — user must re-enter name in onboarding. |
| User revokes Apple ID access | Next token refresh fails → session invalid → auth screen. User can re-authorize or use email. |
| Supabase down at launch | NetworkMonitor detects failure → OfflineViewController with retry. |
| Profile deleted server-side | `hasCompletedProfile` returns false → sent to onboarding to rebuild profile. |
| User signed up but closed app during onboarding | Session exists but profile incomplete → sent to OnboardingCoordinator on next launch. |
