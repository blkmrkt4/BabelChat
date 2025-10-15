# Fix Supabase Trigger for User Creation

The app is failing to create users because the `handle_new_user()` trigger doesn't set required fields properly.

## Steps to Fix (Run this in Supabase SQL Editor):

1. Go to https://supabase.com/dashboard
2. Select your project: `ckhukylfoeofvoxvwwin`
3. Click "SQL Editor" in the left sidebar
4. Click "New query"
5. Paste and run this SQL:

```sql
-- Fix the handle_new_user trigger to set required fields with defaults
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email, first_name, native_language)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'first_name', 'User'),
        COALESCE(new.raw_user_meta_data->>'native_language', 'English')
    )
    ON CONFLICT (id) DO NOTHING;

    -- Create default preferences
    INSERT INTO public.user_preferences (user_id)
    VALUES (new.id)
    ON CONFLICT (user_id) DO NOTHING;

    -- Create language lab stats
    INSERT INTO public.language_lab_stats (user_id)
    VALUES (new.id)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

6. Click "Run" (or press Cmd/Ctrl + Enter)

## Alternative: Create Test User Manually

If you want to quickly create a test user without fixing the trigger:

```sql
-- 1. First, create the auth user
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'test@langchat.com',
    crypt('testpassword123', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    NOW(),
    NOW(),
    '',
    ''
) RETURNING id;

-- 2. Copy the returned UUID, then create the profile (replace YOUR_USER_ID with the UUID from step 1)
INSERT INTO public.profiles (id, email, first_name, native_language, onboarding_completed)
VALUES (
    'YOUR_USER_ID_HERE',  -- Replace with UUID from previous query
    'test@langchat.com',
    'Test',
    'English',
    true
);
```

## After Running Either Fix:

Run this from the terminal to test that sign-in now works:

```bash
node create_test_user.js
```

You should see:
```
✅ User created successfully
✅ Profile created successfully
🎉 Test user is ready!
```
