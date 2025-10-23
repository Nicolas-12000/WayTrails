-- Backfill script: copy existing auth.users into public.users for profiles
-- Run this after you have recreated the public schema (e.g., after wipe_and_recreate.sql)
-- It will insert missing profiles for users already present in auth.users

INSERT INTO public.users (id, email, full_name, avatar_url, created_at)
SELECT au.id, au.email, COALESCE(au.raw_user_meta_data->>'full_name', NULL), NULL, NOW()
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM public.users pu WHERE pu.id = au.id);

-- Check inserted rows
SELECT COUNT(*) AS inserted_profiles FROM public.users;
