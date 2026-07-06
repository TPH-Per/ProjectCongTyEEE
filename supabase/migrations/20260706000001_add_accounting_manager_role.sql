-- ============================================================
-- ACCOUNTING MODULE - PART 1: Add new enum value
-- Must be in separate migration from Part 2 due to PostgreSQL
-- restriction on using new enum values in same transaction.
-- ============================================================

-- Add accounting_manager to user_role enum (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'accounting_manager'
      AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_role')
  ) THEN
    ALTER TYPE public.user_role ADD VALUE 'accounting_manager';
  END IF;
END$$;
