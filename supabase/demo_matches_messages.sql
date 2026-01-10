-- ============================================================================
-- Create Matches, Conversations, and Messages for Demo Account
-- Run this in Supabase SQL Editor
-- ============================================================================

DO $$
DECLARE
    demo_user_id UUID := '2b89fd98-a443-459a-8e1a-fb0922b0a536';
    marie_id UUID := 'a1000001-0001-0001-0001-000000000001';
    lucas_id UUID := 'a1000001-0001-0001-0001-000000000002';
    sofia_id UUID := 'a1000001-0001-0001-0001-000000000003';
    carlos_id UUID := 'a1000001-0001-0001-0001-000000000004';

    match1_id UUID;
    match2_id UUID;
    match3_id UUID;
    match4_id UUID;
    conv1_id UUID;
    conv2_id UUID;
    conv3_id UUID;
    conv4_id UUID;
BEGIN
    -- Clean up any existing data for demo user
    DELETE FROM messages WHERE sender_id = demo_user_id OR receiver_id = demo_user_id;
    DELETE FROM conversations WHERE match_id IN (
        SELECT id FROM matches WHERE user1_id = demo_user_id OR user2_id = demo_user_id
    );
    DELETE FROM matches WHERE user1_id = demo_user_id OR user2_id = demo_user_id;

    RAISE NOTICE 'Cleaned up existing demo data';

    -- Create Matches
    INSERT INTO matches (user1_id, user2_id, user1_liked, user2_liked, is_active)
    VALUES (demo_user_id, marie_id, true, true, true)
    RETURNING id INTO match1_id;

    INSERT INTO matches (user1_id, user2_id, user1_liked, user2_liked, is_active)
    VALUES (demo_user_id, lucas_id, true, true, true)
    RETURNING id INTO match2_id;

    INSERT INTO matches (user1_id, user2_id, user1_liked, user2_liked, is_active)
    VALUES (demo_user_id, sofia_id, true, true, true)
    RETURNING id INTO match3_id;

    INSERT INTO matches (user1_id, user2_id, user1_liked, user2_liked, is_active)
    VALUES (demo_user_id, carlos_id, true, true, true)
    RETURNING id INTO match4_id;

    RAISE NOTICE 'Created 4 matches';

    -- Create Conversations
    INSERT INTO conversations (match_id, last_message_at, message_count, is_active)
    VALUES (match1_id, NOW() - INTERVAL '1 hour', 8, true)
    RETURNING id INTO conv1_id;

    INSERT INTO conversations (match_id, last_message_at, message_count, is_active)
    VALUES (match2_id, NOW() - INTERVAL '2 hours', 6, true)
    RETURNING id INTO conv2_id;

    INSERT INTO conversations (match_id, last_message_at, message_count, is_active)
    VALUES (match3_id, NOW() - INTERVAL '3 hours', 7, true)
    RETURNING id INTO conv3_id;

    INSERT INTO conversations (match_id, last_message_at, message_count, is_active)
    VALUES (match4_id, NOW() - INTERVAL '30 minutes', 5, true)
    RETURNING id INTO conv4_id;

    RAISE NOTICE 'Created 4 conversations';

    -- Messages: Hannah + Marie (French)
    INSERT INTO messages (conversation_id, sender_id, receiver_id, original_text, original_language, translated_text, created_at, is_read, is_delivered) VALUES
    (conv1_id, marie_id, demo_user_id, 'Bonjour Hannah! Enchantee de faire ta connaissance!', 'French', '{"en": "Hello Hannah! Nice to meet you!"}'::jsonb, NOW() - INTERVAL '5 days', true, true),
    (conv1_id, demo_user_id, marie_id, 'Hi Marie! So excited to practice French with you!', 'English', '{"fr": "Salut Marie! Tellement excitee de pratiquer le francais avec toi!"}'::jsonb, NOW() - INTERVAL '5 days' + INTERVAL '5 min', true, true),
    (conv1_id, marie_id, demo_user_id, 'Merci! How long have you been learning French?', 'English', '{"fr": "Merci! Depuis combien de temps apprends-tu le francais?"}'::jsonb, NOW() - INTERVAL '4 days', true, true),
    (conv1_id, demo_user_id, marie_id, 'J''apprends le francais depuis six mois. C''est difficile mais j''adore!', 'French', '{"en": "I have been learning French for six months. It is difficult but I love it!"}'::jsonb, NOW() - INTERVAL '3 days', true, true),
    (conv1_id, marie_id, demo_user_id, 'C''est tres bien! Tu fais des progres.', 'French', '{"en": "That is very good! You are making progress."}'::jsonb, NOW() - INTERVAL '2 days', true, true),
    (conv1_id, demo_user_id, marie_id, 'I''m going to Paris next month! Any recommendations?', 'English', '{"fr": "Je vais a Paris le mois prochain! Des recommandations?"}'::jsonb, NOW() - INTERVAL '1 day', true, true),
    (conv1_id, marie_id, demo_user_id, 'Oui! Tu dois visiter Le Marais. Les crepes a Montmartre sont delicieuses!', 'French', '{"en": "Yes! You must visit Le Marais. The crepes in Montmartre are delicious!"}'::jsonb, NOW() - INTERVAL '12 hours', true, true),
    (conv1_id, demo_user_id, marie_id, 'That sounds amazing! Merci beaucoup!', 'English', '{"fr": "Ca a l''air incroyable! Merci beaucoup!"}'::jsonb, NOW() - INTERVAL '1 hour', true, true);

    -- Messages: Hannah + Lucas (French)
    INSERT INTO messages (conversation_id, sender_id, receiver_id, original_text, original_language, translated_text, created_at, is_read, is_delivered) VALUES
    (conv2_id, lucas_id, demo_user_id, 'Salut Hannah! I saw you are learning French. I can help!', 'English', '{"fr": "Salut Hannah! J''ai vu que tu apprends le francais. Je peux t''aider!"}'::jsonb, NOW() - INTERVAL '3 days', true, true),
    (conv2_id, demo_user_id, lucas_id, 'Salut Lucas! That would be wonderful. I love that you are a developer too!', 'English', '{"fr": "Salut Lucas! Ce serait merveilleux. J''adore que tu sois developpeur aussi!"}'::jsonb, NOW() - INTERVAL '3 days' + INTERVAL '10 min', true, true),
    (conv2_id, lucas_id, demo_user_id, 'C''est genial! What programming languages do you use?', 'French', '{"en": "That is great! What programming languages do you use?"}'::jsonb, NOW() - INTERVAL '2 days', true, true),
    (conv2_id, demo_user_id, lucas_id, 'Mostly Swift for iOS. Et toi?', 'English', '{"fr": "Surtout Swift pour iOS. Et toi?"}'::jsonb, NOW() - INTERVAL '1 day', true, true),
    (conv2_id, lucas_id, demo_user_id, 'Je travaille avec Python et JavaScript. Lyon is great for tech!', 'French', '{"en": "I work with Python and JavaScript. Lyon is great for tech!"}'::jsonb, NOW() - INTERVAL '12 hours', true, true),
    (conv2_id, demo_user_id, lucas_id, 'I would love to visit Lyon someday!', 'English', '{"fr": "J''aimerais visiter Lyon un jour!"}'::jsonb, NOW() - INTERVAL '2 hours', true, true);

    -- Messages: Hannah + Sofia (Spanish)
    INSERT INTO messages (conversation_id, sender_id, receiver_id, original_text, original_language, translated_text, created_at, is_read, is_delivered) VALUES
    (conv3_id, sofia_id, demo_user_id, 'Hola Hannah! Que tal? Nice to match with you!', 'Spanish', '{"en": "Hello Hannah! How are you? Nice to match with you!"}'::jsonb, NOW() - INTERVAL '2 days', true, true),
    (conv3_id, demo_user_id, sofia_id, 'Hola Sofia! Muy bien, gracias! You are a teacher - that is so cool!', 'English', '{"es": "Hola Sofia! Muy bien, gracias! Eres profesora - eso es genial!"}'::jsonb, NOW() - INTERVAL '2 days' + INTERVAL '10 min', true, true),
    (conv3_id, sofia_id, demo_user_id, 'Si! I teach literature in Madrid. Do you like Spanish books?', 'English', '{"es": "Si! Enseno literatura en Madrid. Te gustan los libros espanoles?"}'::jsonb, NOW() - INTERVAL '1 day' + INTERVAL '12 hours', true, true),
    (conv3_id, demo_user_id, sofia_id, 'I am starting to read in Spanish. Any recommendations for beginners?', 'English', '{"es": "Estoy empezando a leer en espanol. Alguna recomendacion para principiantes?"}'::jsonb, NOW() - INTERVAL '1 day', true, true),
    (conv3_id, sofia_id, demo_user_id, 'Te recomiendo El Principito - The Little Prince. Es perfecto para aprender!', 'Spanish', '{"en": "I recommend The Little Prince. It is perfect for learning!"}'::jsonb, NOW() - INTERVAL '12 hours', true, true),
    (conv3_id, demo_user_id, sofia_id, 'Oh I love that book! I will try reading it in Spanish. Gracias!', 'English', '{"es": "Oh me encanta ese libro! Intentare leerlo en espanol. Gracias!"}'::jsonb, NOW() - INTERVAL '6 hours', true, true),
    (conv3_id, sofia_id, demo_user_id, 'De nada! Let me know if you have questions about any words.', 'English', '{"es": "De nada! Dime si tienes preguntas sobre alguna palabra."}'::jsonb, NOW() - INTERVAL '3 hours', true, true);

    -- Messages: Hannah + Carlos (Spanish)
    INSERT INTO messages (conversation_id, sender_id, receiver_id, original_text, original_language, translated_text, created_at, is_read, is_delivered) VALUES
    (conv4_id, carlos_id, demo_user_id, 'Hola Hannah! Soy Carlos de Barcelona. Me encanta tu perfil!', 'Spanish', '{"en": "Hello Hannah! I am Carlos from Barcelona. I love your profile!"}'::jsonb, NOW() - INTERVAL '1 day', true, true),
    (conv4_id, demo_user_id, carlos_id, 'Hola Carlos! Gracias! Barcelona is one of my dream destinations!', 'English', '{"es": "Hola Carlos! Gracias! Barcelona es uno de mis destinos sonados!"}'::jsonb, NOW() - INTERVAL '1 day' + INTERVAL '15 min', true, true),
    (conv4_id, carlos_id, demo_user_id, 'You should visit! I can show you Gaudi architecture - it is amazing.', 'English', '{"es": "Deberias visitar! Puedo mostrarte la arquitectura de Gaudi - es increible."}'::jsonb, NOW() - INTERVAL '20 hours', true, true),
    (conv4_id, demo_user_id, carlos_id, 'Me encantaria ver La Sagrada Familia! Is it impressive in person?', 'English', '{"es": "Me encantaria ver La Sagrada Familia! Es impresionante en persona?"}'::jsonb, NOW() - INTERVAL '10 hours', true, true),
    (conv4_id, carlos_id, demo_user_id, 'Es increible! The light through the windows is magical. Te va a encantar.', 'Spanish', '{"en": "It is incredible! The light through the windows is magical. You are going to love it."}'::jsonb, NOW() - INTERVAL '30 minutes', true, true);

    RAISE NOTICE 'Created 26 messages';

    -- Update conversation previews
    UPDATE conversations SET last_message_preview = 'That sounds amazing! Merci beaucoup!' WHERE id = conv1_id;
    UPDATE conversations SET last_message_preview = 'I would love to visit Lyon someday!' WHERE id = conv2_id;
    UPDATE conversations SET last_message_preview = 'De nada! Let me know if you have questions.' WHERE id = conv3_id;
    UPDATE conversations SET last_message_preview = 'Es increible! The light through the windows is magical.' WHERE id = conv4_id;

    RAISE NOTICE '========================================';
    RAISE NOTICE 'Demo setup complete!';
    RAISE NOTICE '4 matches, 4 conversations, 26 messages';
    RAISE NOTICE '========================================';
END $$;
