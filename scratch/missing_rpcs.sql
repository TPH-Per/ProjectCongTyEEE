-- ====================================================================
-- RPCs con thieu cho chuc nang Cashier: Reservations
-- ====================================================================

-- 1. Tao dat ban thu cong (Walk-in / Hotline) - BE-1.6
CREATE OR REPLACE FUNCTION public.rpc_create_reservation(
  p_guest_name      text,
  p_phone           text,
  p_guest_count     integer,
  p_reserved_from   timestamptz,
  p_reserved_to     timestamptz,
  p_source_channel  text    DEFAULT 'Walk-in',
  p_note            text    DEFAULT '',
  p_deposit_amount  bigint  DEFAULT 0,
  p_deposit_method  text    DEFAULT 'CASH',
  p_branch_id       uuid    DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_reservation_id uuid;
  v_branch_id      uuid;
BEGIN
  v_branch_id := p_branch_id;
  IF v_branch_id IS NULL THEN
    SELECT branch_id INTO v_branch_id
    FROM   public.staff_assignments
    WHERE  profile_id = auth.uid()
      AND  is_active  = true
      AND  ended_at  IS NULL
    LIMIT 1;
  END IF;

  INSERT INTO public.reservations (
    branch_id, guest_name_snapshot, phone_snapshot,
    guest_count, reserved_from, reserved_to,
    source_channel, note,
    deposit_amount_vnd, deposit_method, deposit_status,
    status, created_by_profile_id
  ) VALUES (
    v_branch_id, p_guest_name, p_phone,
    p_guest_count, p_reserved_from, p_reserved_to,
    p_source_channel, p_note,
    p_deposit_amount, p_deposit_method,
    CASE WHEN p_deposit_amount > 0 THEN 'RECEIVED' ELSE 'NONE' END,
    'PENDING', auth.uid()
  )
  RETURNING reservation_id INTO v_reservation_id;

  RETURN jsonb_build_object(
    'success',        true,
    'reservation_id', v_reservation_id
  );
END;
$$;

-- 2. Huy ban / No-show - BE-1.7
CREATE OR REPLACE FUNCTION public.rpc_cancel_reservation(
  p_reservation_id uuid,
  p_reason         text    DEFAULT 'Khach khong den',
  p_is_noshow      boolean DEFAULT false
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_new_status text;
BEGIN
  v_new_status := CASE WHEN p_is_noshow THEN 'NO_SHOW' ELSE 'CANCELLED' END;

  UPDATE public.reservations
  SET    status     = v_new_status,
         note       = COALESCE(note, '') || ' [' || v_new_status || ': ' || p_reason || ']',
         updated_at = now()
  WHERE  reservation_id = p_reservation_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reservation not found: %', p_reservation_id;
  END IF;

  RETURN jsonb_build_object('success', true, 'status', v_new_status);
END;
$$;

-- 3. Cap nhat tien coc - BE-1.5
CREATE OR REPLACE FUNCTION public.rpc_update_reservation_deposit(
  p_reservation_id uuid,
  p_deposit_amount bigint,
  p_deposit_method text DEFAULT 'CASH'
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.reservations
  SET    deposit_amount_vnd = p_deposit_amount,
         deposit_method     = p_deposit_method,
         deposit_status     = CASE WHEN p_deposit_amount > 0 THEN 'RECEIVED' ELSE 'NONE' END,
         updated_at         = now()
  WHERE  reservation_id = p_reservation_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reservation not found: %', p_reservation_id;
  END IF;

  RETURN jsonb_build_object('success', true, 'deposit_amount', p_deposit_amount);
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.rpc_create_reservation TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_cancel_reservation  TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_update_reservation_deposit TO authenticated;

SELECT 'RPCs created: rpc_create_reservation, rpc_cancel_reservation, rpc_update_reservation_deposit' AS result;
