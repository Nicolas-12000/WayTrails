-- Supabase schema for WayTrails (based on README and app code)
-- Run this in Supabase SQL editor or via psql. Make sure the "uuid-ossp" extension is available.

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (profile data, extends auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  total_distance FLOAT DEFAULT 0,
  total_time INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Routes table
CREATE TABLE IF NOT EXISTS public.routes (
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
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES public.routes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Likes table
CREATE TABLE IF NOT EXISTS public.likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES public.routes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(route_id, user_id)
);

-- Follows table
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_routes_user_id ON public.routes(user_id);
CREATE INDEX IF NOT EXISTS idx_routes_is_public ON public.routes(is_public);
CREATE INDEX IF NOT EXISTS idx_routes_created_at ON public.routes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_route_id ON public.comments(route_id);
CREATE INDEX IF NOT EXISTS idx_likes_route_id ON public.likes(route_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON public.likes(user_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows(following_id);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- RLS Policies (named without spaces for easier programmatic checks)
-- Users
CREATE POLICY IF NOT EXISTS users_select_all ON public.users FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS users_update_own ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY IF NOT EXISTS users_insert_own ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- Routes
CREATE POLICY IF NOT EXISTS routes_select_public_or_owner ON public.routes FOR SELECT USING (is_public = true OR auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS routes_insert_own ON public.routes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS routes_update_own ON public.routes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS routes_delete_own ON public.routes FOR DELETE USING (auth.uid() = user_id);

-- Comments
CREATE POLICY IF NOT EXISTS comments_select_public_routes ON public.comments FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.routes r WHERE r.id = public.comments.route_id AND (r.is_public = true OR r.user_id = auth.uid())
  )
);
CREATE POLICY IF NOT EXISTS comments_insert_auth ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS comments_update_own ON public.comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS comments_delete_own ON public.comments FOR DELETE USING (auth.uid() = user_id);

-- Likes
CREATE POLICY IF NOT EXISTS likes_select_all ON public.likes FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS likes_insert_auth ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS likes_delete_own ON public.likes FOR DELETE USING (auth.uid() = user_id);

-- Follows
CREATE POLICY IF NOT EXISTS follows_select_all ON public.follows FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS follows_insert_auth ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY IF NOT EXISTS follows_delete_own ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- Functions to increment/decrement likes count
CREATE OR REPLACE FUNCTION public.increment_likes(route_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.routes
  SET likes_count = likes_count + 1
  WHERE id = route_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.decrement_likes(route_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.routes
  SET likes_count = GREATEST(0, likes_count - 1)
  WHERE id = route_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Functions and triggers for comments count
CREATE OR REPLACE FUNCTION public.increment_comments()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.routes
  SET comments_count = comments_count + 1
  WHERE id = NEW.route_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.decrement_comments()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.routes
  SET comments_count = GREATEST(0, comments_count - 1)
  WHERE id = OLD.route_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Triggers
DROP TRIGGER IF EXISTS on_comment_created ON public.comments;
CREATE TRIGGER on_comment_created
  AFTER INSERT ON public.comments
  FOR EACH ROW
  EXECUTE FUNCTION public.increment_comments();

DROP TRIGGER IF EXISTS on_comment_deleted ON public.comments;
CREATE TRIGGER on_comment_deleted
  AFTER DELETE ON public.comments
  FOR EACH ROW
  EXECUTE FUNCTION public.decrement_comments();

-- Function to create user profile on signup (auth.users trigger)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NULL),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create user profile (on auth.users)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Helpful: corrected way to check if a policy exists for a given table/name
-- Example:
-- SELECT EXISTS(
--   SELECT 1 FROM pg_policy p
--   JOIN pg_class c ON p.polrelid = c.oid
--   JOIN pg_namespace n ON c.relnamespace = n.oid
--   WHERE c.relname = 'routes' AND n.nspname = 'public' AND p.polname = 'routes_select_public_or_owner'
-- );

-- Optional seed data example (commented)
-- INSERT INTO public.users (id, email, full_name) VALUES ('00000000-0000-0000-0000-000000000000','test@example.com','Test User');

SELECT 'Schema creation finished' AS notice;
