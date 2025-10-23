-- WARNING: Destructive cleanup script
-- This script will irreversibly DROP tables, policies, functions, triggers and other objects in the public schema
-- BACKUP your database before running. Prefer exporting a SQL dump from Supabase or using `pg_dump`.

-- Drop triggers (if they exist)
DROP TRIGGER IF EXISTS on_comment_created ON public.comments;
DROP TRIGGER IF EXISTS on_comment_deleted ON public.comments;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop helper functions
DROP FUNCTION IF EXISTS public.increment_likes(uuid);
DROP FUNCTION IF EXISTS public.decrement_likes(uuid);
DROP FUNCTION IF EXISTS public.increment_comments();
DROP FUNCTION IF EXISTS public.decrement_comments();
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Drop policies that commonly exist in this project (safe to keep IF EXISTS)
DROP POLICY IF EXISTS routes_select_public_or_owner ON public.routes;
DROP POLICY IF EXISTS routes_insert_own ON public.routes;
DROP POLICY IF EXISTS routes_update_own ON public.routes;
DROP POLICY IF EXISTS routes_delete_own ON public.routes;

DROP POLICY IF EXISTS users_select_all ON public.users;
DROP POLICY IF EXISTS users_update_own ON public.users;
DROP POLICY IF EXISTS users_insert_own ON public.users;

DROP POLICY IF EXISTS comments_select_public_routes ON public.comments;
DROP POLICY IF EXISTS comments_insert_auth ON public.comments;
DROP POLICY IF EXISTS comments_update_own ON public.comments;
DROP POLICY IF EXISTS comments_delete_own ON public.comments;

DROP POLICY IF EXISTS likes_select_all ON public.likes;
DROP POLICY IF EXISTS likes_insert_auth ON public.likes;
DROP POLICY IF EXISTS likes_delete_own ON public.likes;
DROP POLICY IF EXISTS likes_delete_owner ON public.likes;

DROP POLICY IF EXISTS follows_select_all ON public.follows;
DROP POLICY IF EXISTS follows_insert_auth ON public.follows;
DROP POLICY IF EXISTS follows_delete_own ON public.follows;

-- Drop tables (CASCADE will remove dependent objects)
DROP TABLE IF EXISTS public.likes CASCADE;
DROP TABLE IF EXISTS public.comments CASCADE;
DROP TABLE IF EXISTS public.routes CASCADE;
DROP TABLE IF EXISTS public.follows CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Optionally drop all remaining objects in public schema (uncomment to enable)
-- VERY DESTRUCTIVE: removes every table, view, sequence, function, type in public
-- DO NOT run unless you have a full backup and understand consequences

-- DO $$
-- DECLARE r RECORD;
-- BEGIN
--   FOR r IN SELECT tablename FROM pg_tables WHERE schemaname='public' LOOP
--     EXECUTE format('DROP TABLE IF EXISTS public.%I CASCADE', r.tablename);
--   END LOOP;
--   FOR r IN SELECT routine_name FROM information_schema.routines WHERE routine_schema='public' LOOP
--     EXECUTE format('DROP FUNCTION IF EXISTS public.%I CASCADE', r.routine_name);
--   END LOOP;
-- END$$;

-- Optionally remove the uuid extension (keep if shared)
-- DROP EXTENSION IF EXISTS "uuid-ossp" CASCADE;

-- Revoke public privileges on public schema (optional safety hardening)
-- REVOKE ALL ON SCHEMA public FROM PUBLIC;

-- Final note
SELECT 'Destructive cleanup completed (review actions above). Remember to restore from backup if this was run accidentally.' AS notice;
