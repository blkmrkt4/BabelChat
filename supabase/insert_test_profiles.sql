-- Insert 40 Test Profiles for Matching Algorithm Testing
-- Run this in Supabase SQL Editor

-- Note: These use fake UUIDs. Supabase auth.users entries would need to be created first
-- For testing, we'll insert directly to profiles table

-- Batch 1: English speakers learning various languages (10 profiles)
INSERT INTO profiles (id, email, phone_number, first_name, last_name, bio, birth_year, age, location, native_language, learning_languages, profile_photos, onboarding_completed, gender, gender_preference, min_age, max_age, location_preference, latitude, longitude, relationship_intents, learning_contexts, allow_non_native_matches, min_proficiency_level, max_proficiency_level) VALUES

-- English speakers in US
('10000000-0000-0000-0000-000000000001', 'sarah.johnson@test.com', '+15551001', 'Sarah', 'Johnson', 'Love traveling and learning languages! Currently planning a trip to Barcelona 🇪🇸', 1995, 30, 'San Francisco, USA', 'English', ARRAY['Spanish', 'French'], ARRAY['https://picsum.photos/seed/sarah/400'], true, 'female', 'all', 25, 40, 'anywhere', 37.7749, -122.4194, ARRAY['friendship', 'language_practice_only'], ARRAY['travel', 'cultural'], false, 'beginner', 'advanced'),

('10000000-0000-0000-0000-000000000002', 'mike.chen@test.com', '+15551002', 'Mike', 'Chen', 'Software engineer who wants to learn Japanese. Anime fan!', 1992, 33, 'Seattle, USA', 'English', ARRAY['Japanese', 'Mandarin'], ARRAY['https://picsum.photos/seed/mike/400'], true, 'male', 'all', 28, 38, 'anywhere', 47.6062, -122.3321, ARRAY['language_practice_only'], ARRAY['fun', 'cultural'], true, 'beginner', 'intermediate'),

('10000000-0000-0000-0000-000000000003', 'emma.davis@test.com', '+15551003', 'Emma', 'Davis', 'Teacher passionate about languages. Learning Spanish for work!', 1990, 35, 'Austin, Texas', 'English', ARRAY['Spanish', 'Portuguese'], ARRAY['https://picsum.photos/seed/emma/400'], true, 'female', 'all', 30, 45, 'regional_100km', 30.2672, -97.7431, ARRAY['friendship', 'language_practice_only'], ARRAY['work', 'cultural'], false, 'intermediate', 'advanced'),

('10000000-0000-0000-0000-000000000004', 'james.wilson@test.com', '+15551004', 'James', 'Wilson', 'NYC finance guy learning Mandarin for business. Let''s practice!', 1988, 37, 'New York, USA', 'English', ARRAY['Mandarin'], ARRAY['https://picsum.photos/seed/james/400'], true, 'male', 'female', 32, 42, 'local_25km', 40.7128, -74.0060, ARRAY['open_to_dating', 'friendship'], ARRAY['work', 'travel'], false, 'intermediate', 'advanced'),

('10000000-0000-0000-0000-000000000005', 'sophia.martinez@test.com', '+15551005', 'Sophia', 'Martinez', 'Bilingual Spanish-English speaker. Happy to help English learners!', 1997, 28, 'Miami, Florida', 'English', ARRAY['Portuguese', 'Italian'], ARRAY['https://picsum.photos/seed/sophia/400'], true, 'female', 'male', 24, 35, 'anywhere', 25.7617, -80.1918, ARRAY['open_to_dating', 'friendship'], ARRAY['travel', 'fun'], true, 'beginner', 'advanced'),

('10000000-0000-0000-0000-000000000006', 'david.kim@test.com', '+15551006', 'David', 'Kim', 'Korean-American learning French. Love cooking and music!', 1994, 31, 'Los Angeles, USA', 'English', ARRAY['French', 'Korean'], ARRAY['https://picsum.photos/seed/david/400'], true, 'male', 'all', 26, 38, 'regional_100km', 34.0522, -118.2437, ARRAY['friendship', 'language_practice_only'], ARRAY['cultural', 'fun'], false, 'beginner', 'intermediate'),

('10000000-0000-0000-0000-000000000007', 'olivia.brown@test.com', '+15551007', 'Olivia', 'Brown', 'Digital nomad currently in Bali. Learning Indonesian!', 1993, 32, 'Denver, Colorado', 'English', ARRAY['Indonesian', 'Spanish'], ARRAY['https://picsum.photos/seed/olivia/400'], true, 'female', 'all', 28, 40, 'anywhere', 39.7392, -104.9903, ARRAY['friendship'], ARRAY['travel', 'fun'], true, 'beginner', 'intermediate'),

('10000000-0000-0000-0000-000000000008', 'alex.taylor@test.com', '+15551008', 'Alex', 'Taylor', 'Non-binary language enthusiast. Learning multiple languages!', 1996, 29, 'Portland, Oregon', 'English', ARRAY['German', 'Dutch'], ARRAY['https://picsum.photos/seed/alex/400'], true, 'non_binary', 'all', 25, 35, 'local_25km', 45.5152, -122.6784, ARRAY['friendship'], ARRAY['cultural', 'academic'], false, 'intermediate', 'advanced'),

('10000000-0000-0000-0000-000000000009', 'ryan.anderson@test.com', '+15551009', 'Ryan', 'Anderson', 'Grad student studying abroad in Japan next year!', 1998, 27, 'Boston, Massachusetts', 'English', ARRAY['Japanese'], ARRAY['https://picsum.photos/seed/ryan/400'], true, 'male', 'all', 23, 32, 'anywhere', 42.3601, -71.0589, ARRAY['language_practice_only'], ARRAY['academic', 'travel'], false, 'beginner', 'intermediate'),

('10000000-0000-0000-0000-000000000010', 'mia.white@test.com', '+15551010', 'Mia', 'White', 'Yoga instructor learning Hindi and Sanskrit. Spiritual journey!', 1991, 34, 'San Diego, California', 'English', ARRAY['Hindi'], ARRAY['https://picsum.photos/seed/mia/400'], true, 'female', 'all', 28, 42, 'regional_100km', 32.7157, -117.1611, ARRAY['friendship'], ARRAY['cultural', 'fun'], true, 'beginner', 'intermediate');

-- Batch 2: Spanish native speakers (8 profiles)
INSERT INTO profiles (id, email, phone_number, first_name, last_name, bio, birth_year, age, location, native_language, learning_languages, profile_photos, onboarding_completed, gender, gender_preference, min_age, max_age, location_preference, latitude, longitude, relationship_intents, learning_contexts, allow_non_native_matches, min_proficiency_level, max_proficiency_level) VALUES

('20000000-0000-0000-0000-000000000001', 'carlos.garcia@test.com', '+34551001', 'Carlos', 'García', '¡Hola! From Madrid. Want to practice English and meet new people!', 1994, 31, 'Madrid, Spain', 'Spanish', ARRAY['English'], ARRAY['https://picsum.photos/seed/carlos/400'], true, 'male', 'female', 26, 38, 'anywhere', 40.4168, -3.7038, ARRAY['open_to_dating', 'friendship'], ARRAY['travel', 'fun'], false, 'intermediate', 'advanced'),

('20000000-0000-0000-0000-000000000002', 'maria.rodriguez@test.com', '+34551002', 'María', 'Rodríguez', 'Barcelona native. Love architecture and art! Learning English.', 1992, 33, 'Barcelona, Spain', 'Spanish', ARRAY['English', 'French'], ARRAY['https://picsum.photos/seed/maria/400'], true, 'female', 'all', 28, 40, 'local_25km', 41.3851, 2.1734, ARRAY['friendship'], ARRAY['cultural', 'fun'], false, 'intermediate', 'advanced'),

('20000000-0000-0000-0000-000000000003', 'diego.lopez@test.com', '+52551003', 'Diego', 'López', 'From Mexico City! Software dev wanting to improve English.', 1995, 30, 'Mexico City, Mexico', 'Spanish', ARRAY['English'], ARRAY['https://picsum.photos/seed/diego/400'], true, 'male', 'all', 25, 38, 'anywhere', 19.4326, -99.1332, ARRAY['language_practice_only', 'friendship'], ARRAY['work', 'travel'], false, 'intermediate', 'advanced'),

('20000000-0000-0000-0000-000000000004', 'lucia.fernandez@test.com', '+54551004', 'Lucía', 'Fernández', 'Argentine teacher. Learning English to teach better! ❤️', 1990, 35, 'Buenos Aires, Argentina', 'Spanish', ARRAY['English', 'Portuguese'], ARRAY['https://picsum.photos/seed/lucia/400'], true, 'female', 'all', 30, 45, 'regional_100km', -34.6037, -58.3816, ARRAY['friendship'], ARRAY['work', 'academic'], true, 'intermediate', 'advanced'),

('20000000-0000-0000-0000-000000000005', 'pablo.martinez@test.com', '+57551005', 'Pablo', 'Martínez', 'Bogotá. Coffee lover ☕ Learning English for travel!', 1996, 29, 'Bogotá, Colombia', 'Spanish', ARRAY['English'], ARRAY['https://picsum.photos/seed/pablo/400'], true, 'male', 'all', 25, 35, 'anywhere', 4.7110, -74.0721, ARRAY['friendship', 'language_practice_only'], ARRAY['travel', 'fun'], false, 'beginner', 'intermediate'),

('20000000-0000-0000-0000-000000000006', 'sofia.torres@test.com', '+56551006', 'Sofía', 'Torres', 'From Santiago! Learning English and French. Wine enthusiast 🍷', 1993, 32, 'Santiago, Chile', 'Spanish', ARRAY['English', 'French'], ARRAY['https://picsum.photos/seed/sofia/400'], true, 'female', 'male', 27, 40, 'anywhere', -33.4489, -70.6693, ARRAY['open_to_dating', 'friendship'], ARRAY['cultural', 'travel'], false, 'intermediate', 'advanced'),

('20000000-0000-0000-0000-000000000007', 'javier.santos@test.com', '+51551007', 'Javier', 'Santos', 'Lima, Peru. Traveling to USA next month! Need English practice.', 1997, 28, 'Lima, Peru', 'Spanish', ARRAY['English'], ARRAY['https://picsum.photos/seed/javier/400'], true, 'male', 'all', 24, 35, 'anywhere', -12.0464, -77.0428, ARRAY['language_practice_only'], ARRAY['travel', 'work'], false, 'beginner', 'intermediate'),

('20000000-0000-0000-0000-000000000008', 'valentina.ruiz@test.com', '+58551008', 'Valentina', 'Ruiz', 'Venezuelan in Miami! Bilingual and happy to help Spanish learners.', 1994, 31, 'Miami, Florida', 'Spanish', ARRAY['English', 'Portuguese'], ARRAY['https://picsum.photos/seed/valentina/400'], true, 'female', 'all', 26, 38, 'local_25km', 25.7617, -80.1918, ARRAY['friendship', 'open_to_dating'], ARRAY['fun', 'cultural'], true, 'intermediate', 'advanced');

-- Batch 3: French native speakers (6 profiles)
INSERT INTO profiles (id, email, phone_number, first_name, last_name, bio, birth_year, age, location, native_language, learning_languages, profile_photos, onboarding_completed, gender, gender_preference, min_age, max_age, location_preference, latitude, longitude, relationship_intents, learning_contexts, allow_non_native_matches, min_proficiency_level, max_proficiency_level) VALUES

('30000000-0000-0000-0000-000000000001', 'pierre.dubois@test.com', '+33551001', 'Pierre', 'Dubois', 'Parisien chef learning English. Food lover! 🥖', 1991, 34, 'Paris, France', 'French', ARRAY['English', 'Italian'], ARRAY['https://picsum.photos/seed/pierre/400'], true, 'male', 'all', 28, 42, 'local_25km', 48.8566, 2.3522, ARRAY['friendship', 'open_to_dating'], ARRAY['work', 'cultural'], false, 'intermediate', 'advanced'),

('30000000-0000-0000-0000-000000000002', 'amelie.martin@test.com', '+33551002', 'Amélie', 'Martin', 'From Lyon. Fashion designer learning English and Spanish!', 1995, 30, 'Lyon, France', 'French', ARRAY['English', 'Spanish'], ARRAY['https://picsum.photos/seed/amelie/400'], true, 'female', 'all', 26, 38, 'anywhere', 45.7640, 4.8357, ARRAY['friendship'], ARRAY['work', 'travel'], false, 'intermediate', 'advanced'),

('30000000-0000-0000-0000-000000000003', 'lucas.bernard@test.com', '+33551003', 'Lucas', 'Bernard', 'Marseille native. Learning English for tech career!', 1996, 29, 'Marseille, France', 'French', ARRAY['English'], ARRAY['https://picsum.photos/seed/lucas/400'], true, 'male', 'all', 25, 35, 'regional_100km', 43.2965, 5.3698, ARRAY['language_practice_only'], ARRAY['work', 'fun'], false, 'beginner', 'intermediate'),

('30000000-0000-0000-0000-000000000004', 'chloe.laurent@test.com', '+33551004', 'Chloé', 'Laurent', 'Bordeaux wine country! Learning English and German.', 1993, 32, 'Bordeaux, France', 'French', ARRAY['English', 'German'], ARRAY['https://picsum.photos/seed/chloe/400'], true, 'female', 'male', 27, 40, 'anywhere', 44.8378, -0.5792, ARRAY['open_to_dating', 'friendship'], ARRAY['travel', 'cultural'], false, 'intermediate', 'advanced'),

('30000000-0000-0000-0000-000000000005', 'antoine.moreau@test.com', '+33551005', 'Antoine', 'Moreau', 'Nice. Beach lover 🏖️ Learning English for international friends!', 1994, 31, 'Nice, France', 'French', ARRAY['English'], ARRAY['https://picsum.photos/seed/antoine/400'], true, 'male', 'all', 26, 38, 'local_25km', 43.7102, 7.2620, ARRAY['friendship'], ARRAY['fun', 'travel'], true, 'beginner', 'intermediate'),

('30000000-0000-0000-0000-000000000006', 'emma.rousseau@test.com', '+33551006', 'Emma', 'Rousseau', 'Toulouse student. Learning English and Spanish!', 1998, 27, 'Toulouse, France', 'French', ARRAY['English', 'Spanish'], ARRAY['https://picsum.photos/seed/emma2/400'], true, 'female', 'all', 23, 33, 'regional_100km', 43.6047, 1.4442, ARRAY['friendship'], ARRAY['academic', 'fun'], false, 'beginner', 'intermediate');

-- Batch 4: Japanese native speakers (6 profiles)
INSERT INTO profiles (id, email, phone_number, first_name, last_name, bio, birth_year, age, location, native_language, learning_languages, profile_photos, onboarding_completed, gender, gender_preference, min_age, max_age, location_preference, latitude, longitude, relationship_intents, learning_contexts, allow_non_native_matches, min_proficiency_level, max_proficiency_level) VALUES

('40000000-0000-0000-0000-000000000001', 'yuki.tanaka@test.com', '+81551001', 'Yuki', 'Tanaka', 'Tokyo software engineer. Anime and manga fan! Learning English.', 1995, 30, 'Tokyo, Japan', 'Japanese', ARRAY['English'], ARRAY['https://picsum.photos/seed/yuki/400'], true, 'male', 'all', 26, 38, 'anywhere', 35.6762, 139.6503, ARRAY['friendship', 'language_practice_only'], ARRAY['work', 'fun'], false, 'intermediate', 'advanced'),

('40000000-0000-0000-0000-000000000002', 'sakura.yamamoto@test.com', '+81551002', 'Sakura', 'Yamamoto', 'From Kyoto. Traditional tea ceremony instructor. Learning English!', 1992, 33, 'Kyoto, Japan', 'Japanese', ARRAY['English'], ARRAY['https://picsum.photos/seed/sakura/400'], true, 'female', 'all', 28, 40, 'local_25km', 35.0116, 135.7681, ARRAY['friendship'], ARRAY['cultural', 'work'], false, 'beginner', 'intermediate'),

('40000000-0000-0000-0000-000000000003', 'kenji.sato@test.com', '+81551003', 'Kenji', 'Sato', 'Osaka. Food blogger learning English to reach more people!', 1994, 31, 'Osaka, Japan', 'Japanese', ARRAY['English', 'Korean'], ARRAY['https://picsum.photos/seed/kenji/400'], true, 'male', 'female', 27, 38, 'regional_100km', 34.6937, 135.5023, ARRAY['open_to_dating', 'friendship'], ARRAY['work', 'fun'], false, 'intermediate', 'advanced'),

('40000000-0000-0000-0000-000000000004', 'hana.nakamura@test.com', '+81551004', 'Hana', 'Nakamura', 'Traveling to California soon! Need English practice 🌸', 1996, 29, 'Yokohama, Japan', 'Japanese', ARRAY['English'], ARRAY['https://picsum.photos/seed/hana/400'], true, 'female', 'all', 25, 35, 'anywhere', 35.4437, 139.6380, ARRAY['friendship'], ARRAY['travel', 'fun'], false, 'beginner', 'intermediate'),

('40000000-0000-0000-0000-000000000005', 'ryo.suzuki@test.com', '+81551005', 'Ryo', 'Suzuki', 'Sapporo. Ski instructor learning English for international guests!', 1993, 32, 'Sapporo, Japan', 'Japanese', ARRAY['English'], ARRAY['https://picsum.photos/seed/ryo/400'], true, 'male', 'all', 27, 40, 'local_25km', 43.0642, 141.3469, ARRAY['friendship'], ARRAY['work', 'fun'], true, 'intermediate', 'advanced'),

('40000000-0000-0000-0000-000000000006', 'miyu.ishikawa@test.com', '+81551006', 'Miyu', 'Ishikawa', 'From Fukuoka. Fashion student going to Paris next year!', 1997, 28, 'Fukuoka, Japan', 'Japanese', ARRAY['English', 'French'], ARRAY['https://picsum.photos/seed/miyu/400'], true, 'female', 'all', 24, 34, 'anywhere', 33.5904, 130.4017, ARRAY['friendship'], ARRAY['academic', 'travel'], false, 'beginner', 'intermediate');

-- Batch 5: German native speakers (5 profiles)
INSERT INTO profiles (id, email, phone_number, first_name, last_name, bio, birth_year, age, location, native_language, learning_languages, profile_photos, onboarding_completed, gender, gender_preference, min_age, max_age, location_preference, latitude, longitude, relationship_intents, learning_contexts, allow_non_native_matches, min_proficiency_level, max_proficiency_level) VALUES

('50000000-0000-0000-0000-000000000001', 'max.mueller@test.com', '+49551001', 'Max', 'Müller', 'Berlin tech startup founder. Learning English and Spanish!', 1991, 34, 'Berlin, Germany', 'German', ARRAY['English', 'Spanish'], ARRAY['https://picsum.photos/seed/max/400'], true, 'male', 'all', 28, 42, 'anywhere', 52.5200, 13.4050, ARRAY['friendship'], ARRAY['work', 'travel'], false, 'intermediate', 'advanced'),

('50000000-0000-0000-0000-000000000002', 'anna.schmidt@test.com', '+49551002', 'Anna', 'Schmidt', 'From Munich. Oktoberfest guide learning English!', 1994, 31, 'Munich, Germany', 'German', ARRAY['English'], ARRAY['https://picsum.photos/seed/anna/400'], true, 'female', 'male', 26, 38, 'local_25km', 48.1351, 11.5820, ARRAY['open_to_dating', 'friendship'], ARRAY['work', 'fun'], false, 'intermediate', 'advanced'),

('50000000-0000-0000-0000-000000000003', 'felix.wagner@test.com', '+49551003', 'Felix', 'Wagner', 'Hamburg musician. Learning English for international tours!', 1995, 30, 'Hamburg, Germany', 'German', ARRAY['English'], ARRAY['https://picsum.photos/seed/felix/400'], true, 'male', 'all', 26, 38, 'regional_100km', 53.5511, 9.9937, ARRAY['friendship'], ARRAY['work', 'fun'], true, 'beginner', 'intermediate'),

('50000000-0000-0000-0000-000000000004', 'lena.weber@test.com', '+49551004', 'Lena', 'Weber', 'Frankfurt banker learning English and French for work.', 1990, 35, 'Frankfurt, Germany', 'German', ARRAY['English', 'French'], ARRAY['https://picsum.photos/seed/lena/400'], true, 'female', 'all', 30, 45, 'anywhere', 50.1109, 8.6821, ARRAY['language_practice_only'], ARRAY['work'], false, 'intermediate', 'advanced'),

('50000000-0000-0000-0000-000000000005', 'lukas.fischer@test.com', '+49551005', 'Lukas', 'Fischer', 'Cologne university student. Learning English and Dutch!', 1997, 28, 'Cologne, Germany', 'German', ARRAY['English', 'Dutch'], ARRAY['https://picsum.photos/seed/lukas/400'], true, 'male', 'all', 24, 34, 'local_25km', 50.9375, 6.9603, ARRAY['friendship'], ARRAY['academic', 'fun'], false, 'beginner', 'intermediate');

-- Batch 6: Mandarin/Korean native speakers (5 profiles)
INSERT INTO profiles (id, email, phone_number, first_name, last_name, bio, birth_year, age, location, native_language, learning_languages, profile_photos, onboarding_completed, gender, gender_preference, min_age, max_age, location_preference, latitude, longitude, relationship_intents, learning_contexts, allow_non_native_matches, min_proficiency_level, max_proficiency_level) VALUES

('60000000-0000-0000-0000-000000000001', 'wei.zhang@test.com', '+86551001', 'Wei', 'Zhang', 'Shanghai software developer. Learning English for career!', 1993, 32, 'Shanghai, China', 'Mandarin', ARRAY['English'], ARRAY['https://picsum.photos/seed/wei/400'], true, 'male', 'all', 27, 40, 'anywhere', 31.2304, 121.4737, ARRAY['language_practice_only'], ARRAY['work'], false, 'intermediate', 'advanced'),

('60000000-0000-0000-0000-000000000002', 'li.wang@test.com', '+86551002', 'Li', 'Wang', 'From Beijing. University teacher learning English!', 1990, 35, 'Beijing, China', 'Mandarin', ARRAY['English'], ARRAY['https://picsum.photos/seed/li/400'], true, 'female', 'all', 30, 45, 'regional_100km', 39.9042, 116.4074, ARRAY['friendship'], ARRAY['work', 'academic'], false, 'intermediate', 'advanced'),

('60000000-0000-0000-0000-000000000003', 'jimin.park@test.com', '+82551003', 'Jimin', 'Park', 'Seoul K-pop fan! Learning English and Japanese 🎵', 1996, 29, 'Seoul, South Korea', 'Korean', ARRAY['English', 'Japanese'], ARRAY['https://picsum.photos/seed/jimin/400'], true, 'non_binary', 'all', 25, 35, 'anywhere', 37.5665, 126.9780, ARRAY['friendship'], ARRAY['fun', 'cultural'], true, 'beginner', 'intermediate'),

('60000000-0000-0000-0000-000000000004', 'soo-jin.kim@test.com', '+82551004', 'Soo-Jin', 'Kim', 'Busan. Fashion blogger moving to LA next month!', 1994, 31, 'Busan, South Korea', 'Korean', ARRAY['English'], ARRAY['https://picsum.photos/seed/soojin/400'], true, 'female', 'all', 26, 38, 'anywhere', 35.1796, 129.0756, ARRAY['friendship', 'open_to_dating'], ARRAY['work', 'travel'], false, 'intermediate', 'advanced'),

('60000000-0000-0000-0000-000000000005', 'xiao.chen@test.com', '+86551005', 'Xiao', 'Chen', 'Guangzhou. Learning English to study abroad!', 1997, 28, 'Guangzhou, China', 'Mandarin', ARRAY['English'], ARRAY['https://picsum.photos/seed/xiao/400'], true, 'female', 'all', 24, 34, 'regional_100km', 23.1291, 113.2644, ARRAY['language_practice_only'], ARRAY['academic', 'travel'], false, 'beginner', 'intermediate');

-- Update last_active timestamps to make profiles seem recently active
UPDATE profiles SET last_active = NOW() - (random() * interval '2 hours');

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Successfully inserted 40 test profiles!';
    RAISE NOTICE 'Profiles by language:';
    RAISE NOTICE '- English speakers: 10';
    RAISE NOTICE '- Spanish speakers: 8';
    RAISE NOTICE '- French speakers: 6';
    RAISE NOTICE '- Japanese speakers: 6';
    RAISE NOTICE '- German speakers: 5';
    RAISE NOTICE '- Mandarin/Korean speakers: 5';
END $$;
