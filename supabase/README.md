# LangChat Database Setup

## 📋 Overview

This directory contains all SQL scripts needed to set up the LangChat database in Supabase.

## 🚀 Quick Setup

### Option 1: Execute All at Once

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy and paste the contents of `schema.sql`
5. Click **Run**

### Option 2: Execute in Parts (Recommended)

Execute these files in order through the Supabase SQL Editor:

1. **`01_extensions_and_tables.sql`** - Creates core tables (profiles, matches, swipes)
2. **`02_messaging_tables.sql`** - Creates messaging related tables
3. **`03_stats_and_admin_tables.sql`** - Creates stats and admin tables
4. **`04_indexes.sql`** - Adds performance indexes
5. **`05_rls_policies.sql`** - Sets up Row Level Security
6. **`06_functions_and_triggers.sql`** - Adds functions and triggers

## 📊 Database Schema

### Core Tables
- **profiles** - User profiles and language preferences
- **user_languages** - Detailed language configurations
- **matches** - Match relationships between users
- **swipes** - Swipe history for algorithm

### Communication Tables
- **conversations** - Chat conversations
- **messages** - Individual messages with translations
- **saved_phrases** - User's saved vocabulary

### Support Tables
- **user_preferences** - User settings
- **language_lab_stats** - Dashboard metrics
- **notifications** - Push notification queue
- **reported_users** - Safety/moderation
- **subscriptions** - Premium subscriptions

## 🔒 Security

All tables have Row Level Security (RLS) enabled with appropriate policies:
- Users can only access their own data
- Public profiles visible for matching
- Messages only visible to participants

## ⚡ Real-time Features

The `messages` table has real-time enabled for instant messaging.

To subscribe to messages in your iOS app:
```swift
let channel = supabase
    .channel("messages")
    .on("postgres_changes",
        filter: "conversation_id=eq.\(conversationId)",
        eventType: .insert) { payload in
        // Handle new message
    }
    .subscribe()
```

## 🧪 Testing the Setup

After running the scripts, verify the setup:

```sql
-- Check if all tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';

-- Check if RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';

-- Test creating a user profile (replace with actual UUID)
INSERT INTO profiles (id, email, first_name, native_language)
VALUES (
    gen_random_uuid(),
    'test@example.com',
    'Test User',
    'English'
);
```

## 🔧 Troubleshooting

If you encounter errors:

1. **Extension errors**: Your Supabase plan may not support certain extensions
2. **Permission errors**: Ensure you're using the service role key for setup
3. **Foreign key errors**: Make sure to run scripts in the correct order

## 📝 Notes

- The `auth.users` table is managed by Supabase Auth
- Age verification requires users to be 13+ years old
- All timestamps use `TIMESTAMPTZ` for proper timezone handling
- JSONB columns are used for flexible data like proficiency levels and settings