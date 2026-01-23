# App Review Notes - User Generated Content Safety

This document outlines Fluenca's content moderation and user safety features to address App Store Review Guideline 1.2 (Safety - User Generated Content).

## Summary of Safety Features

Fluenca is a language learning app that connects users for language exchange. We have implemented comprehensive safety features to protect our community.

## 1. Terms of Service & EULA Acceptance

**Location:** Onboarding flow (second step after language selection)

Users must explicitly accept:
- Terms of Service
- Privacy Policy
- Age verification (18+)

**How it works:**
- Users see three checkboxes they must check to proceed
- Can view full Terms, Privacy Policy, and Community Guidelines
- Acceptance timestamp is stored locally and synced to backend
- Users cannot proceed without accepting all three

**Code reference:** `TermsAcceptanceViewController.swift`

## 2. Content Filtering

**Location:** All outgoing messages (ChatViewController.swift)

### Automatic Profanity Filter
- All messages are checked before sending via `ContentFilterService`
- Profanity is automatically masked with asterisks (e.g., "f***")
- **Multi-language support:** English, Spanish, French, German, Portuguese, Italian
- **How to test:** Send a message containing common profanity - it will be masked

### Severe Content Blocking
- Messages with severe violations are blocked entirely
- User sees alert: "Message Blocked - Your message contains content that violates our community guidelines"
- Blocked content is automatically reported to moderation team

### Pattern Detection
- Phone numbers, emails, and social media handles are flagged
- Helps prevent users from sharing contact info to circumvent the platform

**Code reference:** `ContentFilterService.swift`, `ChatViewController.swift:sendButtonTapped()`

## 3. Mechanism to Flag Objectionable Content

### 3.1 Report User Profile
**Location:** User Detail screen > "..." menu > "Report User"

Users can report profiles for:
- Inappropriate content
- Spam or misleading
- Fake profile
- Harassment or bullying
- Scam or fraud
- Other

**Code reference:** `UserDetailViewController.swift:showReportUserOptions()`

### 3.2 Report Photos
**Location:** Photo viewer > Long press on photo

Users can report photos for:
- Inappropriate content
- Spam or misleading
- Not a real photo
- Violence or dangerous content
- Harassment or hate speech
- Other

**Code reference:** `PhotoDetailViewController.swift`, `UserDetailViewController.swift:showReportOptions()`

### 3.3 Report Messages
**Location:** Chat > Long press on message > "Report Message"

Users can report messages for:
- Inappropriate content
- Spam
- Harassment
- Hate speech
- Other

**Code reference:** `ChatViewController.swift:showReportMessageOptions()`

## 4. Mechanism to Block Abusive Users

**Location:** User Detail screen > "..." menu > "Block User"

When a user blocks another:
- Blocked user is added to blocker's blocked_users list
- Any existing match between them is deleted
- Blocked user is removed from discovery feed
- Blocked user cannot see the blocker's profile
- All pending swipes between them are deleted

**Database function:** `block_user(blocker_id, blocked_id)`

**Code reference:**
- `UserDetailViewController.swift:performBlockUser()`
- `SupabaseService.swift:blockUser()`
- `add_block_user_functions.sql`

## 5. Content Moderation Response

**Response time commitment:** All reports are reviewed within 24 hours

**Actions we can take:**
- Remove offending content
- Issue warnings to users
- Temporarily suspend accounts
- Permanently ban accounts
- Report to law enforcement if necessary

**Moderation dashboard:** Web admin panel at `/moderation` allows admins to:
- View all pending reports
- Review reported content/users
- Take action (warn, suspend, ban)
- Track moderation history

## 6. Community Guidelines

Users can access Community Guidelines that explain:
- Expected behavior
- Prohibited content
- Reporting process
- Consequences of violations

**Location:** Settings > Legal > Community Guidelines

**File:** `LangChat/Legal/CommunityGuidelines.md`

## Technical Implementation Details

### Database Tables
- `reported_users` - Stores all reports (user, photo, message)
- `user_preferences.blocked_users` - Array of blocked user IDs
- `profiles.is_banned` - Ban status for users
- `admin_audit_log` - Tracks moderation actions

### Backend Functions
- `block_user()` - Handles blocking and cleanup
- `unblock_user()` - Handles unblocking
- `is_blocked_by()` - Checks block status

## Contact Information

For urgent safety concerns:
- Email: blkmrkt.runner@gmail.com
- In-app: Settings > Help & Support > Report Safety Concern

---

Last updated: January 23, 2026
