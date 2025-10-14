#!/bin/bash

# Load environment variables
source ../.env

echo "🚀 Setting up LangChat database in Supabase..."
echo "📍 URL: $SUPABASE_URL"

# Function to execute SQL via Supabase REST API
execute_sql() {
    local sql="$1"
    local description="$2"

    echo "Executing: $description"

    # Note: This approach requires the SQL to be executed via Supabase Dashboard
    # as direct SQL execution via API requires additional setup

    echo "$sql" >> executed_statements.sql
    echo "-- End of: $description" >> executed_statements.sql
    echo "" >> executed_statements.sql
}

# For now, let's output the SQL to be executed manually
echo "Generating SQL script..."

cp schema.sql langchat_complete_schema.sql

echo "
✅ SQL script generated: langchat_complete_schema.sql

📋 Next steps to complete setup:

1. Open your Supabase Dashboard: $SUPABASE_URL
2. Go to SQL Editor
3. Create a new query
4. Copy and paste the contents of langchat_complete_schema.sql
5. Click 'Run' to execute

This will create all tables, indexes, RLS policies, and triggers.

Alternatively, you can run smaller chunks if needed.
"