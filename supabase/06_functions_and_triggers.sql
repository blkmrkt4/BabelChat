-- Part 6: Functions and Triggers
-- Execute this last

-- Function to update last_active timestamp
CREATE OR REPLACE FUNCTION update_last_active()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE profiles SET last_active = NOW() WHERE id = NEW.sender_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update last_active on message send
DROP TRIGGER IF EXISTS update_user_last_active ON messages;
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

    -- Update unread count for receiver
    IF EXISTS (SELECT 1 FROM matches WHERE conversation_id = NEW.conversation_id AND user1_id = NEW.receiver_id) THEN
        UPDATE conversations
        SET unread_count_user1 = unread_count_user1 + 1
        WHERE id = NEW.conversation_id;
    ELSE
        UPDATE conversations
        SET unread_count_user2 = unread_count_user2 + 1
        WHERE id = NEW.conversation_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update conversation on new message
DROP TRIGGER IF EXISTS update_conversation_on_message ON messages;
CREATE TRIGGER update_conversation_on_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_stats();

-- Function to create profile after user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email)
    VALUES (new.id, new.email)
    ON CONFLICT (id) DO NOTHING;

    -- Create default preferences
    INSERT INTO public.user_preferences (user_id)
    VALUES (new.id)
    ON CONFLICT (user_id) DO NOTHING;

    -- Create language lab stats
    INSERT INTO public.language_lab_stats (user_id)
    VALUES (new.id)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Function to update language lab stats
CREATE OR REPLACE FUNCTION update_language_lab_stats(p_user_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE language_lab_stats
    SET
        total_matches = (SELECT COUNT(*) FROM matches WHERE (user1_id = p_user_id OR user2_id = p_user_id)),
        active_matches = (SELECT COUNT(*) FROM matches WHERE (user1_id = p_user_id OR user2_id = p_user_id) AND is_mutual = true AND is_active = true),
        pending_matches = (SELECT COUNT(*) FROM matches WHERE user2_id = p_user_id AND user2_liked = false AND user1_liked = true),
        messages_sent_week = (SELECT COUNT(*) FROM messages WHERE sender_id = p_user_id AND created_at > NOW() - INTERVAL '7 days'),
        messages_received_week = (SELECT COUNT(*) FROM messages WHERE receiver_id = p_user_id AND created_at > NOW() - INTERVAL '7 days'),
        last_updated = NOW()
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;