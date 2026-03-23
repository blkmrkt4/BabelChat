-- Language Lab tables: partner_streaks, user_daily_activity, chat_sessions
-- Plus triggers for practice_minutes accumulation and daily activity updates

-- ============================================================
-- 1. partner_streaks
-- ============================================================
CREATE TABLE IF NOT EXISTS partner_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    partner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    last_interaction_date DATE,
    total_messages INT DEFAULT 0,
    streak_started_at DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, partner_id)
);

ALTER TABLE partner_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own streaks"
    ON partner_streaks FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own streaks"
    ON partner_streaks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own streaks"
    ON partner_streaks FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================================
-- 2. user_daily_activity
-- ============================================================
CREATE TABLE IF NOT EXISTS user_daily_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    activity_date DATE NOT NULL,
    messages_sent INT DEFAULT 0,
    messages_received INT DEFAULT 0,
    target_language_messages INT DEFAULT 0,
    native_language_messages INT DEFAULT 0,
    practice_minutes INT DEFAULT 0,
    unique_partners INT DEFAULT 0,
    UNIQUE(user_id, activity_date)
);

ALTER TABLE user_daily_activity ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own activity"
    ON user_daily_activity FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own activity"
    ON user_daily_activity FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own activity"
    ON user_daily_activity FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================================
-- 3. chat_sessions
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    conversation_id UUID,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    messages_count INT DEFAULT 0
);

ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own sessions"
    ON chat_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
    ON chat_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 4. Trigger: accumulate practice_minutes on upsert
--    Adds incoming value to existing rather than overwriting
-- ============================================================
CREATE OR REPLACE FUNCTION accumulate_practice_minutes()
RETURNS TRIGGER AS $$
BEGIN
    -- On conflict (upsert), add practice_minutes to existing value
    IF TG_OP = 'UPDATE' THEN
        NEW.practice_minutes := OLD.practice_minutes + NEW.practice_minutes;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_accumulate_practice_minutes
    BEFORE UPDATE ON user_daily_activity
    FOR EACH ROW
    EXECUTE FUNCTION accumulate_practice_minutes();

-- ============================================================
-- 5. Trigger: update daily activity & partner streaks on message insert
-- ============================================================
CREATE OR REPLACE FUNCTION update_daily_activity_on_message()
RETURNS TRIGGER AS $$
DECLARE
    v_today DATE := CURRENT_DATE;
    v_sender_native TEXT;
    v_is_target BOOLEAN;
    v_existing_partners INT;
BEGIN
    -- Get sender's native language to determine if this message is in target language
    SELECT native_language INTO v_sender_native
    FROM profiles
    WHERE id = NEW.sender_id;

    -- If original_language differs from sender's native, it's a target language message
    v_is_target := (NEW.original_language IS NOT NULL AND NEW.original_language != v_sender_native);

    -- Upsert sender's daily activity (messages_sent)
    INSERT INTO user_daily_activity (user_id, activity_date, messages_sent, target_language_messages, native_language_messages)
    VALUES (
        NEW.sender_id,
        v_today,
        1,
        CASE WHEN v_is_target THEN 1 ELSE 0 END,
        CASE WHEN v_is_target THEN 0 ELSE 1 END
    )
    ON CONFLICT (user_id, activity_date)
    DO UPDATE SET
        messages_sent = user_daily_activity.messages_sent + 1,
        target_language_messages = user_daily_activity.target_language_messages + CASE WHEN v_is_target THEN 1 ELSE 0 END,
        native_language_messages = user_daily_activity.native_language_messages + CASE WHEN v_is_target THEN 0 ELSE 1 END;

    -- Upsert receiver's daily activity (messages_received)
    INSERT INTO user_daily_activity (user_id, activity_date, messages_received)
    VALUES (NEW.receiver_id, v_today, 1)
    ON CONFLICT (user_id, activity_date)
    DO UPDATE SET
        messages_received = user_daily_activity.messages_received + 1;

    -- Update unique_partners for sender if this is a new partner today
    SELECT COUNT(DISTINCT m2.receiver_id)
    INTO v_existing_partners
    FROM messages m2
    WHERE m2.sender_id = NEW.sender_id
      AND m2.created_at::date = v_today
      AND m2.id != NEW.id;

    -- Check if receiver was already contacted today
    IF NOT EXISTS (
        SELECT 1 FROM messages m2
        WHERE m2.sender_id = NEW.sender_id
          AND m2.receiver_id = NEW.receiver_id
          AND m2.created_at::date = v_today
          AND m2.id != NEW.id
    ) THEN
        UPDATE user_daily_activity
        SET unique_partners = unique_partners + 1
        WHERE user_id = NEW.sender_id AND activity_date = v_today;
    END IF;

    -- Upsert partner_streaks
    INSERT INTO partner_streaks (user_id, partner_id, current_streak, longest_streak, last_interaction_date, total_messages, streak_started_at)
    VALUES (NEW.sender_id, NEW.receiver_id, 1, 1, v_today, 1, v_today)
    ON CONFLICT (user_id, partner_id)
    DO UPDATE SET
        total_messages = partner_streaks.total_messages + 1,
        current_streak = CASE
            WHEN partner_streaks.last_interaction_date = v_today THEN partner_streaks.current_streak -- same day, no change
            WHEN partner_streaks.last_interaction_date = v_today - 1 THEN partner_streaks.current_streak + 1 -- consecutive day
            ELSE 1 -- streak broken, reset
        END,
        longest_streak = GREATEST(
            partner_streaks.longest_streak,
            CASE
                WHEN partner_streaks.last_interaction_date = v_today THEN partner_streaks.current_streak
                WHEN partner_streaks.last_interaction_date = v_today - 1 THEN partner_streaks.current_streak + 1
                ELSE 1
            END
        ),
        last_interaction_date = v_today,
        streak_started_at = CASE
            WHEN partner_streaks.last_interaction_date = v_today THEN partner_streaks.streak_started_at
            WHEN partner_streaks.last_interaction_date = v_today - 1 THEN partner_streaks.streak_started_at
            ELSE v_today -- streak broken, new start
        END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_update_daily_activity_on_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_activity_on_message();

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_partner_streaks_user_id ON partner_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_user_daily_activity_user_date ON user_daily_activity(user_id, activity_date);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id ON chat_sessions(user_id);
