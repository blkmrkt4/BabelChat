-- LangChat Database Schema
-- Created: 2025-10-08
-- Description: Complete database schema for LangChat language exchange app

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS reported_users CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS language_lab_stats CASCADE;
DROP TABLE IF EXISTS saved_phrases CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS swipes CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS user_languages CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- 1. Profiles table (extends auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    phone_number TEXT UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT,
    bio TEXT,
    birth_year INTEGER,
    age INTEGER GENERATED ALWAYS AS (EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER - birth_year) STORED,
    location TEXT,
    show_city_in_profile BOOLEAN DEFAULT true,
    native_language TEXT NOT NULL,
    learning_languages TEXT[] DEFAULT '{}',
    proficiency_levels JSONB DEFAULT '{}',
    learning_goals TEXT[] DEFAULT '{}',
    profile_photos TEXT[] DEFAULT '{}',
    is_premium BOOLEAN DEFAULT false,
    granularity_level INTEGER DEFAULT 2 CHECK (granularity_level BETWEEN 0 AND 3),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active TIMESTAMPTZ DEFAULT NOW(),
    onboarding_completed BOOLEAN DEFAULT false,

    CONSTRAINT valid_birth_year CHECK (birth_year >= 1900 AND birth_year <= EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER - 13)
);

-- 2. User languages table
CREATE TABLE user_languages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    language TEXT NOT NULL,
    proficiency TEXT CHECK (proficiency IN ('native', 'fluent', 'intermediate', 'beginner')),
    is_native BOOLEAN DEFAULT false,
    is_learning BOOLEAN DEFAULT false,
    is_open_to_practice BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_user_language UNIQUE (user_id, language)
);

-- 3. Matches table
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    user1_liked BOOLEAN DEFAULT false,
    user2_liked BOOLEAN DEFAULT false,
    is_mutual BOOLEAN GENERATED ALWAYS AS (user1_liked AND user2_liked) STORED,
    match_type TEXT DEFAULT 'normal' CHECK (match_type IN ('normal', 'super_like')),
    matched_language TEXT,
    matched_at TIMESTAMPTZ DEFAULT NOW(),
    conversation_id UUID,
    is_active BOOLEAN DEFAULT true,
    last_interaction TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_match_pair UNIQUE (user1_id, user2_id),
    CONSTRAINT no_self_match CHECK (user1_id != user2_id)
);

-- 4. Swipes table
CREATE TABLE swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    swiped_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    direction TEXT NOT NULL CHECK (direction IN ('left', 'right', 'super')),
    shown_language TEXT,
    swiped_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_swipe UNIQUE (swiper_id, swiped_id),
    CONSTRAINT no_self_swipe CHECK (swiper_id != swiped_id)
);

-- 5. Conversations table
CREATE TABLE conversations (
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
CREATE TABLE messages (
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
CREATE TABLE user_preferences (
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
CREATE TABLE saved_phrases (
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

-- 9. Language Lab stats table
CREATE TABLE language_lab_stats (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    total_matches INTEGER DEFAULT 0,
    active_matches INTEGER DEFAULT 0,
    pending_matches INTEGER DEFAULT 0,
    messages_sent_week INTEGER DEFAULT 0,
    messages_received_week INTEGER DEFAULT 0,
    current_streaks JSONB DEFAULT '[]',
    achievements JSONB DEFAULT '[]',
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('message', 'match', 'like', 'streak')),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Reported users table
CREATE TABLE reported_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reported_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,

    CONSTRAINT different_users CHECK (reporter_id != reported_id)
);

-- 12. Subscriptions table
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    receipt_data TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_profiles_native_language ON profiles(native_language);
CREATE INDEX idx_profiles_learning_languages ON profiles USING GIN(learning_languages);
CREATE INDEX idx_profiles_last_active ON profiles(last_active DESC);
CREATE INDEX idx_profiles_location ON profiles(location);

CREATE INDEX idx_user_languages_user ON user_languages(user_id);
CREATE INDEX idx_user_languages_language ON user_languages(language);

CREATE INDEX idx_matches_user1 ON matches(user1_id);
CREATE INDEX idx_matches_user2 ON matches(user2_id);
CREATE INDEX idx_matches_mutual ON matches(is_mutual) WHERE is_mutual = true;
CREATE INDEX idx_matches_conversation ON matches(conversation_id);

CREATE INDEX idx_swipes_swiper ON swipes(swiper_id);
CREATE INDEX idx_swipes_swiped ON swipes(swiped_id);
CREATE INDEX idx_swipes_time ON swipes(swiped_at DESC);

CREATE INDEX idx_conversations_match ON conversations(match_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC NULLS LAST);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);

CREATE INDEX idx_saved_phrases_user ON saved_phrases(user_id);
CREATE INDEX idx_saved_phrases_language ON saved_phrases(from_language, to_language);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;

-- Enable Row Level Security on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_phrases ENABLE ROW LEVEL SECURITY;
ALTER TABLE language_lab_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE reported_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for profiles table
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view public profiles for matching" ON profiles
    FOR SELECT USING (true);

-- Create RLS policies for matches table
CREATE POLICY "Users can view their own matches" ON matches
    FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can create matches" ON matches
    FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can update their own matches" ON matches
    FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Create RLS policies for messages table
CREATE POLICY "Users can view their own messages" ON messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages" ON messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their own messages" ON messages
    FOR UPDATE USING (auth.uid() = sender_id);

-- Create RLS policies for conversations
CREATE POLICY "Users can view their conversations" ON conversations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM matches
            WHERE matches.id = conversations.match_id
            AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
        )
    );

-- Create RLS policies for user preferences
CREATE POLICY "Users can view their own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Create RLS policies for saved phrases
CREATE POLICY "Users can manage their saved phrases" ON saved_phrases
    FOR ALL USING (auth.uid() = user_id);

-- Create RLS policies for notifications
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR ALL USING (auth.uid() = user_id);

-- Create RLS policies for language lab stats
CREATE POLICY "Users can view their own stats" ON language_lab_stats
    FOR SELECT USING (auth.uid() = user_id);

-- Create RLS policies for subscriptions
CREATE POLICY "Users can view their own subscriptions" ON subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- Function to update last_active timestamp
CREATE OR REPLACE FUNCTION update_last_active()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE profiles SET last_active = NOW() WHERE id = NEW.sender_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update last_active on message send
CREATE TRIGGER update_user_last_active
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_last_active();

-- Function to update conversation stats on new message
CREATE OR REPLACE FUNCTION update_conversation_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET
        last_message_at = NOW(),
        last_message_preview = LEFT(NEW.original_text, 100),
        message_count = message_count + 1
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update conversation on new message
CREATE TRIGGER update_conversation_on_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_stats();

-- Grant permissions for authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;