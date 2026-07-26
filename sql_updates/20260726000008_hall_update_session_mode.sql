CREATE OR REPLACE FUNCTION public.hall_update_session_mode(
  p_branch_id uuid,
  p_table_id uuid,
  p_service_mode text,
  p_package_id uuid DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_session_id uuid;
  v_service_config jsonb;
BEGIN
  -- Find the active dining session for this table
  SELECT ds.dining_session_id INTO v_session_id
  FROM   public.session_tables st
  JOIN   public.dining_sessions ds ON ds.dining_session_id = st.dining_session_id
  WHERE  st.dining_table_id = p_table_id
    AND  ds.branch_id = p_branch_id
    AND  ds.status    = 'open'
  ORDER  BY ds.created_at DESC
  LIMIT  1;

  IF v_session_id IS NULL THEN
    RETURN json_build_object('ok', false, 'error', 'No open session for this table');
  END IF;

  -- Build service config if package is selected
  IF p_service_mode = 'buffet' AND p_package_id IS NOT NULL THEN
    v_service_config := jsonb_build_object('package_id', p_package_id);
  ELSE
    p_service_mode := 'a_la_carte';
    v_service_config := '{}'::jsonb;
  END IF;

  UPDATE public.dining_sessions
  SET service_mode = p_service_mode,
      service_config = v_service_config,
      updated_at = now()
  WHERE dining_session_id = v_session_id
    AND branch_id = p_branch_id;

  RETURN json_build_object(
    'ok', true,
    'session_id', v_session_id,
    'service_mode', p_service_mode,
    'updated_at', now()
  );
END;
$function$;

GRANT EXECUTE ON FUNCTION public.hall_update_session_mode(uuid, uuid, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hall_update_session_mode(uuid, uuid, text, uuid) TO anon;
