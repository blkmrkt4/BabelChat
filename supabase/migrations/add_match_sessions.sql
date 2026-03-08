-- Match Sessions: Live Video/Audio Language Practice
-- Migration for sessions, participants, messages, and invites

-- Sessions table
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT,
    language_pair JSONB NOT NULL,  -- {"native": "English", "learning": "French"}
    status TEXT NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled', 'live', 'ended', 'cancelled')),
    is_open BOOLEAN DEFAULT false,
    scheduled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    max_duration_minutes INTEGER DEFAULT 60,
    participant_count INTEGER DEFAULT 0,
    livekit_room_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE sessions REPLICA IDENTITY FULL;

-- Session participants table
CREATE TABLE session_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'listener'
        CHECK (role IN ('host', 'co_speaker', 'rotating_speaker', 'listener')),
    is_hand_raised BOOLEAN DEFAULT false,
    hand_raised_at TIMESTAMPTZ,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    left_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    UNIQUE (session_id, user_id)
);
ALTER TABLE session_participants REPLICA IDENTITY FULL;

-- Session messages table
CREATE TABLE session_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    original_text TEXT NOT NULL,
    original_language TEXT NOT NULL,
    translated_text JSONB DEFAULT '{}',
    ai_insights JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE session_messages REPLICA IDENTITY FULL;

-- Session invites table (pre-assigned co-speakers)
CREATE TABLE session_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'co_speaker',
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (session_id, invitee_id)
);

-- Indexes
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_sessions_host_id ON sessions(host_id);
CREATE INDEX idx_sessions_scheduled_at ON sessions(scheduled_at);
CREATE INDEX idx_sessions_language_pair ON sessions USING GIN (language_pair);
CREATE INDEX idx_session_participants_session_id ON session_participants(session_id);
CREATE INDEX idx_session_participants_user_id ON session_participants(user_id);
CREATE INDEX idx_session_messages_session_id ON session_messages(session_id);
CREATE INDEX idx_session_invites_invitee_status ON session_invites(invitee_id, status);

-- RLS Policies
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_invites ENABLE ROW LEVEL SECURITY;

-- Sessions: readable by all authenticated users
CREATE POLICY "Sessions are viewable by authenticated users"
    ON sessions FOR SELECT
    TO authenticated
    USING (true);

-- Sessions: creatable by authenticated users
CREATE POLICY "Users can create sessions"
    ON sessions FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = host_id);

-- Sessions: updatable by host only
CREATE POLICY "Host can update their sessions"
    ON sessions FOR UPDATE
    TO authenticated
    USING (auth.uid() = host_id);

-- Sessions: deletable by host only
CREATE POLICY "Host can delete their sessions"
    ON sessions FOR DELETE
    TO authenticated
    USING (auth.uid() = host_id);

-- Participants: readable by session participants
CREATE POLICY "Participants are viewable by authenticated users"
    ON session_participants FOR SELECT
    TO authenticated
    USING (true);

-- Participants: users can join sessions
CREATE POLICY "Users can join sessions"
    ON session_participants FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Participants: users can update their own participation, host can update any
CREATE POLICY "Users can update own participation or host can update"
    ON session_participants FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = user_id OR
        auth.uid() IN (SELECT host_id FROM sessions WHERE id = session_id)
    );

-- Messages: readable by active participants
CREATE POLICY "Session messages viewable by participants"
    ON session_messages FOR SELECT
    TO authenticated
    USING (
        session_id IN (
            SELECT session_id FROM session_participants
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- Messages: sendable by active participants
CREATE POLICY "Active participants can send messages"
    ON session_messages FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = sender_id AND
        session_id IN (
            SELECT session_id FROM session_participants
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- Invites: readable by inviter or invitee
CREATE POLICY "Invites viewable by inviter or invitee"
    ON session_invites FOR SELECT
    TO authenticated
    USING (auth.uid() = inviter_id OR auth.uid() = invitee_id);

-- Invites: creatable by inviter
CREATE POLICY "Users can create invites"
    ON session_invites FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = inviter_id);

-- Invites: updatable by invitee (accept/decline)
CREATE POLICY "Invitees can respond to invites"
    ON session_invites FOR UPDATE
    TO authenticated
    USING (auth.uid() = invitee_id);

-- Function to update participant count
CREATE OR REPLACE FUNCTION update_session_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE sessions
    SET participant_count = (
        SELECT COUNT(*) FROM session_participants
        WHERE session_id = COALESCE(NEW.session_id, OLD.session_id)
        AND is_active = true
    )
    WHERE id = COALESCE(NEW.session_id, OLD.session_id);
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_update_session_participant_count
    AFTER INSERT OR UPDATE OR DELETE ON session_participants
    FOR EACH ROW EXECUTE FUNCTION update_session_participant_count();

-- RPC: Get discoverable sessions for a user
-- Returns sessions where: user is host, has direct match with host,
-- has 2nd-degree match sharing language pair, or session is open
CREATE OR REPLACE FUNCTION get_discoverable_sessions(p_user_id UUID)
RETURNS SETOF sessions AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT s.*
    FROM sessions s
    WHERE s.status IN ('scheduled', 'live')
    AND (
        -- User is the host
        s.host_id = p_user_id
        -- User has a direct mutual match with the host
        OR EXISTS (
            SELECT 1 FROM matches m
            WHERE m.is_mutual = true
            AND (
                (m.user1_id = p_user_id AND m.user2_id = s.host_id)
                OR (m.user1_id = s.host_id AND m.user2_id = p_user_id)
            )
        )
        -- Session is open and user shares the language pair
        OR (
            s.is_open = true
            AND EXISTS (
                SELECT 1 FROM profiles p
                WHERE p.id = p_user_id
                AND (
                    p.native_language = s.language_pair->>'native'
                    OR p.native_language = s.language_pair->>'learning'
                    OR s.language_pair->>'native' = ANY(
                        SELECT jsonb_array_elements_text(p.learning_languages)
                    )
                    OR s.language_pair->>'learning' = ANY(
                        SELECT jsonb_array_elements_text(p.learning_languages)
                    )
                )
            )
        )
        -- User is already a participant
        OR EXISTS (
            SELECT 1 FROM session_participants sp
            WHERE sp.session_id = s.id
            AND sp.user_id = p_user_id
            AND sp.is_active = true
        )
        -- User has an invite
        OR EXISTS (
            SELECT 1 FROM session_invites si
            WHERE si.session_id = s.id
            AND si.invitee_id = p_user_id
            AND si.status = 'pending'
        )
    )
    ORDER BY
        CASE s.status
            WHEN 'live' THEN 0
            WHEN 'scheduled' THEN 1
        END,
        s.scheduled_at ASC NULLS LAST,
        s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
