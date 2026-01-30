# Email Sign In & Sign Up Flow

Detailed walkthrough of email/password authentication — sign in, sign up, and magic link paths.

## Email Sign In Flow

```mermaid
sequenceDiagram
    participant User
    participant AuthVC as AuthenticationViewController
    participant SupaSvc as SupabaseService
    participant Supabase as Supabase Auth

    User->>AuthVC: Taps "Sign in with Email"
    AuthVC->>AuthVC: Show action sheet:<br/>"Sign In" or "Create Account"
    User->>AuthVC: Selects "Sign In"
    AuthVC->>AuthVC: Show UIAlertController<br/>(email + password text fields)
    User->>AuthVC: Enters email & password, taps Sign In

    AuthVC->>SupaSvc: signIn(email:, password:)
    SupaSvc->>Supabase: client.auth.signIn(email:, password:)

    Supabase->>Supabase: Verify credentials against auth.users

    alt Valid credentials
        Supabase-->>SupaSvc: Session (access_token + refresh_token)
        Note over SupaSvc: SDK persists session internally
        SupaSvc-->>AuthVC: Success
        AuthVC->>AuthVC: Store userId in UserDefaults
        AuthVC->>SupaSvc: hasCompletedProfile()?
        alt Profile complete
            AuthVC->>AuthVC: Navigate to MainTabBarController
        else Profile incomplete
            AuthVC->>AuthVC: Start OnboardingCoordinator
        end
    else Invalid credentials
        Supabase-->>SupaSvc: Error (invalid_grant, etc.)
        SupaSvc-->>AuthVC: Throws error
        AuthVC->>AuthVC: Show alert with error message
    end
```

## Email Sign Up Flow

```mermaid
sequenceDiagram
    participant User
    participant AuthVC as AuthenticationViewController
    participant SupaSvc as SupabaseService
    participant Supabase as Supabase Auth

    User->>AuthVC: Taps "Sign in with Email"
    AuthVC->>AuthVC: Show action sheet:<br/>"Sign In" or "Create Account"
    User->>AuthVC: Selects "Create Account"
    AuthVC->>AuthVC: Show UIAlertController<br/>(email + password text fields)
    User->>AuthVC: Enters email & password, taps Create

    AuthVC->>SupaSvc: signUp(email:, password:)
    SupaSvc->>Supabase: client.auth.signUp(email:, password:)

    alt Email not taken
        Supabase->>Supabase: Create auth.users row
        Supabase-->>SupaSvc: Session (auto-signed-in)
        Note over SupaSvc: SDK persists session internally
        SupaSvc-->>AuthVC: Success
        AuthVC->>AuthVC: Store userId in UserDefaults
        AuthVC->>AuthVC: Start OnboardingCoordinator<br/>(new user — no profile yet)
    else Email already registered
        Supabase-->>SupaSvc: Error
        SupaSvc-->>AuthVC: Throws error
        AuthVC->>AuthVC: Show alert with error message
    end
```

## Magic Link Flow (Available in SupabaseService, not exposed in current UI)

```mermaid
sequenceDiagram
    participant User
    participant App as LangChat App
    participant SupaSvc as SupabaseService
    participant Supabase as Supabase Auth
    participant Email as User's Email

    App->>SupaSvc: sendMagicLink(email:)
    SupaSvc->>Supabase: client.auth.signInWithOTP(email:)
    Supabase->>Email: Sends email with OTP code

    Email->>User: Receives OTP code
    User->>App: Enters OTP code

    App->>SupaSvc: verifyOTP(email:, token:)
    SupaSvc->>Supabase: client.auth.verifyOTP(<br/>email:, token:, type: .email)

    alt Valid OTP
        Supabase-->>SupaSvc: Session
        SupaSvc-->>App: Success
    else Invalid / expired OTP
        Supabase-->>SupaSvc: Error
        SupaSvc-->>App: Throws error
    end
```

## Apple Sign In vs Email — Comparison

```mermaid
flowchart TD
    subgraph apple ["Apple Sign In"]
        A1[User taps Apple button] --> A2[Native iOS prompt<br/>Face ID / Touch ID / Password]
        A2 --> A3[Apple returns idToken]
        A3 --> A4[Supabase validates idToken<br/>with Apple servers]
        A4 --> A5[Session created]
        A5 --> A6[Name/email cached in<br/>UserDefaults from Apple<br/>— first sign-in only]
    end

    subgraph email ["Email Sign In"]
        E1[User taps Email button] --> E2[UIAlertController<br/>email + password fields]
        E2 --> E3[Credentials sent to<br/>Supabase directly]
        E3 --> E4[Supabase verifies against<br/>its own auth.users table]
        E4 --> E5[Session created]
        E5 --> E6[No name auto-populated<br/>— user enters in onboarding]
    end

    subgraph differences ["Key Differences"]
        D1["Apple: No password stored — token-based"]
        D2["Email: Password hashed in Supabase auth.users"]
        D3["Apple: Name available only on first sign-in"]
        D4["Email: No name provided at auth time"]
        D5["Apple: Uses nonce for replay protection"]
        D6["Email: Standard credential verification"]
        D7["Apple: Can use biometrics (Face ID)"]
        D8["Email: Manual credential entry every time"]
    end
```

## What the User Sees (UI Flow)

```mermaid
flowchart TD
    A[AuthenticationViewController] --> B["Sign in with Apple" button<br/>— black ASAuthorizationButton]
    A --> C["Sign in with Email" button<br/>— outlined style]

    C --> D[UIAlertController action sheet]
    D --> E["Sign In" — existing account]
    D --> F["Create Account" — new user]

    E --> G[UIAlertController with<br/>Email field + Password field<br/>+ Sign In button]
    F --> H[UIAlertController with<br/>Email field + Password field<br/>+ Create Account button]

    B --> I[System Apple ID sheet<br/>— handled by iOS]

    style A fill:#1a1a2e,color:#fff
    style B fill:#000,color:#fff
    style C fill:#2d2d44,color:#fff
```

## Debug Quick Login (DEBUG builds only)

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant AuthVC as AuthenticationViewController
    participant SupaSvc as SupabaseService
    participant Supabase as Supabase Auth

    Note over AuthVC: Only visible when<br/>DebugConfig.showDebugPanel = true

    Dev->>AuthVC: Taps "Quick Login (Debug)"
    AuthVC->>SupaSvc: signIn(email: DebugConfig.testEmail,<br/>password: DebugConfig.testPassword)
    SupaSvc->>Supabase: client.auth.signIn(email:, password:)
    Supabase-->>SupaSvc: Session
    SupaSvc-->>AuthVC: Success
    AuthVC->>AuthVC: Normal post-auth flow<br/>(profile check → main or onboarding)
```
