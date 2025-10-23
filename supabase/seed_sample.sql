-- Seed sample data for testing the app after recreating schema
-- WARNING: IDs used here are examples. Replace with real user UUIDs if needed.

-- Option: create a test user profile (use an existing auth.users id if possible)
-- If you don't have a user in auth.users, create a dummy UUID and later adjust the app auth for testing.

-- Example: insert a test user profile (replace id with a real auth.users id to match)
INSERT INTO public.users (id, email, full_name, avatar_url, bio, created_at)
VALUES ('00000000-0000-0000-0000-000000000000','test@example.com','Test User', NULL, 'Cuenta de prueba', NOW())
ON CONFLICT (id) DO NOTHING;

-- Insert a sample route for that user (use same id as above if testing without auth.users)
INSERT INTO public.routes (id, user_id, name, activity_type, distance, duration, coordinates, is_public, created_at)
VALUES (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'Ruta de prueba',
  'running',
  5.2,
  1800,
  '[{"latitude": -0.180653, "longitude": -78.467834}, {"latitude": -0.181, "longitude": -78.468}]'::jsonb,
  true,
  NOW()
);

-- Insert a comment and a like (optional)
INSERT INTO public.comments (id, route_id, user_id, content, created_at)
SELECT gen_random_uuid(), r.id, '00000000-0000-0000-0000-000000000000', 'Comentario de prueba', NOW()
FROM public.routes r WHERE r.user_id = '00000000-0000-0000-0000-000000000000' LIMIT 1;

INSERT INTO public.likes (id, route_id, user_id, created_at)
SELECT gen_random_uuid(), r.id, '00000000-0000-0000-0000-000000000000', NOW()
FROM public.routes r WHERE r.user_id = '00000000-0000-0000-0000-000000000000' LIMIT 1
ON CONFLICT (route_id, user_id) DO NOTHING;

-- Verify sample data
SELECT COUNT(*) AS routes FROM public.routes;
SELECT COUNT(*) AS comments FROM public.comments;
SELECT COUNT(*) AS likes FROM public.likes;
