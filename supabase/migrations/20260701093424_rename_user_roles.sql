ALTER TYPE public.user_role RENAME VALUE 'admin' TO 'superadmin';
ALTER TYPE public.user_role RENAME VALUE 'procurement' TO 'procurement_manager';
ALTER TYPE public.user_role RENAME VALUE 'accounting' TO 'accountant';

ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'procurement_staff';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'crm_manager';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'marketing';

UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  raw_user_meta_data,
  '{role}',
  '"superadmin"'
)
WHERE raw_user_meta_data->>'role' = 'admin';

UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  raw_user_meta_data,
  '{role}',
  '"procurement_manager"'
)
WHERE raw_user_meta_data->>'role' = 'procurement';

UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  raw_user_meta_data,
  '{role}',
  '"accountant"'
)
WHERE raw_user_meta_data->>'role' = 'accounting';

