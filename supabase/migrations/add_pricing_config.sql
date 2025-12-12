-- Pricing configuration table for dynamic pricing management
CREATE TABLE IF NOT EXISTS pricing_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Premium pricing
  premium_price_usd DECIMAL(10,2) NOT NULL DEFAULT 9.99,
  premium_banner TEXT NOT NULL DEFAULT '7-Day Free Trial • Cancel Anytime',

  -- Premium features (JSON array of features)
  premium_features JSONB NOT NULL DEFAULT '[
    {"title": "Unlimited AI Chat Messages", "subtitle": "Practice without limits"},
    {"title": "Unlimited Profile Views", "subtitle": "Browse all potential matches"},
    {"title": "Direct Messaging", "subtitle": "Chat directly with matches"},
    {"title": "Full Conversation History", "subtitle": "Access all your past chats"},
    {"title": "All Language Pairs", "subtitle": "Learn any language combination"},
    {"title": "Grammar Tips & Insights", "subtitle": "AI-powered learning assistance"}
  ]'::jsonb,

  -- Free tier features (JSON array of features)
  free_features JSONB NOT NULL DEFAULT '[
    {"title": "5 AI Chat Messages/Day", "subtitle": "Practice with AI assistance", "included": true},
    {"title": "View 10 Profiles/Day", "subtitle": "Browse potential matches", "included": true},
    {"title": "Unlimited Matches", "subtitle": "Match with learners (AI chat only)", "included": true},
    {"title": "Direct Messaging", "subtitle": "Premium feature", "included": false},
    {"title": "Unlimited Profiles", "subtitle": "Premium feature", "included": false}
  ]'::jsonb,

  -- Metadata
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Insert default config if not exists
INSERT INTO pricing_config (id)
VALUES ('00000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- Enable RLS
ALTER TABLE pricing_config ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read pricing config (for the app)
CREATE POLICY "Anyone can read pricing config"
ON pricing_config FOR SELECT
TO anon, authenticated
USING (true);

-- Only service role can update (admin uses service role)
CREATE POLICY "Service role can update pricing config"
ON pricing_config FOR UPDATE
TO service_role
USING (true);

-- Add comment
COMMENT ON TABLE pricing_config IS 'Stores dynamic pricing configuration for the app';
