-- Add weekly_pricing_countries column to pricing_config table
-- This stores which countries should see weekly price display (e.g., "$2.31/wk" instead of "$9.99/mo")

-- Add the column with default emerging markets
ALTER TABLE pricing_config
ADD COLUMN IF NOT EXISTS weekly_pricing_countries TEXT[] DEFAULT ARRAY['IN', 'BR', 'MX', 'ID', 'PH', 'VN', 'TH', 'MY'];

-- Add comment for documentation
COMMENT ON COLUMN pricing_config.weekly_pricing_countries IS 'ISO country codes where prices are displayed as weekly equivalent (still billed monthly)';
