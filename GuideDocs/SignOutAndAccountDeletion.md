# Sign Out & Account Deletion Flows

How users exit the app and how data is cleaned up.

## Sign Out Flow

```mermaid
sequenceDiagram
    participant User
    participant SettingsVC as SettingsViewController
    participant SupaSvc as SupabaseService
    participant SDK as Supabase SDK
    participant Remote as Supabase Auth

    User->>SettingsVC: Taps "Sign Out"
    SettingsVC->>SettingsVC: Show confirmation alert

    User->>SettingsVC: Confirms sign out

    SettingsVC->>SupaSvc: signOut()
    SupaSvc->>SDK: client.auth.signOut()
    SDK->>Remote: POST /logout (invalidate refresh token)
    Remote-->>SDK: OK
    SDK->>SDK: Clear persisted tokens

    SupaSvc-->>SettingsVC: Success

    SettingsVC->>SettingsVC: Clear UserDefaults auth keys
    SettingsVC->>SettingsVC: Navigate to AuthenticationViewController

    Note over SettingsVC: User returns to sign-in screen.<br/>Next sign-in restores full access<br/>if profile is still complete.
```

## Account Deletion Flow

```mermaid
sequenceDiagram
    participant User
    participant SettingsVC as SettingsViewController
    participant SupaSvc as SupabaseService
    participant Supabase as Supabase Database
    participant Storage as Supabase Storage
    participant Auth as Supabase Auth

    User->>SettingsVC: Taps "Delete Account"
    SettingsVC->>SettingsVC: Show destructive confirmation alert

    User->>SettingsVC: Confirms deletion

    SettingsVC->>SupaSvc: deleteAccount()

    Note over SupaSvc: Cascade delete across all tables

    SupaSvc->>Supabase: DELETE messages (where sender or receiver)
    SupaSvc->>Supabase: DELETE conversations (where user1 or user2)
    SupaSvc->>Supabase: DELETE reported_users (where reporter or reported)
    SupaSvc->>Supabase: DELETE muse_interactions
    SupaSvc->>Supabase: DELETE feedback
    SupaSvc->>Supabase: DELETE matches (where user1 or user2)
    SupaSvc->>Supabase: DELETE swipes (where swiper or swiped)
    SupaSvc->>Supabase: DELETE user_languages
    SupaSvc->>Supabase: DELETE user_preferences
    SupaSvc->>Supabase: DELETE invites (where inviter)
    SupaSvc->>Supabase: DELETE profiles

    SupaSvc->>Storage: Delete user's photo files

    SupaSvc->>Auth: RPC delete_auth_user()
    Note over Auth: SECURITY DEFINER function<br/>deletes auth.users row<br/>where id = auth.uid()
    Auth-->>SupaSvc: Auth user deleted

    SupaSvc->>Auth: client.auth.signOut()

    SupaSvc-->>SettingsVC: Success

    SettingsVC->>SettingsVC: Clear all UserDefaults
    SettingsVC->>SettingsVC: Navigate to AuthenticationViewController
```

## Data Deletion Cascade — What Gets Removed

```mermaid
flowchart TD
    A[deleteAccount called] --> B[Supabase Tables]
    A --> C[Supabase Storage]
    A --> D[Local Device]
    A --> E[Auth System]

    B --> B1[messages]
    B --> B2[conversations]
    B --> B3[reported_users]
    B --> B4[muse_interactions]
    B --> B5[feedback]
    B --> B6[matches]
    B --> B7[swipes]
    B --> B8[user_languages]
    B --> B9[user_preferences]
    B --> B10[invites]
    B --> B11[profiles]

    C --> C1[Profile photos in storage bucket]

    D --> D1[UserDefaults cleared]
    D --> D2[SDK tokens cleared via signOut]

    E --> E1[auth.users row DELETED<br/>via delete_auth_user RPC]
    E --> E2[Refresh token invalidated via signOut]

    style A fill:#8b0000,color:#fff
    style B fill:#4a1010,color:#fff
    style C fill:#4a1010,color:#fff
```

## Sign Out vs Delete — Comparison

```mermaid
flowchart LR
    subgraph signout ["Sign Out"]
        SO1[Invalidate session tokens]
        SO2[Clear local UserDefaults]
        SO3[Server data PRESERVED]
        SO4[Can sign back in<br/>and resume immediately]
    end

    subgraph delete ["Delete Account"]
        DA1[Invalidate session tokens]
        DA2[Clear local UserDefaults]
        DA3[ALL server data DELETED<br/>— 11 tables + storage + auth.users]
        DA4[Signing back in creates<br/>a completely new auth user]
    end
```

## What Survives Sign Out

| Data | After Sign Out | After Delete |
|------|----------------|--------------|
| Supabase auth.users row | Kept | **Deleted** via `delete_auth_user()` RPC |
| Profile in profiles table | Kept | Deleted |
| Matches & swipes | Kept | Deleted |
| Messages & conversations | Kept | Deleted |
| Photos in storage | Kept | Deleted |
| UserDefaults (local) | Cleared | Cleared |
| SDK tokens (local) | Cleared | Cleared |
| Apple ID association | Kept | Kept (Apple-side, not app-controlled) |

> **Note:** The `auth.users` row is now deleted via the `delete_auth_user()` Postgres function (SECURITY DEFINER). This function verifies `auth.uid()` matches the caller, then deletes the row from `auth.users`. It is called while the user is still authenticated, just before the final `signOut()`. If a user signs up again with the same Apple ID or email, Supabase will create a completely new auth user with a new UUID.
