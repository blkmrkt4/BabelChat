-- ============================================================================
-- Create Demo Auth User for App Store Review
-- ============================================================================
-- Run this FIRST, then run demo_account_setup.sql
-- ============================================================================

-- Generate a UUID for the demo user
DO $$
DECLARE
    new_user_id UUID := gen_random_uuid();
BEGIN
    -- Insert into auth.users table
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        role,
        aud,
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change
    ) VALUES (
        new_user_id,
        '00000000-0000-0000-0000-000000000000',
        'appreview@byzyb.ai',
        crypt('123456', gen_salt('bf')),  -- Password: 123456
        NOW(),  -- Email confirmed
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        '{}'::jsonb,
        false,
        'authenticated',
        'authenticated',
        '',
        '',
        '',
        ''
    );

    -- Also insert into auth.identities (required for email login)
    INSERT INTO auth.identities (
        id,
        user_id,
        provider_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        new_user_id,
        'appreview@byzyb.ai',
        jsonb_build_object(
            'sub', new_user_id::text,
            'email', 'appreview@byzyb.ai',
            'email_verified', true,
            'provider', 'email'
        ),
        'email',
        NOW(),
        NOW(),
        NOW()
    );

    -- Output the UUID so you can use it in the next script
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Demo auth user created successfully!';
    RAISE NOTICE 'User ID: %', new_user_id;
    RAISE NOTICE '============================================';
    RAISE NOTICE 'NEXT STEP: Copy this UUID and replace';
    RAISE NOTICE 'DEMO_USER_UUID_HERE in demo_account_setup.sql';
    RAISE NOTICE '============================================';

END $$;

-- Verify the user was created
SELECT id, email, email_confirmed_at, created_at
FROM auth.users
WHERE email = 'appreview@byzyb.ai';
