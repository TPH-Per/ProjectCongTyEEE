-- =============================================================================
-- shift_open RPC
-- Date: 2026-07-03
--
-- No open-shift path existed in the codebase — the Edge Function close-shift
-- closes any open row but nothing ever inserts one. As a result payments made
-- without an open shift get shift_id=NULL and disappear from shift reports.
--
-- This RPC + Edge Function + UI provides a real "Open shift" button. It is
-- idempotent: if the caller already has an open shift in their branch, that
-- row is returned without inserting a duplicate.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.shift_open(
  p_branch_id    uuid,
  p_opening_cash numeric(14,2) DEFAULT 0,
  p_notes        jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := public.current_user_id();
  v_existing record;
  v_row public.shifts%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHENTICATED' USING ERRCODE = '28000';
  END IF;

  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::public.user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;

  IF p_opening_cash IS NULL OR p_opening_cash < 0 THEN
    RAISE EXCEPTION 'OPENING_CASH_INVALID' USING ERRCODE = '22023';
  END IF;

  -- Idempotent: return the existing open shift if the caller has one in this branch.
  SELECT * INTO v_existing
  FROM public.shifts
  WHERE user_id = v_user_id
    AND branch_id = p_branch_id
    AND status = 'open'
  LIMIT 1;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'ok', true,
      'idempotent', true,
      'shift', row_to_json(v_existing)
    );
  END IF;

  INSERT INTO public.shifts (
    branch_id, user_id, status, opened_at,
    opening_cash, notes, metadata
  ) VALUES (
    p_branch_id, v_user_id, 'open', now(),
    p_opening_cash, COALESCE(p_notes, '{}'::jsonb),
    jsonb_build_object('opened_via', 'shift_open_rpc')
  )
  RETURNING * INTO v_row;

  RETURN jsonb_build_object(
    'ok', true,
    'idempotent', false,
    'shift', row_to_json(v_row)
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.shift_open(uuid, numeric, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.shift_open(uuid, numeric, jsonb) TO authenticated, service_role;

COMMENT ON FUNCTION public.shift_open(uuid, numeric, jsonb) IS
  'Idempotent shift opener for the current user/branch. Returns the existing '
  'open shift if one exists; otherwise inserts a new row and returns it.';