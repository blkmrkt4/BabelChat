-- Migration: Add Pro tier columns to pricing_config
-- Run this in Supabase SQL Editor

-- Add Pro tier columns to pricing_config table
ALTER TABLE pricing_config ADD COLUMN IF NOT EXISTS pro_price_usd DECIMAL(10,2) DEFAULT 19.99;
ALTER TABLE pricing_config ADD COLUMN IF NOT EXISTS pro_banner TEXT DEFAULT 'Unlimited Everything';
ALTER TABLE pricing_config ADD COLUMN IF NOT EXISTS pro_features JSONB DEFAULT '[]'::jsonb;

-- Add comments
COMMENT ON COLUMN pricing_config.pro_price_usd IS 'Monthly price for Pro tier in USD';
COMMENT ON COLUMN pricing_config.pro_banner IS 'Marketing banner text for Pro tier';
COMMENT ON COLUMN pricing_config.pro_features IS 'JSON array of Pro tier features';

-- Update with Pro tier features (matches gold standard from iOS app exactly)
UPDATE pricing_config
SET
    pro_price_usd = 19.99,
    pro_banner = 'Best Value for Serious Learners',
    pro_features = '[
        {"title": "Everything in Premium", "included": true, "subtitle": ""},
        {"title": "Unlimited Text-to-Speech plays", "included": true, "subtitle": ""},
        {"title": "Natural voices (Google Neural2)", "included": true, "subtitle": ""},
        {"title": "Higher word limit per play - 150 vs 100 for Premium", "included": true, "subtitle": ""}
    ]'::jsonb,
    premium_banner = '7-Day Free Trial • Cancel Anytime',
    premium_features = '[
        {"title": "Match with real people worldwide", "included": true, "subtitle": ""},
        {"title": "Unlimited messages", "included": true, "subtitle": ""},
        {"title": "Full translation & grammar insights", "included": true, "subtitle": ""},
        {"title": "200 Text-to-Speech plays/month with natural voices", "included": true, "subtitle": ""}
    ]'::jsonb,
    free_features = '[
        {"title": "No matching with real people - AI Muse chats only", "included": true, "subtitle": ""},
        {"title": "50 messages per month", "included": true, "subtitle": ""},
        {"title": "Full translation & grammar insights", "included": true, "subtitle": ""},
        {"title": "Basic text to speech", "included": true, "subtitle": ""}
    ]'::jsonb
WHERE id = '00000000-0000-0000-0000-000000000001';
