-- Track Muse (AI bot) interactions separately from real messages
-- This allows monitoring Muse usage without storing actual message content

CREATE TABLE IF NOT EXISTS muse_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    muse_id TEXT NOT NULL,           -- e.g., "ai_bot_sophie"
    muse_name TEXT NOT NULL,         -- e.g., "Sophie"
    language TEXT NOT NULL,          -- e.g., "French"
    interaction_type TEXT NOT NULL DEFAULT 'message',  -- 'message', 'tts_play', etc.
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_muse_interactions_user_id ON muse_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_muse_interactions_muse_id ON muse_interactions(muse_id);
CREATE INDEX IF NOT EXISTS idx_muse_interactions_created_at ON muse_interactions(created_at);
CREATE INDEX IF NOT EXISTS idx_muse_interactions_language ON muse_interactions(language);

-- Enable RLS
ALTER TABLE muse_interactions ENABLE ROW LEVEL SECURITY;

-- Users can only insert their own interactions
CREATE POLICY "Users can insert own muse interactions"
    ON muse_interactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can read their own interactions
CREATE POLICY "Users can read own muse interactions"
    ON muse_interactions FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can read all (for admin dashboard)
CREATE POLICY "Service role can read all muse interactions"
    ON muse_interactions FOR SELECT
    USING (auth.role() = 'service_role');

-- Grant permissions
GRANT SELECT, INSERT ON muse_interactions TO authenticated;
GRANT ALL ON muse_interactions TO service_role;
