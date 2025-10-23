-- WARNING: Full wipe-and-recreate script
-- This script DROPS the entire public schema and recreates it.
-- THIS IS IRREVERSIBLE unless you have a backup. Create a DB snapshot or pg_dump BEFORE running.
-- Recommended: run in Supabase SQL editor or via psql with a strong backup in place.

-- Safety check: ensure you really want to run this
RAISE NOTICE 'Starting full wipe of public schema. Make sure you have a backup!';

-- Drop and recreate public schema (CASCADE removes everything under public)
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- Recreate default privileges (optional)
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- Create uuid extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- === Create tables ===

-- Users table (profile data, extends auth.users)
CREATE TABLE public.users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  total_distance FLOAT DEFAULT 0,
  total_time INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Routes table
CREATE TABLE public.routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('running', 'walking', 'cycling', 'hiking')),
  distance FLOAT NOT NULL CHECK (distance >= 0),
  duration INTEGER NOT NULL CHECK (duration >= 0),
  avg_speed FLOAT,
  coordinates JSONB NOT NULL,
  is_public BOOLEAN DEFAULT false,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comments table
CREATE TABLE public.comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES public.routes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Likes table
CREATE TABLE public.likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES public.routes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(route_id, user_id)
);

-- Follows table
CREATE TABLE public.follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- Indexes
CREATE INDEX idx_routes_user_id ON public.routes(user_id);
CREATE INDEX idx_routes_is_public ON public.routes(is_public);
CREATE INDEX idx_routes_created_at ON public.routes(created_at DESC);
CREATE INDEX idx_comments_route_id ON public.comments(route_id);
CREATE INDEX idx_likes_route_id ON public.likes(route_id);
CREATE INDEX idx_likes_user_id ON public.likes(user_id);
CREATE INDEX idx_follows_follower ON public.follows(follower_id);
CREATE INDEX idx_follows_following ON public.follows(following_id);

-- === Row Level Security ===
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY users_select_all ON public.users FOR SELECT USING (true);
CREATE POLICY users_update_own ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY users_insert_own ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY routes_select_public_or_owner ON public.routes FOR SELECT USING (is_public = true OR auth.uid() = user_id);
CREATE POLICY routes_insert_own ON public.routes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY routes_update_own ON public.routes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY routes_delete_own ON public.routes FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY comments_select_public_routes ON public.comments FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.routes r WHERE r.id = public.comments.route_id AND (r.is_public = true OR r.user_id = auth.uid())
  )
);
CREATE POLICY comments_insert_auth ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY comments_update_own ON public.comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY comments_delete_own ON public.comments FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY likes_select_all ON public.likes FOR SELECT USING (true);
CREATE POLICY likes_insert_auth ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY likes_delete_own ON public.likes FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY follows_select_all ON public.follows FOR SELECT USING (true);
CREATE POLICY follows_insert_auth ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY follows_delete_own ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- === Functions and Triggers ===
-- Likes counters
CREATE OR REPLACE FUNCTION public.increment_likes(route_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.routes SET likes_count = likes_count + 1 WHERE id = route_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.decrement_likes(route_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.routes SET likes_count = GREATEST(0, likes_count - 1) WHERE id = route_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments counters
CREATE OR REPLACE FUNCTION public.increment_comments()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.routes SET comments_count = comments_count + 1 WHERE id = NEW.route_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.decrement_comments()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.routes SET comments_count = GREATEST(0, comments_count - 1) WHERE id = OLD.route_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER on_comment_created AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION public.increment_comments();
CREATE TRIGGER on_comment_deleted AFTER DELETE ON public.comments FOR EACH ROW EXECUTE FUNCTION public.decrement_comments();

-- Create user profile when a new auth.user is created (auth.users is in auth schema managed by Supabase)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, created_at)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', NULL), NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- The following trigger must be created on auth.users (auth schema). In Supabase SQL editor this is allowed.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Final message
SELECT 'Wipe and recreate finished. Verify auth triggers and policies in Supabase dashboard.' AS notice;
