-- Migration: Add feedback table for feature requests and bug reports
-- This allows users to submit feature requests from the app

CREATE TABLE IF NOT EXISTS feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    type VARCHAR(50) NOT NULL, -- 'feature_request', 'bug_report', 'general', 'contact_support'
    message TEXT NOT NULL,
    app_version VARCHAR(20),
    device_info TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'reviewed', 'planned', 'completed', 'declined'
    admin_notes TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for efficient filtering by status and type
CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback(status);
CREATE INDEX IF NOT EXISTS idx_feedback_type ON feedback(type);
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON feedback(created_at DESC);

-- Enable RLS
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Users can insert their own feedback
CREATE POLICY "Users can insert feedback" ON feedback
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Users can view their own feedback
CREATE POLICY "Users can view own feedback" ON feedback
    FOR SELECT USING (auth.uid() = user_id);

-- Comment for documentation
COMMENT ON TABLE feedback IS 'User feedback including feature requests, bug reports, and support messages';
COMMENT ON COLUMN feedback.type IS 'Type of feedback: feature_request, bug_report, general, contact_support';
COMMENT ON COLUMN feedback.status IS 'Status: pending, reviewed, planned, completed, declined';
