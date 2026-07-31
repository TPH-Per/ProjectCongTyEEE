CREATE OR REPLACE FUNCTION public.rpc_transfer_table_all(
  p_branch_id uuid,
  p_source_table_id uuid,
  p_target_table_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_source_session_id uuid;
BEGIN
  -- 1. Check source table
  SELECT dining_session_id INTO v_source_session_id
  FROM public.session_tables
  WHERE dining_table_id = p_source_table_id AND left_at IS NULL
  LIMIT 1;

  IF v_source_session_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Source table has no active session');
  END IF;

  RETURN public.rpc_transfer_or_merge_table(v_source_session_id, p_target_table_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_transfer_table_all TO authenticated;
