-- Store user consent/acceptance of legal documents (Terms, Privacy Policy, EULA, etc.)
-- Required for compliance: UserDefaults alone is not sufficient.

CREATE TABLE IF NOT EXISTS consent_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,       -- 'terms_of_service', 'privacy_policy', 'eula', 'community_guidelines'
    document_version TEXT NOT NULL,    -- e.g. '1.0', '2024-01-15'
    accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast lookup by user
CREATE INDEX idx_consent_records_user_id ON consent_records(user_id);

-- Unique constraint: one acceptance per document type per version per user
CREATE UNIQUE INDEX idx_consent_records_unique
    ON consent_records(user_id, document_type, document_version);

-- RLS policies
ALTER TABLE consent_records ENABLE ROW LEVEL SECURITY;

-- Users can insert their own consent records
CREATE POLICY consent_records_insert ON consent_records
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Users can read their own consent records
CREATE POLICY consent_records_select ON consent_records
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);
