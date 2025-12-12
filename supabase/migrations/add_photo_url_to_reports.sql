-- Add photo_url column to reported_users table to track specific reported photos
ALTER TABLE reported_users ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Add index for faster querying by status
CREATE INDEX IF NOT EXISTS idx_reported_users_status ON reported_users(status);

-- Add index for sorting by creation date
CREATE INDEX IF NOT EXISTS idx_reported_users_created_at ON reported_users(created_at DESC);

-- Add comment to document the column
COMMENT ON COLUMN reported_users.photo_url IS 'Storage path or signed URL of the reported photo';
