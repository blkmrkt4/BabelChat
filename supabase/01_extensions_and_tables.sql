-- Part 1: Extensions and Core Tables
-- Execute this first in Supabase SQL Editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    phone_number TEXT UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT,
    bio TEXT,
    birth_year INTEGER,
    age INTEGER,
    location TEXT,
    show_city_in_profile BOOLEAN DEFAULT true,
    native_language TEXT NOT NULL,
    learning_languages TEXT[] DEFAULT '{}',
    proficiency_levels JSONB DEFAULT '{}',
    learning_goals TEXT[] DEFAULT '{}',
    profile_photos TEXT[] DEFAULT '{}',
    is_premium BOOLEAN DEFAULT false,
    granularity_level INTEGER DEFAULT 2 CHECK (granularity_level BETWEEN 0 AND 3),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active TIMESTAMPTZ DEFAULT NOW(),
    onboarding_completed BOOLEAN DEFAULT false,

    CONSTRAINT valid_birth_year CHECK (birth_year >= 1900 AND birth_year <= EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER - 13)
);

-- 2. User languages table
CREATE TABLE IF NOT EXISTS user_languages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    language TEXT NOT NULL,
    proficiency TEXT CHECK (proficiency IN ('native', 'fluent', 'intermediate', 'beginner')),
    is_native BOOLEAN DEFAULT false,
    is_learning BOOLEAN DEFAULT false,
    is_open_to_practice BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_user_language UNIQUE (user_id, language)
);

-- 3. Matches table
CREATE TABLE IF NOT EXISTS matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    user1_liked BOOLEAN DEFAULT false,
    user2_liked BOOLEAN DEFAULT false,
    is_mutual BOOLEAN GENERATED ALWAYS AS (user1_liked AND user2_liked) STORED,
    match_type TEXT DEFAULT 'normal' CHECK (match_type IN ('normal', 'super_like')),
    matched_language TEXT,
    matched_at TIMESTAMPTZ DEFAULT NOW(),
    conversation_id UUID,
    is_active BOOLEAN DEFAULT true,
    last_interaction TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_match_pair UNIQUE (user1_id, user2_id),
    CONSTRAINT no_self_match CHECK (user1_id != user2_id)
);

-- 4. Swipes table
CREATE TABLE IF NOT EXISTS swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    swiped_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    direction TEXT NOT NULL CHECK (direction IN ('left', 'right', 'super')),
    shown_language TEXT,
    swiped_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_swipe UNIQUE (swiper_id, swiped_id),
    CONSTRAINT no_self_swipe CHECK (swiper_id != swiped_id)
);