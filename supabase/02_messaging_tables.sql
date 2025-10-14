-- Part 2: Messaging and Communication Tables
-- Execute this after Part 1

-- 5. Conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_message_at TIMESTAMPTZ,
    last_message_preview TEXT,
    message_count INTEGER DEFAULT 0,
    unread_count_user1 INTEGER DEFAULT 0,
    unread_count_user2 INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,

    CONSTRAINT valid_counts CHECK (message_count >= 0 AND unread_count_user1 >= 0 AND unread_count_user2 >= 0)
);

-- 6. Messages table (with real-time support)
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    original_text TEXT NOT NULL,
    original_language TEXT NOT NULL,
    translated_text JSONB DEFAULT '{}',
    ai_insights JSONB DEFAULT '{}',
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'voice')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    edited_at TIMESTAMPTZ,
    is_read BOOLEAN DEFAULT false,
    is_delivered BOOLEAN DEFAULT false,

    CONSTRAINT valid_participants CHECK (sender_id != receiver_id)
);

-- Enable real-time for messages
ALTER TABLE messages REPLICA IDENTITY FULL;

-- 7. User preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    min_age INTEGER DEFAULT 18,
    max_age INTEGER DEFAULT 99,
    max_distance_km INTEGER,
    preferred_locations TEXT[] DEFAULT '{}',
    blocked_users UUID[] DEFAULT '{}',
    notification_settings JSONB DEFAULT '{"messages": true, "matches": true, "likes": true}',
    privacy_settings JSONB DEFAULT '{"show_online": true, "show_location": true}',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Saved phrases table
CREATE TABLE IF NOT EXISTS saved_phrases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    original_text TEXT NOT NULL,
    translated_text TEXT NOT NULL,
    from_language TEXT NOT NULL,
    to_language TEXT NOT NULL,
    context TEXT,
    saved_at TIMESTAMPTZ DEFAULT NOW()
);