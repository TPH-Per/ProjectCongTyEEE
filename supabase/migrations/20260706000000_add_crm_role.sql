-- Migration to add 'crm' role to user_role enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    RAISE EXCEPTION 'user_role enum not found';
  END IF;

  -- Attempt to add 'crm' if it doesn't exist
  BEGIN
    ALTER TYPE public.user_role ADD VALUE 'crm';
  EXCEPTION WHEN duplicate_object THEN
    -- Ignore if it already exists
  END;
END $$;
