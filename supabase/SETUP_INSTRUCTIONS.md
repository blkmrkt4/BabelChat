# 🚀 Supabase Database Setup Instructions

## Quick Setup (5 minutes)

Since the Supabase REST API doesn't support arbitrary SQL execution, you'll need to manually execute the schema in the Supabase SQL Editor.

### Option 1: Execute All At Once (Easiest)

1. Open your Supabase SQL Editor:
   **https://supabase.com/dashboard/project/ckhukylfoeofvoxvwwin/sql**

2. Click **"New Query"**

3. Copy and paste the entire contents of `combined_schema.sql`

4. Click **"Run"** (or press Cmd/Ctrl + Enter)

5. Wait for execution to complete (~10-15 seconds)

6. Verify success by checking for error messages

### Option 2: Execute Individual Files (More Control)

Execute these files **in order** through the Supabase SQL Editor:

1. ✅ `01_extensions_and_tables.sql` - Core tables (profiles, matches, swipes)
2. ✅ `02_messaging_tables.sql` - Messaging tables (conversations, messages)
3. ✅ `03_stats_and_admin_tables.sql` - Stats and admin tables
4. ✅ `04_indexes.sql` - Performance indexes
5. ✅ `05_rls_policies.sql` - Row Level Security policies
6. ✅ `06_functions_and_triggers.sql` - Database functions and triggers

For each file:
- Open the file in your editor
- Copy entire contents
- Paste into Supabase SQL Editor
- Click "Run"
- Wait for success confirmation

## ✅ Verify Setup

After running the schema, verify everything is set up correctly:

```sql
-- Check if all tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Expected tables:
-- conversations, language_lab_stats, matches, messages, notifications,
-- profiles, reported_users, saved_phrases, subscriptions, swipes,
-- user_languages, user_preferences
```

```sql
-- Check if RLS is enabled on all tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- All should show: rowsecurity = true
```

```sql
-- Check if real-time is enabled for messages
SELECT schemaname, tablename, replicaidentity
FROM pg_publication_tables
WHERE tablename = 'messages';
```

## 🧪 Test with Sample Data

Once setup is complete, you can test by inserting a sample profile:

⚠️ **Note**: This requires an actual authenticated user ID from Supabase Auth.
You'll do this through your iOS app after implementing authentication.

## ⚡ Enable Real-time

Make sure Real-time is enabled for the `messages` table:

1. Go to **Database** → **Replication** in Supabase Dashboard
2. Find the `messages` table
3. Toggle replication to **ON**

## 🔒 Security Notes

- All tables have Row Level Security (RLS) enabled
- Users can only access their own data
- Public profiles are visible for matching purposes
- Messages are only visible to participants

## 📱 Next Steps

After database setup:

1. ✅ Implement Sign in with Apple authentication
2. ✅ Create Supabase service layer in iOS app
3. ✅ Test user registration and profile creation
4. ✅ Implement real-time messaging
5. ✅ Build matching algorithm

## 🐛 Troubleshooting

### "Extension does not exist" errors
- Your Supabase plan should support `uuid-ossp` and `pgcrypto`
- These are available on all plans including free tier

### "Permission denied" errors
- Make sure you're logged in with proper admin access
- SQL Editor should have full permissions by default

### Foreign key constraint errors
- Make sure you executed files in the correct order
- Try executing the combined schema file instead

### Real-time not working
- Check Database → Replication settings
- Ensure `messages` table has replication enabled
- Verify REPLICA IDENTITY is set to FULL

## 📊 Database Schema Summary

### Core Tables
- **profiles** (12 columns) - User profiles extending auth.users
- **user_languages** (8 columns) - Detailed language preferences
- **matches** (11 columns) - Match relationships
- **swipes** (6 columns) - Swipe history

### Communication
- **conversations** (10 columns) - Chat conversations
- **messages** (12 columns) - Individual messages with AI translations
- **saved_phrases** (9 columns) - User's saved vocabulary

### Supporting Tables
- **user_preferences** (8 columns) - App settings
- **language_lab_stats** (9 columns) - Learning metrics
- **notifications** (10 columns) - Push notification queue
- **reported_users** (8 columns) - Safety/moderation
- **subscriptions** (9 columns) - Premium subscriptions

### Indexes (23 total)
- Performance indexes on foreign keys
- Composite indexes for common queries
- Text search indexes for profiles

### Functions & Triggers (6 total)
- Auto-update timestamps
- Conversation counters
- Match creation logic
- User activity tracking

## 💡 Tips

- The combined_schema.sql file is regenerated and always contains the latest complete schema
- You can safely re-run the schema (uses `IF NOT EXISTS` and `IF EXISTS`)
- Back up your database before making major changes
- Use Supabase's built-in backup feature regularly
