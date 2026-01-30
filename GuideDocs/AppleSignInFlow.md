# Apple Sign In Flow

Detailed walkthrough of Sign in with Apple — from button tap to authenticated session.

## End-to-End Flow

```mermaid
sequenceDiagram
    participant User
    participant AuthVC as AuthenticationViewController
    participant SupaSvc as SupabaseService
    participant AppleSvc as SignInWithAppleService
    participant Apple as Apple ID Servers
    participant Supabase as Supabase Auth

    User->>AuthVC: Taps "Sign in with Apple"
    AuthVC->>SupaSvc: signInWithApple(from: window)

    Note over SupaSvc: Sets presentingWindow on AppleSvc

    SupaSvc->>AppleSvc: signIn(from: window)

    Note over AppleSvc: Generate 32-char random nonce<br/>SHA256 hash for Apple request<br/>Keep raw nonce for Supabase

    AppleSvc->>Apple: ASAuthorizationController.performRequests()<br/>(scopes: fullName, email)
    Apple->>User: System Apple ID prompt (Face ID / password)
    User->>Apple: Authorizes

    alt First-ever Apple Sign In for this app
        Apple-->>AppleSvc: Returns idToken + email + fullName
    else Subsequent sign-ins
        Apple-->>AppleSvc: Returns idToken only (no name/email)
    end

    AppleSvc->>AppleSvc: Extract idToken JWT string from credential
    AppleSvc-->>SupaSvc: AppleSignInResult(idToken, nonce, userID, email?, fullName?)

    Note over SupaSvc: Cache Apple-provided name/email<br/>in UserDefaults (keys:<br/>appleProvidedFirstName,<br/>appleProvidedLastName,<br/>appleProvidedEmail)<br/>— Only available on first sign-in

    SupaSvc->>Supabase: signInWithIdToken(<br/>provider: .apple,<br/>idToken: idToken,<br/>nonce: rawNonce)

    Supabase->>Apple: Validates idToken JWT
    Apple-->>Supabase: Token valid

    alt New user
        Supabase->>Supabase: Creates auth.users row
    else Existing user
        Supabase->>Supabase: Matches existing user by Apple sub
    end

    Supabase-->>SupaSvc: Session (access_token + refresh_token)

    Note over SupaSvc: Supabase SDK persists session<br/>internally (tokens stored by SDK)

    SupaSvc-->>AuthVC: Success
    AuthVC->>AuthVC: Store userId in UserDefaults
    AuthVC->>SupaSvc: hasCompletedProfile()?

    alt Profile exists and is complete
        AuthVC->>AuthVC: Navigate to MainTabBarController
    else No profile or incomplete
        AuthVC->>AuthVC: Start OnboardingCoordinator
    end
```

## Nonce Security Detail

```mermaid
flowchart LR
    A[Generate 32-char<br/>random string] --> B[Store raw nonce<br/>in memory]
    A --> C[SHA256 hash]
    C --> D[Send hash to Apple<br/>in ASAuthorizationRequest]
    B --> E[Send raw nonce to Supabase<br/>with idToken]
    D --> F[Apple embeds hash<br/>in returned idToken JWT]
    E --> G[Supabase hashes raw nonce,<br/>compares to JWT claim]
    F --> G
    G --> H{Match?}
    H -->|Yes| I[Auth succeeds — replay attack prevented]
    H -->|No| J[Auth rejected]
```

## Apple's First-Sign-In Data Problem

```mermaid
flowchart TD
    A[User taps Sign in with Apple] --> B{Ever signed in<br/>to this app before?}
    B -->|No — first time| C[Apple provides:<br/>idToken + email + fullName]
    B -->|Yes — subsequent| D[Apple provides:<br/>idToken ONLY]

    C --> E[SupabaseService caches to UserDefaults:<br/>appleProvidedFirstName<br/>appleProvidedLastName<br/>appleProvidedEmail]
    E --> F[OnboardingCoordinator skips<br/>name input step]

    D --> G[App reads cached name<br/>from UserDefaults if available]
    G --> H{Cache exists?}
    H -->|Yes| I[Pre-fill name fields]
    H -->|No — e.g. reinstall| J[User must enter name manually]
```

## Error Handling

```mermaid
flowchart TD
    A[Apple Sign In attempt] --> B{Result}
    B -->|Success| C[Continue to Supabase auth]
    B -->|userCancelled| D[Silently dismiss — no error shown]
    B -->|invalidCredential| E[Show alert: Invalid credentials]
    B -->|missingIdentityToken| E
    B -->|invalidIdentityToken| E
    B -->|missingNonce| E
    B -->|authorizationFailed| F[Show alert with error details]
    B -->|notHandled| F
    B -->|unknown| F

    C --> G{Supabase responds}
    G -->|Success| H[Proceed to profile check]
    G -->|Error| I[Show alert: Sign in failed + error message]
```

## Key Implementation Details

- **Singleton:** `SignInWithAppleService.shared` — reused across AuthenticationVC and LandingVC
- **Async/Await bridge:** Uses `withCheckedThrowingContinuation` to convert delegate callbacks to async
- **Window anchor:** Uses stored `presentingWindow` with fallbacks — critical for iPad multi-window
- **No Keychain usage:** App code does not directly touch Keychain; the Supabase SDK handles token persistence internally
