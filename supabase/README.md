WayTrails — Supabase quick ops

This folder contains SQL scripts to wipe, recreate, backfill and seed the Supabase database used by the app.

Files
- wipe_and_recreate.sql  — Drops `public` schema and recreates tables, policies, functions and triggers. DESTRUCTIVE.
- destructive.sql        — Destructive cleanup helper (drops specific objects). Less aggressive.
- schema.sql             — Non-destructive schema creation (uses IF NOT EXISTS).
- backfill_users.sql     — Copies existing rows from `auth.users` into `public.users` to create profiles.
- seed_sample.sql        — Inserts a small test user + route/comment/like to test the app.

Recommended order (safe path)
1. BACKUP your database (Supabase snapshot or `pg_dump`).
2. Run `wipe_and_recreate.sql` only if you want a clean fresh public schema. Otherwise run `schema.sql` to only create missing objects.
3. Run `backfill_users.sql` to populate `public.users` from existing `auth.users`.
4. (Optional) Run `seed_sample.sql` to create demo data for quick testing.

Verification queries
- List tables in public:
  SELECT tablename FROM pg_tables WHERE schemaname = 'public';

- Check RLS policies for `routes`:
  SELECT p.polname, n.nspname AS schema, c.relname AS table
  FROM pg_policy p
  JOIN pg_class c ON p.polrelid = c.oid
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE c.relname = 'routes';

- Check triggers:
  SELECT event_object_schema, event_object_table, trigger_name
  FROM information_schema.triggers
  WHERE event_object_schema IN ('public','auth');

Notes & tips
- If you recreate the schema and users are already in `auth.users`, use `backfill_users.sql` so your app can see user profiles.
- If you plan to keep production data, do NOT run `wipe_and_recreate.sql` on prod without a verified backup.
- If you need help running these from PowerShell/psql, I can generate the exact commands.
