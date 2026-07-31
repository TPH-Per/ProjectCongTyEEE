CREATE OR REPLACE FUNCTION public.hall_open_table(
  p_branch_id uuid,
  p_table_id uuid,
  p_package_id uuid DEFAULT NULL,
  p_guest_count integer DEFAULT 2,
  p_service_mode text DEFAULT 'a_la_carte',
  p_customer_name text DEFAULT 'Walk-in',
  p_opened_by text DEFAULT 'reception'
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_session_id uuid;
  v_service_config jsonb;
BEGIN
  -- Build service config if package is selected
  IF p_package_id IS NOT NULL THEN
    v_service_config := jsonb_build_object('package_id', p_package_id);
    p_service_mode := 'buffet';
  ELSE
    v_service_config := '{}'::jsonb;
  END IF;

  INSERT INTO public.dining_sessions (
    branch_id, guest_count, service_mode, status, service_config, opened_by_profile_id
  ) VALUES (
    p_branch_id, p_guest_count, p_service_mode, 'open', v_service_config, NULL
  ) RETURNING dining_session_id INTO v_session_id;

  INSERT INTO public.session_tables (
    branch_id, dining_session_id, dining_table_id
  ) VALUES (
    p_branch_id, v_session_id, p_table_id
  );

  RETURN json_build_object(
    'id', v_session_id,
    'created_at', now()
  );
END;
$function$;

GRANT EXECUTE ON FUNCTION public.hall_open_table(uuid, uuid, uuid, integer, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hall_open_table(uuid, uuid, uuid, integer, text, text, text) TO anon;
