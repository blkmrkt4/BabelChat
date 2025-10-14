# LangMatcher Database & Storage Architecture Specification

## Overview

This document defines the complete database and storage architecture for LangMatcher. Reference this file for all database-related implementation decisions.

**Primary Technologies:**
- **Local Storage**: Core Data (iOS native)
- **Cloud Storage**: CloudKit (Apple) + Supabase Storage
- **Backend Database**: Supabase (PostgreSQL with real-time)
- **Cache Layer**: Core Data + In-memory cache

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│            iOS App (Client)              │
├─────────────────────────────────────────┤
│         Core Data (Local DB)             │
│  - Message cache (last 100 per chat)    │
│  - User profiles cache                  │
│  - Translation cache                    │
│  - Offline queue                        │
├─────────────────────────────────────────┤
│          CloudKit (Apple Cloud)          │
│  - User profile photos (CKAsset)        │
│  - Saved phrases/vocabulary             │
│  - User preferences sync                │
│  - Learning progress                    │
├─────────────────────────────────────────┤
│         Supabase (Backend)               │
│  - Real-time messaging                  │
│  - User authentication                  │
│  - Matching algorithm                   │
│  - Chat history (source of truth)       │
│  - Analytics events                     │
└─────────────────────────────────────────┘
```

## Supabase Configuration

### Connection Details
```swift
// Environment variables (store in .env, NEVER commit)
SUPABASE_URL=https://[your-project-ref].supabase.co
SUPABASE_ANON_KEY=[your-anon-key]
SUPABASE_SERVICE_KEY=[your-service-key] // Server-side only

// Swift client initialization
import Supabase

let client = SupabaseClient(
    supabaseURL: URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"]!)!,
    supabaseKey: ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]!
)
```

### Database Schema

```sql
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector"; -- For AI-powered matching

-- Users table (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    bio TEXT,
    age INTEGER CHECK (age >= 18),
    location TEXT, -- City, Country format
    native_language TEXT NOT NULL,
    learning_languages TEXT[] NOT NULL,
    proficiency_levels JSONB DEFAULT '{}', -- {"es": 2, "fr": 1}
    learning_goals TEXT[] DEFAULT '{}', -- ["travel", "business", "cultural"]
    profile_image_url TEXT,
    cloudkit_record_id TEXT, -- Link to CloudKit profile
    is_premium BOOLEAN DEFAULT FALSE,
    granularity_level INTEGER DEFAULT 2 CHECK (granularity_level BETWEEN 0 AND 3),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes for matching algorithm
    CONSTRAINT valid_age CHECK (age >= 18 AND age <= 120),
    CONSTRAINT valid_languages CHECK (array_length(learning_languages, 1) > 0)
);

-- Create indexes for efficient queries
CREATE INDEX idx_profiles_native_language ON profiles(native_language);
CREATE INDEX idx_profiles_learning_languages ON profiles USING GIN(learning_languages);
CREATE INDEX idx_profiles_last_active ON profiles(last_active DESC);
CREATE INDEX idx_profiles_location ON profiles(location);

-- Matches table
CREATE TABLE public.matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    user1_liked BOOLEAN DEFAULT FALSE,
    user2_liked BOOLEAN DEFAULT FALSE,
    is_mutual BOOLEAN GENERATED ALWAYS AS (user1_liked AND user2_liked) STORED,
    match_type TEXT DEFAULT 'normal' CHECK (match_type IN ('normal', 'super_like')),
    matched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    conversation_id UUID,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Ensure unique matches (no duplicates)
    CONSTRAINT unique_match_pair UNIQUE (user1_id, user2_id),
    CONSTRAINT no_self_match CHECK (user1_id != user2_id)
);

CREATE INDEX idx_matches_user1 ON matches(user1_id);
CREATE INDEX idx_matches_user2 ON matches(user2_id);
CREATE INDEX idx_matches_mutual ON matches(is_mutual) WHERE is_mutual = TRUE;

-- Swipes table (for algorithm and analytics)
CREATE TABLE public.swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    swiped_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    direction TEXT NOT NULL CHECK (direction IN ('left', 'right', 'super')),
    swiped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_swipe UNIQUE (swiper_id, swiped_id),
    CONSTRAINT no_self_swipe CHECK (swiper_id != swiped_id)
);

CREATE INDEX idx_swipes_swiper ON swipes(swiper_id);
CREATE INDEX idx_swipes_swiped_at ON swipes(swiped_at DESC);

-- Conversations table
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_at TIMESTAMP WITH TIME ZONE,
    last_message_preview TEXT,
    message_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT valid_message_count CHECK (message_count >= 0)
);

CREATE INDEX idx_conversations_match ON conversations(match_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC NULLS LAST);

-- Messages table (with real-time enabled)
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    original_text TEXT NOT NULL,
    original_language TEXT NOT NULL,
    translated_text JSONB DEFAULT '{}', -- {"en": "Hello", "es": "Hola"}
    ai_insights JSONB DEFAULT '{}', -- {"grammar": [], "cultural": "", "alternatives": []}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    edited_at TIMESTAMP WITH TIME ZONE,
    is_read BOOLEAN DEFAULT FALSE,
    is_delivered BOOLEAN DEFAULT FALSE,
    
    CONSTRAINT valid_participants CHECK (sender_id != receiver_id)
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);

-- Enable real-time for messages
ALTER TABLE messages REPLICA IDENTITY FULL;

-- Saved phrases table (syncs with CloudKit)
CREATE TABLE public.saved_phrases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    original_text TEXT NOT NULL,
    translated_text TEXT NOT NULL,
    language TEXT NOT NULL,
    context TEXT,
    cloudkit_record_id TEXT,
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_saved_phrases_user ON saved_phrases(user_id);
CREATE INDEX idx_saved_phrases_language ON saved_phrases(language);

-- User preferences table
CREATE TABLE public.user_preferences (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    min_age INTEGER DEFAULT 18,
    max_age INTEGER DEFAULT 99,
    max_distance_km INTEGER,
    preferred_locations TEXT[] DEFAULT '{}',
    blocked_users UUID[] DEFAULT '{}',
    notification_settings JSONB DEFAULT '{"messages": true, "matches": true, "likes": true}',
    privacy_settings JSONB DEFAULT '{"show_online": true, "show_location": true}',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analytics events table
CREATE TABLE public.analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    event_data JSONB DEFAULT '{}',
    device_info JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_analytics_user ON analytics_events(user_id);
CREATE INDEX idx_analytics_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_created ON analytics_events(created_at DESC);

-- Translation cache table (to reduce API costs)
CREATE TABLE public.translation_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text_hash TEXT NOT NULL, -- SHA256 of original text
    from_language TEXT NOT NULL,
    to_language TEXT NOT NULL,
    translated_text TEXT NOT NULL,
    provider TEXT DEFAULT 'openai', -- 'openai', 'google', 'deepl'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    usage_count INTEGER DEFAULT 1,
    
    CONSTRAINT unique_translation UNIQUE (text_hash, from_language, to_language, provider)
);

CREATE INDEX idx_translation_hash ON translation_cache(text_hash);
CREATE INDEX idx_translation_usage ON translation_cache(usage_count DESC);
```

### Database Functions

```sql
-- Function to update message count on new message
CREATE OR REPLACE FUNCTION update_conversation_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations 
    SET 
        message_count = message_count + 1,
        last_message_at = NEW.created_at,
        last_message_preview = LEFT(NEW.original_text, 100)
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_new_message
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION update_conversation_stats();

-- Function to find language matches
CREATE OR REPLACE FUNCTION find_language_matches(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    user_id UUID,
    first_name TEXT,
    age INTEGER,
    location TEXT,
    native_language TEXT,
    learning_languages TEXT[],
    profile_image_url TEXT,
    compatibility_score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH user_data AS (
        SELECT * FROM profiles WHERE id = p_user_id
    ),
    potential_matches AS (
        SELECT 
            p.id,
            p.first_name,
            p.age,
            p.location,
            p.native_language,
            p.learning_languages,
            p.profile_image_url,
            -- Calculate compatibility score
            (
                -- They speak what I want to learn (50 points)
                CASE WHEN u.learning_languages && ARRAY[p.native_language] 
                     THEN 50 ELSE 0 END +
                -- I speak what they want to learn (50 points)
                CASE WHEN p.learning_languages && ARRAY[u.native_language] 
                     THEN 50 ELSE 0 END +
                -- Bonus for being recently active (up to 10 points)
                CASE WHEN p.last_active > NOW() - INTERVAL '7 days'
                     THEN 10
                     WHEN p.last_active > NOW() - INTERVAL '30 days'
                     THEN 5
                     ELSE 0 END
            ) AS compatibility_score
        FROM profiles p
        CROSS JOIN user_data u
        WHERE p.id != p_user_id
        -- Must have at least one language match
        AND (
            u.learning_languages && ARRAY[p.native_language]
            OR p.learning_languages && ARRAY[u.native_language]
        )
        -- Not already matched
        AND NOT EXISTS (
            SELECT 1 FROM matches m 
            WHERE (m.user1_id = p_user_id AND m.user2_id = p.id)
               OR (m.user1_id = p.id AND m.user2_id = p_user_id)
        )
        -- Not already swiped
        AND NOT EXISTS (
            SELECT 1 FROM swipes s
            WHERE s.swiper_id = p_user_id AND s.swiped_id = p.id
        )
    )
    SELECT 
        pm.id as user_id,
        pm.first_name,
        pm.age,
        pm.location,
        pm.native_language,
        pm.learning_languages,
        pm.profile_image_url,
        pm.compatibility_score
    FROM potential_matches pm
    ORDER BY pm.compatibility_score DESC, pm.last_active DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to check and create mutual match
CREATE OR REPLACE FUNCTION process_swipe(
    p_swiper_id UUID,
    p_swiped_id UUID,
    p_direction TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_match_id UUID;
    v_is_match BOOLEAN := FALSE;
    v_conversation_id UUID;
BEGIN
    -- Record the swipe
    INSERT INTO swipes (swiper_id, swiped_id, direction)
    VALUES (p_swiper_id, p_swiped_id, p_direction)
    ON CONFLICT (swiper_id, swiped_id) DO NOTHING;
    
    -- If it's a right swipe, check for mutual match
    IF p_direction IN ('right', 'super') THEN
        -- Check if other person already swiped right
        IF EXISTS (
            SELECT 1 FROM swipes 
            WHERE swiper_id = p_swiped_id 
            AND swiped_id = p_swiper_id 
            AND direction IN ('right', 'super')
        ) THEN
            -- Create mutual match
            v_conversation_id := uuid_generate_v4();
            
            INSERT INTO matches (
                user1_id, 
                user2_id, 
                user1_liked, 
                user2_liked,
                match_type,
                conversation_id
            ) VALUES (
                LEAST(p_swiper_id, p_swiped_id),
                GREATEST(p_swiper_id, p_swiped_id),
                TRUE,
                TRUE,
                CASE WHEN p_direction = 'super' THEN 'super_like' ELSE 'normal' END,
                v_conversation_id
            ) RETURNING id INTO v_match_id;
            
            -- Create conversation
            INSERT INTO conversations (id, match_id)
            VALUES (v_conversation_id, v_match_id);
            
            v_is_match := TRUE;
        END IF;
    END IF;
    
    RETURN jsonb_build_object(
        'is_match', v_is_match,
        'match_id', v_match_id,
        'conversation_id', v_conversation_id
    );
END;
$$ LANGUAGE plpgsql;
```

### Row Level Security (RLS) Policies

```sql
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_phrases ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone"
    ON profiles FOR SELECT
    USING (true);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Messages policies
CREATE POLICY "Users can view their own messages"
    ON messages FOR SELECT
    USING (
        auth.uid() = sender_id OR 
        auth.uid() = receiver_id
    );

CREATE POLICY "Users can send messages"
    ON messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

-- Matches policies
CREATE POLICY "Users can view their matches"
    ON matches FOR SELECT
    USING (
        auth.uid() = user1_id OR 
        auth.uid() = user2_id
    );

-- Saved phrases policies
CREATE POLICY "Users can manage their saved phrases"
    ON saved_phrases FOR ALL
    USING (auth.uid() = user_id);

-- User preferences policies
CREATE POLICY "Users can manage their preferences"
    ON user_preferences FOR ALL
    USING (auth.uid() = user_id);
```

### Supabase Edge Functions

```typescript
// supabase/functions/translate-message/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { text, targetLanguage, sourceLanguage } = await req.json()
  
  // Check cache first
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  
  const textHash = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(text)
  )
  
  const { data: cached } = await supabase
    .from('translation_cache')
    .select('translated_text')
    .eq('text_hash', textHash)
    .eq('from_language', sourceLanguage)
    .eq('to_language', targetLanguage)
    .single()
  
  if (cached) {
    return new Response(JSON.stringify({ translation: cached.translated_text }))
  }
  
  // Call OpenRouter API
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('OPENROUTER_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'openai/gpt-3.5-turbo',
      messages: [{
        role: 'system',
        content: `Translate the following text from ${sourceLanguage} to ${targetLanguage}. Provide only the translation, no explanations.`
      }, {
        role: 'user',
        content: text
      }]
    })
  })
  
  const result = await response.json()
  const translation = result.choices[0].message.content
  
  // Cache the translation
  await supabase
    .from('translation_cache')
    .insert({
      text_hash: textHash,
      from_language: sourceLanguage,
      to_language: targetLanguage,
      translated_text: translation
    })
  
  return new Response(JSON.stringify({ translation }))
})
```

## Core Data Schema (iOS Local)

```swift
// Core Data Entity Definitions
// File: LangMatcher.xcdatamodeld

// CachedProfile Entity
entity: CachedProfile {
    attributes:
        - id: UUID
        - firstName: String
        - profileImageData: Binary
        - nativeLanguage: String
        - learningLanguages: Transformable // [String]
        - lastUpdated: Date
    relationships:
        - messages: To-Many -> CachedMessage
}

// CachedMessage Entity
entity: CachedMessage {
    attributes:
        - id: UUID
        - conversationId: UUID
        - originalText: String
        - translatedText: String?
        - timestamp: Date
        - isRead: Boolean
        - isSent: Boolean
        - syncedToCloud: Boolean
    relationships:
        - sender: To-One -> CachedProfile
}

// CachedConversation Entity
entity: CachedConversation {
    attributes:
        - id: UUID
        - lastMessageText: String?
        - lastMessageTime: Date?
        - unreadCount: Int16
    relationships:
        - messages: To-Many -> CachedMessage (ordered)
        - participants: To-Many -> CachedProfile
}

// TranslationCache Entity
entity: TranslationCache {
    attributes:
        - originalText: String
        - fromLanguage: String
        - toLanguage: String
        - translatedText: String
        - cachedAt: Date
        - hitCount: Int32
}
```

## CloudKit Schema

```swift
// CloudKit Record Types
// Container: iCloud.com.langmatcher.app

// UserProfile Record Type
recordType: UserProfile {
    fields:
        - userId: String (indexed)
        - profileImage: Asset
        - savedPhrases: [Reference] -> SavedPhrase
        - preferences: Bytes // Encrypted JSON
        - lastSyncedAt: Date
}

// SavedPhrase Record Type  
recordType: SavedPhrase {
    fields:
        - originalText: String
        - translatedText: String
        - language: String (indexed)
        - context: String
        - savedAt: Date (indexed)
        - userId: Reference -> UserProfile
}
```

## Storage Strategy

### Image Storage

```swift
// Profile Images
// Primary: CloudKit (free, CDN included)
// Backup: Supabase Storage
// Local: Core Data (thumbnail only)

func uploadProfileImage(_ image: UIImage) async throws {
    // 1. Compress image
    let compressed = image.jpegData(compressionQuality: 0.8)!
    
    // 2. Save thumbnail to Core Data for offline
    let thumbnail = image.resized(to: CGSize(width: 200, height: 200))
    CoreDataManager.shared.saveProfileThumbnail(thumbnail)
    
    // 3. Upload to CloudKit
    let ckAsset = CKAsset(data: compressed)
    let record = CKRecord(recordType: "UserProfile")
    record["profileImage"] = ckAsset
    try await CloudKitManager.shared.save(record)
    
    // 4. Store URL reference in Supabase
    await supabase.from("profiles")
        .update(["profile_image_url": ckAsset.fileURL])
        .eq("id", userId)
}
```

### Message Storage

```swift
// Messages Flow:
// 1. Save to Core Data immediately (offline support)
// 2. Send to Supabase (real-time delivery)
// 3. Mark as synced in Core Data

func sendMessage(_ text: String, conversation: String) async {
    // 1. Save locally first
    let message = CoreDataManager.shared.saveMessage(
        text: text, 
        conversation: conversation,
        syncStatus: .pending
    )
    
    // 2. Send to Supabase
    do {
        let response = try await supabase.from("messages")
            .insert([
                "original_text": text,
                "conversation_id": conversation,
                "sender_id": currentUserId
            ])
            .execute()
        
        // 3. Mark as synced
        CoreDataManager.shared.markSynced(message)
    } catch {
        // Will retry on next sync
        print("Message queued for retry")
    }
}
```

## Data Sync Strategy

```swift
// Sync Manager handles all data synchronization
class SyncManager {
    // Sync priorities
    enum SyncPriority {
        case immediate  // Messages, matches
        case high       // Profile updates
        case normal     // Preferences, saved phrases
        case low        // Analytics
    }
    
    // Sync on app lifecycle
    func syncOnAppLaunch() {
        // 1. Send queued messages
        // 2. Fetch new messages
        // 3. Update matches
        // 4. Sync profile changes
    }
    
    // Real-time subscriptions
    func subscribeToRealtimeUpdates() {
        // Messages
        supabase.realtime
            .channel("messages")
            .on("INSERT") { payload in
                self.handleNewMessage(payload)
            }
            .subscribe()
        
        // Matches
        supabase.realtime
            .channel("matches")
            .on("INSERT") { payload in
                self.handleNewMatch(payload)
            }
            .subscribe()
    }
}
```

## Backup & Recovery

```swift
// Daily backup to CloudKit
func scheduleBackups() {
    // Critical data backed up to CloudKit daily
    Timer.scheduledTimer(withTimeInterval: 86400) { _ in
        self.backupToCloudKit([
            "saved_phrases",
            "user_preferences",
            "learning_progress"
        ])
    }
}

// Recovery procedure
func recoverUserData() async {
    // 1. Restore from CloudKit (user-owned data)
    let cloudData = try await CloudKitManager.restore()
    
    // 2. Restore from Supabase (messages, matches)
    let serverData = try await supabase.from("messages")
        .select("*")
        .eq("user_id", userId)
        .execute()
    
    // 3. Merge and resolve conflicts
    DataMerger.merge(cloud: cloudData, server: serverData)
}
```

## Performance Guidelines

### Query Optimization
- Always paginate messages (50 per page)
- Cache user profiles for 24 hours
- Use indexes on all foreign keys
- Limit real-time subscriptions to active conversations

### Storage Limits
- Profile images: Max 5MB, JPEG 80% quality
- Message length: Max 1000 characters
- Translation cache: Keep last 1000 translations
- Core Data: Purge messages older than 90 days

### API Rate Limits
- Supabase: 1000 requests/minute on free tier
- Translation API: Batch requests when possible
- CloudKit: 40 requests/second per container

## Security Requirements

### Data Encryption
- All API keys in iOS Keychain
- Sensitive user data encrypted at rest in Core Data
- TLS 1.3 for all network requests
- Certificate pinning for Supabase endpoints

### Authentication Flow
```swift
// Sign in with Apple -> Supabase Auth
func signInWithApple() async throws {
    let appleIDCredential = try await ASAuthorizationAppleIDProvider().createRequest()
    
    let session = try await supabase.auth.signInWithIdToken(
        credentials: .init(
            provider: .apple,
            idToken: appleIDCredential.identityToken,
            nonce: nonce
        )
    )
    
    // Create/update profile
    try await supabase.from("profiles")
        .upsert(["id": session.user.id])
        .execute()
}
```

## Error Handling

```swift
enum DatabaseError: Error {
    case syncFailed
    case quotaExceeded
    case networkUnavailable
    case authenticationRequired
}

// Retry logic for failed operations
func retryableOperation<T>(
    maxRetries: Int = 3,
    operation: () async throws -> T
) async throws -> T {
    for attempt in 0..<maxRetries {
        do {
            return try await operation()
        } catch {
            if attempt == maxRetries - 1 { throw error }
            await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
        }
    }
    throw DatabaseError.syncFailed
}
```

## Migration Notes

### Future Considerations
- If user base exceeds 100k: Consider PostgreSQL read replicas
- If message volume exceeds 1M/day: Add Redis cache layer
- For Android support: Supabase works cross-platform
- For web app: Same Supabase backend, different client

### Data Portability
- Users can export all their data via GDPR request
- CloudKit data owned by user's Apple ID
- Supabase data exportable as JSON/CSV
- No vendor lock-in: Can migrate to self-hosted Supabase

## Testing Strategy

```swift
// Test data scenarios
class DatabaseTests {
    func testOfflineMessageQueue() { }
    func testConflictResolution() { }
    func testRealTimeSync() { }
    func testDataMigration() { }
    func testCacheExpiration() { }
}
```

---

**Last Updated**: [Current Date]
**Version**: 1.0
**Status**: Active Development

This specification is the source of truth for all database and storage decisions in LangMatcher. Any changes should be reflected here first before implementation.