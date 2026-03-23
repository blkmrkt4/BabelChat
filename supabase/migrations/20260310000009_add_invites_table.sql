-- Invite Links System
-- Allows users to generate invite codes that auto-match new users after signup

-- Create invites table
CREATE TABLE IF NOT EXISTS invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inviter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    code TEXT UNIQUE NOT NULL,  -- Short readable code like "FLU-abc123"
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired')),
    invited_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,  -- Set when accepted
    match_id UUID REFERENCES matches(id) ON DELETE SET NULL,  -- The auto-created match
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days',
    accepted_at TIMESTAMPTZ
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_invites_code ON invites(code);
CREATE INDEX IF NOT EXISTS idx_invites_inviter ON invites(inviter_id);
CREATE INDEX IF NOT EXISTS idx_invites_status ON invites(status);

-- Enable RLS
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can view their own invites (ones they created)
CREATE POLICY "Users can view own invites"
ON invites FOR SELECT
TO authenticated
USING (inviter_id = auth.uid());

-- Users can create invites
CREATE POLICY "Users can create invites"
ON invites FOR INSERT
TO authenticated
WITH CHECK (inviter_id = auth.uid());

-- Anyone can look up an invite by code (for validation during signup)
CREATE POLICY "Anyone can lookup invite by code"
ON invites FOR SELECT
TO anon, authenticated
USING (true);

-- Service role can update invites (for accepting)
CREATE POLICY "Service can update invites"
ON invites FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);

-- Also allow authenticated users to update invites they're accepting
CREATE POLICY "Users can accept invites"
ON invites FOR UPDATE
TO authenticated
USING (status = 'pending')
WITH CHECK (invited_user_id = auth.uid());

-- Function to generate a unique invite code
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate code: FLU- followed by 6 random alphanumeric chars
        new_code := 'FLU-' || upper(substring(md5(random()::text) from 1 for 6));

        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM invites WHERE code = new_code) INTO code_exists;

        -- Exit loop if code is unique
        EXIT WHEN NOT code_exists;
    END LOOP;

    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- Function to create an invite (returns the invite code)
CREATE OR REPLACE FUNCTION create_invite(p_inviter_id UUID)
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
BEGIN
    new_code := generate_invite_code();

    INSERT INTO invites (inviter_id, code)
    VALUES (p_inviter_id, new_code);

    RETURN new_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept an invite and create auto-match
CREATE OR REPLACE FUNCTION accept_invite(p_code TEXT, p_new_user_id UUID)
RETURNS JSON AS $$
DECLARE
    v_invite RECORD;
    v_match_id UUID;
    v_inviter_name TEXT;
BEGIN
    -- Get the invite
    SELECT * INTO v_invite
    FROM invites
    WHERE code = p_code
    AND status = 'pending'
    AND expires_at > NOW();

    -- Check if invite exists and is valid
    IF v_invite IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid or expired invite code'
        );
    END IF;

    -- Check that user isn't inviting themselves
    IF v_invite.inviter_id = p_new_user_id THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cannot accept your own invite'
        );
    END IF;

    -- Create the auto-match (mutual match)
    INSERT INTO matches (user1_id, user2_id, user1_liked, user2_liked)
    VALUES (v_invite.inviter_id, p_new_user_id, true, true)
    RETURNING id INTO v_match_id;

    -- Update the invite
    UPDATE invites
    SET status = 'accepted',
        invited_user_id = p_new_user_id,
        match_id = v_match_id,
        accepted_at = NOW()
    WHERE id = v_invite.id;

    -- Get inviter name for confirmation message
    SELECT name INTO v_inviter_name
    FROM profiles
    WHERE id = v_invite.inviter_id;

    RETURN json_build_object(
        'success', true,
        'match_id', v_match_id,
        'inviter_name', v_inviter_name,
        'inviter_id', v_invite.inviter_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_invite(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_invite(TEXT, UUID) TO authenticated, anon;
