-- Part 4: Performance Indexes
-- Execute this after all tables are created

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_native_language ON profiles(native_language);
CREATE INDEX IF NOT EXISTS idx_profiles_learning_languages ON profiles USING GIN(learning_languages);
CREATE INDEX IF NOT EXISTS idx_profiles_last_active ON profiles(last_active DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_location ON profiles(location);

-- User languages indexes
CREATE INDEX IF NOT EXISTS idx_user_languages_user ON user_languages(user_id);
CREATE INDEX IF NOT EXISTS idx_user_languages_language ON user_languages(language);

-- Matches indexes
CREATE INDEX IF NOT EXISTS idx_matches_user1 ON matches(user1_id);
CREATE INDEX IF NOT EXISTS idx_matches_user2 ON matches(user2_id);
CREATE INDEX IF NOT EXISTS idx_matches_mutual ON matches(is_mutual) WHERE is_mutual = true;
CREATE INDEX IF NOT EXISTS idx_matches_conversation ON matches(conversation_id);

-- Swipes indexes
CREATE INDEX IF NOT EXISTS idx_swipes_swiper ON swipes(swiper_id);
CREATE INDEX IF NOT EXISTS idx_swipes_swiped ON swipes(swiped_id);
CREATE INDEX IF NOT EXISTS idx_swipes_time ON swipes(swiped_at DESC);

-- Conversations indexes
CREATE INDEX IF NOT EXISTS idx_conversations_match ON conversations(match_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON conversations(last_message_at DESC NULLS LAST);

-- Messages indexes
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);

-- Saved phrases indexes
CREATE INDEX IF NOT EXISTS idx_saved_phrases_user ON saved_phrases(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_phrases_language ON saved_phrases(from_language, to_language);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;