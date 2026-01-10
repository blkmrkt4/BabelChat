-- ============================================================================
-- App Store Review Demo Account Setup
-- ============================================================================
--
-- INSTRUCTIONS:
-- 1. First, create the auth user in Supabase Dashboard:
--    - Go to Authentication > Users > Add User
--    - Email: appreview@byzyb.ai
--    - Password: 123456
--    - Check "Auto Confirm User"
--    - Copy the generated UUID
--
-- 2. Replace 'DEMO_USER_UUID_HERE' below with the actual UUID
--
-- 3. Run this script in Supabase SQL Editor
-- ============================================================================

-- Set the demo user UUID
DO $$
DECLARE
    demo_user_id UUID := '2b89fd98-a443-459a-8e1a-fb0922b0a536';  -- App Review demo account

    -- Test profile UUIDs (fixed for consistency)
    marie_id UUID := 'a1000001-0001-0001-0001-000000000001';
    lucas_id UUID := 'a1000001-0001-0001-0001-000000000002';
    sofia_id UUID := 'a1000001-0001-0001-0001-000000000003';
    carlos_id UUID := 'a1000001-0001-0001-0001-000000000004';
    camille_id UUID := 'a1000001-0001-0001-0001-000000000005';
    antoine_id UUID := 'a1000001-0001-0001-0001-000000000006';
    isabella_id UUID := 'a1000001-0001-0001-0001-000000000007';
    diego_id UUID := 'a1000001-0001-0001-0001-000000000008';
    emma_id UUID := 'a1000001-0001-0001-0001-000000000009';
    james_id UUID := 'a1000001-0001-0001-0001-000000000010';
    lucia_id UUID := 'a1000001-0001-0001-0001-000000000011';
    pierre_id UUID := 'a1000001-0001-0001-0001-000000000012';

    -- Match and conversation IDs
    match1_id UUID;
    match2_id UUID;
    match3_id UUID;
    match4_id UUID;
    conv1_id UUID;
    conv2_id UUID;
    conv3_id UUID;
    conv4_id UUID;

BEGIN
    -- ========================================================================
    -- STEP 1: Create Demo User Profile
    -- ========================================================================
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        show_city_in_profile, native_language, learning_languages,
        proficiency_levels, profile_photos, onboarding_completed, last_active,
        gender, gender_preference, min_age, max_age, location_preference,
        latitude, longitude, strictly_platonic, subscription_tier,
        open_to_languages, allow_non_native_matches
    ) VALUES (
        demo_user_id,
        'appreview@byzyb.ai',
        'Hannah',
        'Apple',
        'Hi! I''m Hannah and I live in the UK. I''m passionate about learning French and Spanish, and I''d love to help others with their English. I have a trip to Paris coming up so I''m especially focused on French right now!',
        1995,
        'London, United Kingdom',
        true,
        'English',
        ARRAY['French', 'Spanish'],
        '{"French": "beginner", "Spanish": "beginner"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/women/44.jpg',
            'https://i.pravatar.cc/400?img=45',
            'https://i.pravatar.cc/400?img=46',
            'https://i.pravatar.cc/400?img=47',
            'https://i.pravatar.cc/400?img=48',
            'https://i.pravatar.cc/400?img=49',
            'https://i.pravatar.cc/400?img=32'
        ],
        true,
        NOW(),
        'female',
        'all',
        18,
        99,
        'anywhere',
        51.5074,
        -0.1278,
        true,
        'pro',
        ARRAY['English'],
        false
    ) ON CONFLICT (id) DO UPDATE SET
        subscription_tier = 'pro',
        onboarding_completed = true;

    -- ========================================================================
    -- STEP 2: Create Test Profiles (12 total)
    -- ========================================================================

    -- Profile 1: Marie (French, Female) - WILL BE MATCHED
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        marie_id,
        'marie.demo@test.langchat.com',
        'Marie',
        'Dubois',
        'Bonjour! I''m a graphic designer from Paris who loves to travel. I want to improve my English for work and to make friends from around the world. I can help you with French - let''s practice together!',
        1994,
        'Paris, France',
        'French',
        ARRAY['English'],
        '{"English": "intermediate"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/women/1.jpg',
            'https://i.pravatar.cc/400?img=1',
            'https://i.pravatar.cc/400?img=2',
            'https://i.pravatar.cc/400?img=3',
            'https://i.pravatar.cc/400?img=4',
            'https://i.pravatar.cc/400?img=5',
            'https://i.pravatar.cc/400?img=6'
        ],
        true,
        NOW() - INTERVAL '2 hours',
        'female',
        'all',
        20,
        45,
        'anywhere',
        48.8566,
        2.3522,
        true,
        'free',
        ARRAY['French'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 2: Lucas (French, Male) - WILL BE MATCHED
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        lucas_id,
        'lucas.demo@test.langchat.com',
        'Lucas',
        'Martin',
        'Salut! I''m a software developer from Lyon. I love cooking, hiking, and learning new languages. Looking for language exchange partners to improve my English while helping with French.',
        1992,
        'Lyon, France',
        'French',
        ARRAY['English'],
        '{"English": "intermediate"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/men/1.jpg',
            'https://i.pravatar.cc/400?img=11',
            'https://i.pravatar.cc/400?img=12',
            'https://i.pravatar.cc/400?img=13',
            'https://i.pravatar.cc/400?img=14',
            'https://i.pravatar.cc/400?img=15',
            'https://i.pravatar.cc/400?img=16'
        ],
        true,
        NOW() - INTERVAL '1 hour',
        'male',
        'all',
        20,
        50,
        'anywhere',
        45.7640,
        4.8357,
        true,
        'free',
        ARRAY['French'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 3: Sofia (Spanish, Female) - WILL BE MATCHED
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        sofia_id,
        'sofia.demo@test.langchat.com',
        'Sofia',
        'Garcia',
        'Hola! I''m a teacher from Madrid who loves reading and exploring new cultures. I want to practice English and I can help you with Spanish. Let''s learn from each other!',
        1996,
        'Madrid, Spain',
        'Spanish',
        ARRAY['English'],
        '{"English": "intermediate"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/women/2.jpg',
            'https://i.pravatar.cc/400?img=21',
            'https://i.pravatar.cc/400?img=22',
            'https://i.pravatar.cc/400?img=23',
            'https://i.pravatar.cc/400?img=24',
            'https://i.pravatar.cc/400?img=25',
            'https://i.pravatar.cc/400?img=26'
        ],
        true,
        NOW() - INTERVAL '30 minutes',
        'female',
        'all',
        22,
        40,
        'anywhere',
        40.4168,
        -3.7038,
        true,
        'free',
        ARRAY['Spanish'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 4: Carlos (Spanish, Male) - WILL BE MATCHED
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        carlos_id,
        'carlos.demo@test.langchat.com',
        'Carlos',
        'Rodriguez',
        'Hola amigos! I''m an architect from Barcelona. I love design, photography, and traveling. Looking to improve my English skills while sharing my Spanish knowledge.',
        1990,
        'Barcelona, Spain',
        'Spanish',
        ARRAY['English'],
        '{"English": "intermediate"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/men/2.jpg',
            'https://i.pravatar.cc/400?img=31',
            'https://i.pravatar.cc/400?img=33',
            'https://i.pravatar.cc/400?img=34',
            'https://i.pravatar.cc/400?img=35',
            'https://i.pravatar.cc/400?img=36',
            'https://i.pravatar.cc/400?img=37'
        ],
        true,
        NOW() - INTERVAL '3 hours',
        'male',
        'all',
        25,
        50,
        'anywhere',
        41.3851,
        2.1734,
        true,
        'free',
        ARRAY['Spanish'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 5: Camille (French, Female) - DISCOVERY
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        camille_id,
        'camille.demo@test.langchat.com',
        'Camille',
        'Leroy',
        'Coucou! I''m a marine biologist living in Nice. I spend my weekends at the beach and love discussing environmental topics. Would love to practice English with someone!',
        1993,
        'Nice, France',
        'French',
        ARRAY['English'],
        '{"English": "beginner"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/women/3.jpg',
            'https://i.pravatar.cc/400?img=41',
            'https://i.pravatar.cc/400?img=42',
            'https://i.pravatar.cc/400?img=43',
            'https://i.pravatar.cc/400?img=44',
            'https://i.pravatar.cc/400?img=9',
            'https://i.pravatar.cc/400?img=10'
        ],
        true,
        NOW() - INTERVAL '4 hours',
        'female',
        'all',
        22,
        45,
        'anywhere',
        43.7102,
        7.2620,
        true,
        'free',
        ARRAY['French'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 6: Antoine (French, Male) - DISCOVERY
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        antoine_id,
        'antoine.demo@test.langchat.com',
        'Antoine',
        'Bernard',
        'Bonjour! I''m a wine sommelier from Bordeaux. I love sharing stories about French wine culture and cuisine. Looking to improve my English for international clients.',
        1988,
        'Bordeaux, France',
        'French',
        ARRAY['English'],
        '{"English": "intermediate"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/men/3.jpg',
            'https://i.pravatar.cc/400?img=51',
            'https://i.pravatar.cc/400?img=52',
            'https://i.pravatar.cc/400?img=53',
            'https://i.pravatar.cc/400?img=54',
            'https://i.pravatar.cc/400?img=55',
            'https://i.pravatar.cc/400?img=56'
        ],
        true,
        NOW() - INTERVAL '5 hours',
        'male',
        'all',
        25,
        55,
        'anywhere',
        44.8378,
        -0.5792,
        true,
        'free',
        ARRAY['French'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 7: Isabella (Spanish, Female) - DISCOVERY
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        isabella_id,
        'isabella.demo@test.langchat.com',
        'Isabella',
        'Fernandez',
        'Hola! I''m a dancer from Valencia. I love flamenco, art, and meeting people from different cultures. I''d love to practice English and share my Spanish!',
        1997,
        'Valencia, Spain',
        'Spanish',
        ARRAY['English'],
        '{"English": "beginner"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/women/4.jpg',
            'https://i.pravatar.cc/400?img=61',
            'https://i.pravatar.cc/400?img=62',
            'https://i.pravatar.cc/400?img=63',
            'https://i.pravatar.cc/400?img=64',
            'https://i.pravatar.cc/400?img=65',
            'https://i.pravatar.cc/400?img=66'
        ],
        true,
        NOW() - INTERVAL '6 hours',
        'female',
        'all',
        20,
        40,
        'anywhere',
        39.4699,
        -0.3763,
        true,
        'free',
        ARRAY['Spanish'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 8: Diego (Spanish, Male) - DISCOVERY
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        diego_id,
        'diego.demo@test.langchat.com',
        'Diego',
        'Moreno',
        'Hola! I''m a chef from Seville specializing in traditional Andalusian cuisine. I want to learn English to work internationally and share Spanish culture.',
        1991,
        'Seville, Spain',
        'Spanish',
        ARRAY['English'],
        '{"English": "beginner"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/men/4.jpg',
            'https://i.pravatar.cc/400?img=7',
            'https://i.pravatar.cc/400?img=8',
            'https://i.pravatar.cc/400?img=57',
            'https://i.pravatar.cc/400?img=58',
            'https://i.pravatar.cc/400?img=59',
            'https://i.pravatar.cc/400?img=60'
        ],
        true,
        NOW() - INTERVAL '7 hours',
        'male',
        'all',
        22,
        45,
        'anywhere',
        37.3891,
        -5.9845,
        true,
        'free',
        ARRAY['Spanish'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 9: Emma (English, Female) - DISCOVERY (English speaker learning French)
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        emma_id,
        'emma.demo@test.langchat.com',
        'Emma',
        'Thompson',
        'Hey! I''m a journalist from London. I''m passionate about French culture and literature, and I''m looking for native French speakers to practice with!',
        1995,
        'London, United Kingdom',
        'English',
        ARRAY['French'],
        '{"French": "intermediate"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/women/5.jpg',
            'https://i.pravatar.cc/400?img=17',
            'https://i.pravatar.cc/400?img=18',
            'https://i.pravatar.cc/400?img=19',
            'https://i.pravatar.cc/400?img=20',
            'https://i.pravatar.cc/400?img=27',
            'https://i.pravatar.cc/400?img=28'
        ],
        true,
        NOW() - INTERVAL '8 hours',
        'female',
        'all',
        22,
        45,
        'anywhere',
        51.5074,
        -0.1278,
        true,
        'free',
        ARRAY['English'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 10: James (English, Male) - DISCOVERY
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        james_id,
        'james.demo@test.langchat.com',
        'James',
        'Wilson',
        'Hello! I''m a music teacher from Manchester. I''m planning a trip to France and want to learn conversational French. Happy to help with English!',
        1989,
        'Manchester, United Kingdom',
        'English',
        ARRAY['French'],
        '{"French": "beginner"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/men/5.jpg',
            'https://i.pravatar.cc/400?img=67',
            'https://i.pravatar.cc/400?img=68',
            'https://i.pravatar.cc/400?img=69',
            'https://i.pravatar.cc/400?img=70',
            'https://i.pravatar.cc/400?img=29',
            'https://i.pravatar.cc/400?img=30'
        ],
        true,
        NOW() - INTERVAL '9 hours',
        'male',
        'all',
        25,
        50,
        'anywhere',
        53.4808,
        -2.2426,
        true,
        'free',
        ARRAY['English'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 11: Lucia (Spanish, Female) - DISCOVERY
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        lucia_id,
        'lucia.demo@test.langchat.com',
        'Lucia',
        'Sanchez',
        'Hola desde Buenos Aires! I''m a psychologist interested in cultural exchange. I want to improve my English while sharing the beauty of Argentine Spanish!',
        1994,
        'Buenos Aires, Argentina',
        'Spanish',
        ARRAY['English'],
        '{"English": "intermediate"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/women/6.jpg',
            'https://i.pravatar.cc/400?img=38',
            'https://i.pravatar.cc/400?img=39',
            'https://i.pravatar.cc/400?img=40',
            'https://i.pravatar.cc/400?img=47',
            'https://i.pravatar.cc/400?img=48',
            'https://i.pravatar.cc/400?img=49'
        ],
        true,
        NOW() - INTERVAL '10 hours',
        'female',
        'all',
        22,
        45,
        'anywhere',
        -34.6037,
        -58.3816,
        true,
        'free',
        ARRAY['Spanish'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- Profile 12: Pierre (French, Male) - DISCOVERY
    INSERT INTO profiles (
        id, email, first_name, last_name, bio, birth_year, location,
        native_language, learning_languages, proficiency_levels, profile_photos,
        onboarding_completed, last_active, gender, gender_preference,
        min_age, max_age, location_preference, latitude, longitude,
        strictly_platonic, subscription_tier, open_to_languages, allow_non_native_matches
    ) VALUES (
        pierre_id,
        'pierre.demo@test.langchat.com',
        'Pierre',
        'Tremblay',
        'Bonjour from Montreal! I''m a photographer who loves capturing city life. As a French Canadian, I can help with both French dialects. Looking to practice English!',
        1987,
        'Montreal, Canada',
        'French',
        ARRAY['English'],
        '{"English": "intermediate"}'::jsonb,
        ARRAY[
            'https://randomuser.me/api/portraits/men/6.jpg',
            'https://i.pravatar.cc/400?img=50',
            'https://i.pravatar.cc/400?img=57',
            'https://i.pravatar.cc/400?img=58',
            'https://i.pravatar.cc/400?img=59',
            'https://i.pravatar.cc/400?img=60',
            'https://i.pravatar.cc/400?img=14'
        ],
        true,
        NOW() - INTERVAL '11 hours',
        'male',
        'all',
        25,
        55,
        'anywhere',
        45.5017,
        -73.5673,
        true,
        'free',
        ARRAY['French'],
        true
    ) ON CONFLICT (id) DO NOTHING;

    -- ========================================================================
    -- STEP 3: Create Matches (4 mutual matches)
    -- ========================================================================

    -- Match 1: Hannah + Marie
    INSERT INTO matches (id, user1_id, user2_id, user1_liked, user2_liked, matched_at, is_active)
    VALUES (uuid_generate_v4(), demo_user_id, marie_id, true, true, NOW() - INTERVAL '5 days', true)
    RETURNING id INTO match1_id;

    -- Match 2: Hannah + Lucas
    INSERT INTO matches (id, user1_id, user2_id, user1_liked, user2_liked, matched_at, is_active)
    VALUES (uuid_generate_v4(), demo_user_id, lucas_id, true, true, NOW() - INTERVAL '3 days', true)
    RETURNING id INTO match2_id;

    -- Match 3: Hannah + Sofia
    INSERT INTO matches (id, user1_id, user2_id, user1_liked, user2_liked, matched_at, is_active)
    VALUES (uuid_generate_v4(), demo_user_id, sofia_id, true, true, NOW() - INTERVAL '2 days', true)
    RETURNING id INTO match3_id;

    -- Match 4: Hannah + Carlos
    INSERT INTO matches (id, user1_id, user2_id, user1_liked, user2_liked, matched_at, is_active)
    VALUES (uuid_generate_v4(), demo_user_id, carlos_id, true, true, NOW() - INTERVAL '1 day', true)
    RETURNING id INTO match4_id;

    -- ========================================================================
    -- STEP 4: Create Conversations
    -- ========================================================================

    -- Conversation 1: With Marie
    INSERT INTO conversations (id, match_id, created_at, last_message_at, message_count, is_active)
    VALUES (uuid_generate_v4(), match1_id, NOW() - INTERVAL '5 days', NOW() - INTERVAL '1 hour', 8, true)
    RETURNING id INTO conv1_id;

    -- Conversation 2: With Lucas
    INSERT INTO conversations (id, match_id, created_at, last_message_at, message_count, is_active)
    VALUES (uuid_generate_v4(), match2_id, NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 hours', 6, true)
    RETURNING id INTO conv2_id;

    -- Conversation 3: With Sofia
    INSERT INTO conversations (id, match_id, created_at, last_message_at, message_count, is_active)
    VALUES (uuid_generate_v4(), match3_id, NOW() - INTERVAL '2 days', NOW() - INTERVAL '3 hours', 7, true)
    RETURNING id INTO conv3_id;

    -- Conversation 4: With Carlos
    INSERT INTO conversations (id, match_id, created_at, last_message_at, message_count, is_active)
    VALUES (uuid_generate_v4(), match4_id, NOW() - INTERVAL '1 day', NOW() - INTERVAL '30 minutes', 5, true)
    RETURNING id INTO conv4_id;

    -- ========================================================================
    -- STEP 5: Create Messages
    -- ========================================================================

    -- ---- Conversation 1: Hannah + Marie (French) ----
    INSERT INTO messages (conversation_id, sender_id, receiver_id, original_text, original_language, translated_text, created_at, is_read, is_delivered)
    VALUES
    (conv1_id, marie_id, demo_user_id, 'Bonjour Hannah! Enchantee de faire ta connaissance!', 'fr',
     '{"en": "Hello Hannah! Nice to meet you!"}'::jsonb,
     NOW() - INTERVAL '5 days' + INTERVAL '10 minutes', true, true),

    (conv1_id, demo_user_id, marie_id, 'Hi Marie! So excited to practice French with you! Your profile looks amazing.', 'en',
     '{"fr": "Salut Marie! Tellement excitee de pratiquer le francais avec toi! Ton profil est super."}'::jsonb,
     NOW() - INTERVAL '5 days' + INTERVAL '15 minutes', true, true),

    (conv1_id, marie_id, demo_user_id, 'Merci! Your English is very good. How long have you been learning French?', 'en',
     '{"fr": "Merci! Ton anglais est tres bon. Depuis combien de temps apprends-tu le francais?"}'::jsonb,
     NOW() - INTERVAL '5 days' + INTERVAL '20 minutes', true, true),

    (conv1_id, demo_user_id, marie_id, 'Merci beaucoup! J''apprends le francais depuis six mois. C''est difficile mais j''adore!', 'fr',
     '{"en": "Thank you so much! I have been learning French for six months. It is difficult but I love it!"}'::jsonb,
     NOW() - INTERVAL '4 days', true, true),

    (conv1_id, marie_id, demo_user_id, 'C''est tres bien! Tu fais des progres. I love helping people learn French.', 'fr',
     '{"en": "That is very good! You are making progress. I love helping people learn French."}'::jsonb,
     NOW() - INTERVAL '3 days', true, true),

    (conv1_id, demo_user_id, marie_id, 'I''m going to Paris next month! Do you have any recommendations?', 'en',
     '{"fr": "Je vais a Paris le mois prochain! As-tu des recommandations?"}'::jsonb,
     NOW() - INTERVAL '2 days', true, true),

    (conv1_id, marie_id, demo_user_id, 'Oui! Tu dois visiter Le Marais, c''est mon quartier prefere. Et les crepes a Montmartre sont delicieuses!', 'fr',
     '{"en": "Yes! You must visit Le Marais, it is my favorite neighborhood. And the crepes in Montmartre are delicious!"}'::jsonb,
     NOW() - INTERVAL '1 day', true, true),

    (conv1_id, demo_user_id, marie_id, 'That sounds amazing! Merci beaucoup pour les conseils!', 'en',
     '{"fr": "Ca a l''air incroyable! Merci beaucoup pour les conseils!"}'::jsonb,
     NOW() - INTERVAL '1 hour', true, true);

    -- ---- Conversation 2: Hannah + Lucas (French) ----
    INSERT INTO messages (conversation_id, sender_id, receiver_id, original_text, original_language, translated_text, created_at, is_read, is_delivered)
    VALUES
    (conv2_id, lucas_id, demo_user_id, 'Salut Hannah! I saw you are learning French. I can help!', 'en',
     '{"fr": "Salut Hannah! J''ai vu que tu apprends le francais. Je peux t''aider!"}'::jsonb,
     NOW() - INTERVAL '3 days' + INTERVAL '5 minutes', true, true),

    (conv2_id, demo_user_id, lucas_id, 'Salut Lucas! That would be wonderful. I love that you are a developer - me too!', 'en',
     '{"fr": "Salut Lucas! Ce serait merveilleux. J''adore que tu sois developpeur - moi aussi!"}'::jsonb,
     NOW() - INTERVAL '3 days' + INTERVAL '10 minutes', true, true),

    (conv2_id, lucas_id, demo_user_id, 'C''est genial! What programming languages do you work with?', 'fr',
     '{"en": "That is great! What programming languages do you work with?"}'::jsonb,
     NOW() - INTERVAL '2 days', true, true),

    (conv2_id, demo_user_id, lucas_id, 'Mostly Swift for iOS. Et toi? What do you work on in Lyon?', 'en',
     '{"fr": "Surtout Swift pour iOS. Et toi? Sur quoi travailles-tu a Lyon?"}'::jsonb,
     NOW() - INTERVAL '2 days' + INTERVAL '30 minutes', true, true),

    (conv2_id, lucas_id, demo_user_id, 'Je travaille avec Python et JavaScript. Lyon is a great city for tech!', 'fr',
     '{"en": "I work with Python and JavaScript. Lyon is a great city for tech!"}'::jsonb,
     NOW() - INTERVAL '1 day', true, true),

    (conv2_id, demo_user_id, lucas_id, 'I would love to visit Lyon someday! Do you have any tech meetups there?', 'en',
     '{"fr": "J''aimerais visiter Lyon un jour! Y a-t-il des meetups tech la-bas?"}'::jsonb,
     NOW() - INTERVAL '2 hours', true, true);

    -- ---- Conversation 3: Hannah + Sofia (Spanish) ----
    INSERT INTO messages (conversation_id, sender_id, receiver_id, original_text, original_language, translated_text, created_at, is_read, is_delivered)
    VALUES
    (conv3_id, sofia_id, demo_user_id, 'Hola Hannah! Que tal? Nice to match with you!', 'es',
     '{"en": "Hello Hannah! How are you? Nice to match with you!"}'::jsonb,
     NOW() - INTERVAL '2 days' + INTERVAL '5 minutes', true, true),

    (conv3_id, demo_user_id, sofia_id, 'Hola Sofia! Muy bien, gracias! Your bio says you are a teacher - that is so cool!', 'en',
     '{"es": "Hola Sofia! Muy bien, gracias! Tu bio dice que eres profesora - eso es genial!"}'::jsonb,
     NOW() - INTERVAL '2 days' + INTERVAL '10 minutes', true, true),

    (conv3_id, sofia_id, demo_user_id, 'Si! I teach literature in Madrid. Do you like Spanish books?', 'en',
     '{"es": "Si! Enseno literatura en Madrid. Te gustan los libros espanoles?"}'::jsonb,
     NOW() - INTERVAL '2 days' + INTERVAL '20 minutes', true, true),

    (conv3_id, demo_user_id, sofia_id, 'I am just starting to read in Spanish. Do you have any recommendations for beginners?', 'en',
     '{"es": "Acabo de empezar a leer en espanol. Tienes alguna recomendacion para principiantes?"}'::jsonb,
     NOW() - INTERVAL '1 day' + INTERVAL '12 hours', true, true),

    (conv3_id, sofia_id, demo_user_id, 'Te recomiendo "El Principito" - The Little Prince. Es perfecto para aprender!', 'es',
     '{"en": "I recommend \"The Little Prince\". It is perfect for learning!"}'::jsonb,
     NOW() - INTERVAL '1 day', true, true),

    (conv3_id, demo_user_id, sofia_id, 'Oh I love that book! I will try reading it in Spanish. Gracias!', 'en',
     '{"es": "Oh me encanta ese libro! Intentare leerlo en espanol. Gracias!"}'::jsonb,
     NOW() - INTERVAL '12 hours', true, true),

    (conv3_id, sofia_id, demo_user_id, 'De nada! Let me know if you have questions about any words.', 'en',
     '{"es": "De nada! Dime si tienes preguntas sobre alguna palabra."}'::jsonb,
     NOW() - INTERVAL '3 hours', true, true);

    -- ---- Conversation 4: Hannah + Carlos (Spanish) ----
    INSERT INTO messages (conversation_id, sender_id, receiver_id, original_text, original_language, translated_text, created_at, is_read, is_delivered)
    VALUES
    (conv4_id, carlos_id, demo_user_id, 'Hola Hannah! Soy Carlos de Barcelona. Me encanta tu perfil!', 'es',
     '{"en": "Hello Hannah! I am Carlos from Barcelona. I love your profile!"}'::jsonb,
     NOW() - INTERVAL '1 day' + INTERVAL '5 minutes', true, true),

    (conv4_id, demo_user_id, carlos_id, 'Hola Carlos! Gracias! Barcelona is one of my dream destinations!', 'en',
     '{"es": "Hola Carlos! Gracias! Barcelona es uno de mis destinos sonados!"}'::jsonb,
     NOW() - INTERVAL '1 day' + INTERVAL '15 minutes', true, true),

    (conv4_id, carlos_id, demo_user_id, 'You should visit! I can show you the best architecture - Gaudi is amazing.', 'en',
     '{"es": "Deberias visitar! Puedo mostrarte la mejor arquitectura - Gaudi es increible."}'::jsonb,
     NOW() - INTERVAL '20 hours', true, true),

    (conv4_id, demo_user_id, carlos_id, 'Me encantaria ver La Sagrada Familia! Is it as impressive in person?', 'en',
     '{"es": "Me encantaria ver La Sagrada Familia! Es tan impresionante en persona?"}'::jsonb,
     NOW() - INTERVAL '10 hours', true, true),

    (conv4_id, carlos_id, demo_user_id, 'Es increible! The light through the windows is magical. Te va a encantar.', 'es',
     '{"en": "It is incredible! The light through the windows is magical. You are going to love it."}'::jsonb,
     NOW() - INTERVAL '30 minutes', true, true);

    -- Update conversation last_message_preview
    UPDATE conversations SET last_message_preview = 'That sounds amazing! Merci beaucoup pour les conseils!' WHERE id = conv1_id;
    UPDATE conversations SET last_message_preview = 'I would love to visit Lyon someday!' WHERE id = conv2_id;
    UPDATE conversations SET last_message_preview = 'Let me know if you have questions about any words.' WHERE id = conv3_id;
    UPDATE conversations SET last_message_preview = 'Es increible! The light through the windows is magical.' WHERE id = conv4_id;

    RAISE NOTICE 'Demo account setup complete!';
    RAISE NOTICE 'Demo user ID: %', demo_user_id;
    RAISE NOTICE 'Created 12 test profiles';
    RAISE NOTICE 'Created 4 matches with conversations';
    RAISE NOTICE 'Created sample messages for each conversation';

END $$;

-- ============================================================================
-- VERIFICATION QUERIES (Run after setup to confirm)
-- ============================================================================

-- Check demo profile
-- SELECT id, email, first_name, subscription_tier, onboarding_completed
-- FROM profiles WHERE email = 'appreview@byzyb.ai';

-- Check test profiles (should return 12)
-- SELECT COUNT(*) as test_profile_count FROM profiles WHERE email LIKE '%@test.langchat.com';

-- Check matches (should return 4)
-- SELECT m.id, p1.first_name as user1, p2.first_name as user2, m.is_mutual
-- FROM matches m
-- JOIN profiles p1 ON m.user1_id = p1.id
-- JOIN profiles p2 ON m.user2_id = p2.id
-- WHERE p1.email = 'appreview@byzyb.ai' OR p2.email = 'appreview@byzyb.ai';

-- Check conversations with message counts
-- SELECT c.id, c.message_count, c.last_message_preview
-- FROM conversations c
-- JOIN matches m ON c.match_id = m.id
-- JOIN profiles p ON m.user1_id = p.id
-- WHERE p.email = 'appreview@byzyb.ai';

-- Check total messages (should return ~26)
-- SELECT COUNT(*) as total_messages FROM messages;
