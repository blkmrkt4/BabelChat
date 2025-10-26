-- Create model_evaluations table to store all evaluation test results
CREATE TABLE IF NOT EXISTS model_evaluations (
  id TEXT PRIMARY KEY,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Test parameters
  test_input TEXT NOT NULL,
  source_lang TEXT NOT NULL,
  target_lang TEXT NOT NULL,

  -- Baseline info
  baseline_type TEXT NOT NULL CHECK (baseline_type IN ('google', 'model')),
  baseline_model_id TEXT,
  baseline_model_name TEXT,
  google_translate_output TEXT NOT NULL,

  -- Model being tested
  model_id TEXT NOT NULL,
  model_name TEXT NOT NULL,
  model_output TEXT NOT NULL,
  response_time DECIMAL,

  -- Evaluation info
  evaluation_model_id TEXT NOT NULL,
  evaluation_model_name TEXT NOT NULL,
  model_prompt TEXT,
  evaluation_prompt TEXT,

  -- Scores
  score DECIMAL NOT NULL,
  scores JSONB,  -- Legacy multi-dimensional scores
  detailed_scores JSONB,  -- New detailed scoring breakdown
  evaluation TEXT NOT NULL,
  category TEXT NOT NULL,

  -- Error tracking
  error TEXT,
  error_type TEXT CHECK (error_type IN ('json_parse', 'api_error', 'timeout', 'unknown')),

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_model_evaluations_category ON model_evaluations(category);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_model_id ON model_evaluations(model_id);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_timestamp ON model_evaluations(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_model_evaluations_category_timestamp ON model_evaluations(category, timestamp DESC);

-- Enable Row Level Security
ALTER TABLE model_evaluations ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (adjust based on your auth requirements)
CREATE POLICY "Allow all operations on model_evaluations" ON model_evaluations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_model_evaluations_updated_at
  BEFORE UPDATE ON model_evaluations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add comment
COMMENT ON TABLE model_evaluations IS 'Stores results from AI model evaluation tests (round robin evaluations)';
