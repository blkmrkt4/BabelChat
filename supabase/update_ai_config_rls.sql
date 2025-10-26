-- Update RLS policies for ai_config to allow web admin access
-- The web admin uses the anon key, so we need to allow anon role to update

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Only admins can modify AI configs" ON ai_config;
DROP POLICY IF EXISTS "Anyone can read active AI configs" ON ai_config;

-- Create new policies allowing anon role full access
-- (In production, you'd want to add additional security like API key checks)

-- Allow anyone to read all configs
CREATE POLICY "Allow anon read access to ai_config"
ON ai_config FOR SELECT
USING (true);

-- Allow anyone to update configs (for web admin)
CREATE POLICY "Allow anon update access to ai_config"
ON ai_config FOR UPDATE
USING (true)
WITH CHECK (true);

-- Allow anyone to insert configs (for web admin)
CREATE POLICY "Allow anon insert access to ai_config"
ON ai_config FOR INSERT
WITH CHECK (true);
