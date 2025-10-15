-- Fix the handle_new_user trigger to set required fields
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
