-- Fix Row Level Security (RLS) policies to allow users to access their own data

-- Enable RLS on all tables (if not already enabled)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read all profiles, update only their own
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
CREATE POLICY "Users can view all profiles" ON profiles
    FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- Matches: Users can see matches where they are either user1 or user2
DROP POLICY IF EXISTS "Users can view their own matches" ON matches;
CREATE POLICY "Users can view their own matches" ON matches
    FOR SELECT
    USING (
        auth.uid() = user1_id OR
        auth.uid() = user2_id
    );

DROP POLICY IF EXISTS "Users can create matches" ON matches;
CREATE POLICY "Users can create matches" ON matches
    FOR INSERT
    WITH CHECK (
        auth.uid() = user1_id OR
        auth.uid() = user2_id
    );

DROP POLICY IF EXISTS "Users can update their matches" ON matches;
CREATE POLICY "Users can update their matches" ON matches
    FOR UPDATE
    USING (
        auth.uid() = user1_id OR
        auth.uid() = user2_id
    );

-- Conversations: Users can see conversations linked to their matches
DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
CREATE POLICY "Users can view their conversations" ON conversations
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM matches
            WHERE matches.id = conversations.match_id
            AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
CREATE POLICY "Users can create conversations" ON conversations
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM matches
            WHERE matches.id = conversations.match_id
            AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
        )
    );

-- Messages: Users can see messages in their conversations
DROP POLICY IF EXISTS "Users can view their messages" ON messages;
CREATE POLICY "Users can view their messages" ON messages
    FOR SELECT
    USING (
        auth.uid() = sender_id OR
        auth.uid() = receiver_id
    );

DROP POLICY IF EXISTS "Users can send messages" ON messages;
CREATE POLICY "Users can send messages" ON messages
    FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = conversation_id
            AND EXISTS (
                SELECT 1 FROM matches
                WHERE matches.id = conversations.match_id
                AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
            )
        )
    );

-- Swipes: Users can see their own swipes
DROP POLICY IF EXISTS "Users can view their swipes" ON swipes;
CREATE POLICY "Users can view their swipes" ON swipes
    FOR SELECT
    USING (auth.uid() = swiper_id);

DROP POLICY IF EXISTS "Users can create swipes" ON swipes;
CREATE POLICY "Users can create swipes" ON swipes
    FOR INSERT
    WITH CHECK (auth.uid() = swiper_id);

-- Grant necessary permissions
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON matches TO authenticated;
GRANT ALL ON conversations TO authenticated;
GRANT ALL ON messages TO authenticated;
GRANT ALL ON swipes TO authenticated;
