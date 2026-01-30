# Credential & Session Storage

Where and how authentication state, tokens, and user data are persisted.

## Storage Architecture

```mermaid
flowchart TD
    subgraph app ["LangChat App Code"]
        UD[UserDefaults]
        SS[SupabaseService]
    end

    subgraph sdk ["Supabase Swift SDK — Internal"]
        SDK_Store[SDK Internal Storage<br/>— manages tokens automatically]
    end

    subgraph system ["iOS System"]
        KC[Keychain<br/>— used by SDK, not by app directly]
    end

    subgraph remote ["Remote"]
        SB_Auth[Supabase auth.users table]
        Apple[Apple ID Servers]
    end

    SS -->|Calls client.auth methods| SDK_Store
    SDK_Store -->|Persists tokens| KC
    SDK_Store <-->|Auth API calls| SB_Auth
    SS -->|signInWithIdToken| SB_Auth
    SB_Auth -->|Validates idToken| Apple
    SS -->|Caches user data| UD
```

## What Is Stored Where

```mermaid
flowchart LR
    subgraph userdefaults ["UserDefaults (App-managed)"]
        direction TB
        UD1["userId — UUID string"]
        UD2["isUserSignedIn — bool"]
        UD3["onboardingCompleted — bool"]
        UD4["appleProvidedFirstName"]
        UD5["appleProvidedLastName"]
        UD6["appleProvidedEmail"]
        UD7["firstName, lastName, email, bio"]
        UD8["profileSynced — bool"]
        UD9["hasSeenWelcomeScreen"]
        UD10["hasCompletedOnboarding"]
    end

    subgraph sdk_internal ["Supabase SDK Internal"]
        direction TB
        SK1["access_token (JWT)"]
        SK2["refresh_token"]
        SK3["token expiry timestamp"]
        SK4["user metadata"]
    end

    subgraph supabase_remote ["Supabase Remote (auth.users)"]
        direction TB
        SB1["id (UUID)"]
        SB2["email"]
        SB3["encrypted_password<br/>(email users only)"]
        SB4["provider (apple / email)"]
        SB5["app_metadata"]
        SB6["last_sign_in_at"]
    end

    subgraph not_used ["NOT Used by App Code"]
        direction TB
        NU1["Keychain — no direct access"]
        NU2["Core Data — not for auth"]
        NU3["CloudKit — not for auth"]
    end
```

## Session Lifecycle

```mermaid
stateDiagram-v2
    [*] --> NoSession: App installed / data cleared

    NoSession --> Authenticating: User taps sign-in
    Authenticating --> ActiveSession: Auth succeeds
    Authenticating --> NoSession: Auth fails / cancelled

    ActiveSession --> ActiveSession: App foregrounded<br/>(restoreSession — token still valid)
    ActiveSession --> TokenRefresh: App foregrounded<br/>(access_token expired)
    TokenRefresh --> ActiveSession: Refresh succeeds<br/>(SDK handles automatically)
    TokenRefresh --> NoSession: Refresh token also expired<br/>(user must re-authenticate)

    ActiveSession --> NoSession: User signs out
    ActiveSession --> NoSession: User deletes account<br/>(auth.users row also deleted)
    ActiveSession --> NoSession: Debug "Reset All Data"

    note right of ActiveSession
        Supabase SDK stores:
        - access_token (short-lived JWT)
        - refresh_token (long-lived)
        SDK auto-refreshes transparently
    end note

    note right of NoSession
        App checks on every launch:
        SceneDelegate → restoreSession()
        If no valid session → auth screen
    end note
```

## Token Refresh — Handled by SDK

```mermaid
sequenceDiagram
    participant App as SceneDelegate
    participant SupaSvc as SupabaseService
    participant SDK as Supabase SDK
    participant Remote as Supabase Auth Server

    App->>SupaSvc: restoreSession()
    SupaSvc->>SDK: client.auth.session

    SDK->>SDK: Load persisted tokens from internal storage

    alt Access token still valid
        SDK-->>SupaSvc: Returns session with current user
    else Access token expired, refresh token valid
        SDK->>Remote: POST /token?grant_type=refresh_token
        Remote-->>SDK: New access_token + refresh_token
        SDK->>SDK: Persist new tokens
        SDK-->>SupaSvc: Returns refreshed session
    else Both tokens expired/invalid
        SDK-->>SupaSvc: Throws error (no valid session)
        SupaSvc-->>App: isAuthenticated = false
        App->>App: Show auth screen
    end
```

## Sign Out & Account Deletion — Data Cleanup

```mermaid
flowchart TD
    subgraph signout ["Sign Out (SettingsViewController)"]
        SO1[User taps Sign Out] --> SO2[SupabaseService.signOut]
        SO2 --> SO3[client.auth.signOut]
        SO3 --> SO4[SDK clears persisted tokens]
        SO2 --> SO5[Clear UserDefaults keys]
        SO5 --> SO6[Show auth screen]
    end

    subgraph delete ["Delete Account (SettingsViewController)"]
        DA1[User taps Delete Account] --> DA2[Confirmation alert]
        DA2 --> DA3[SupabaseService.deleteAccount]
        DA3 --> DA4[Delete from Supabase tables:<br/>messages, conversations,<br/>reported_users, muse_interactions,<br/>feedback, matches, swipes,<br/>user_languages, user_preferences,<br/>invites, profiles]
        DA4 --> DA5[Delete storage photos]
        DA5 --> DA6[Sign out via client.auth.signOut]
        DA6 --> DA7[Clear all local data]
        DA7 --> DA8[Show auth screen]
    end
```

## Security Observations

| Aspect | Current State | Notes |
|--------|--------------|-------|
| Token storage | Supabase SDK internal (likely Keychain) | App does not directly manage tokens |
| Password storage | Supabase server-side only | Never stored locally |
| Apple idToken | Transient — used once during auth, not persisted | Nonce prevents replay attacks |
| UserDefaults data | Unencrypted | Contains userId, name, email — not secrets, but PII |
| API keys | In Info.plist via Secrets.xcconfig | xcconfig not checked into git |
| Custom Keychain usage | None | App relies entirely on SDK for secure storage |
| Certificate pinning | Not implemented | Noted in CLAUDE.md as desired |
