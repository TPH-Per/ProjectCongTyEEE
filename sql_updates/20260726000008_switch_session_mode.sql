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
  -- Validate inputs
  IF p_service_mode NOT IN ('a_la_carte', 'buffet') THEN
    RAISE EXCEPTION 'Invalid service mode: %', p_service_mode;
  END IF;

  -- Build service config
  IF p_service_mode = 'buffet' THEN
    IF p_package_id IS NULL THEN
       p_package_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;
    v_service_config := jsonb_build_object('package_id', p_package_id);
  ELSE
    v_service_config := '{}'::jsonb;
  END IF;

  -- Find open session for this table
  SELECT ds.dining_session_id INTO v_session_id
  FROM public.session_tables st
  JOIN public.dining_sessions ds ON ds.dining_session_id = st.dining_session_id
  WHERE st.dining_table_id = p_table_id
    AND ds.branch_id = p_branch_id
    AND ds.status = 'open'
  LIMIT 1;

  IF v_session_id IS NULL THEN
    RAISE EXCEPTION 'No open session found for this table';
  END IF;

  UPDATE public.dining_sessions
  SET service_mode = p_service_mode,
      service_config = v_service_config
  WHERE dining_session_id = v_session_id
    AND branch_id = p_branch_id;
  
  RETURN json_build_object(
    'ok', true,
    'session_id', v_session_id,
    'new_mode', p_service_mode,
    'service_config', v_service_config
  );
END;
$function$;

GRANT EXECUTE ON FUNCTION public.hall_update_session_mode(uuid, uuid, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hall_update_session_mode(uuid, uuid, text, uuid) TO anon;
