-- Add RLS policies for model_evaluations table
-- This table is used by the web-admin to store AI model evaluation results

-- First, check if RLS is enabled (if not, enable it)
ALTER TABLE IF EXISTS model_evaluations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON model_evaluations;
DROP POLICY IF EXISTS "Allow read for anon" ON model_evaluations;

-- Policy: Allow authenticated users full access (for web-admin)
CREATE POLICY "Allow all operations for authenticated users"
ON model_evaluations
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy: Allow anon users to read (for web-admin before login)
-- Note: The web-admin requires login, so this is mainly for initial page load
CREATE POLICY "Allow read for anon"
ON model_evaluations
FOR SELECT
TO anon
USING (true);

-- Also allow anon to insert (for evaluation runs before auth check)
CREATE POLICY "Allow insert for anon"
ON model_evaluations
FOR INSERT
TO anon
WITH CHECK (true);
