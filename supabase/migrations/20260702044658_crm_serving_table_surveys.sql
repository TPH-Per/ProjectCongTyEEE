-- =============================================================================
-- CRM SERVING TABLE SURVEYS
-- Date: 2026-07-02
--
-- Business rule:
--   CRM survey belongs to the current dining order/session, not to a table.
--   table_id is display context only. Anti-duplication is enforced by order_id
--   and table_assignment_id so old surveys never leak into a later seating.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    RAISE EXCEPTION 'Base schema must run before crm_serving_table_surveys';
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- Guest DB additions. Keep additive and nullable to avoid breaking existing data.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crm_normalize_phone(p_phone text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_digits text;
BEGIN
  v_digits := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');

  IF v_digits = '' THEN
    RETURN NULL;
  END IF;

  IF v_digits LIKE '0084%' AND length(v_digits) >= 6 THEN
    v_digits := '0' || substring(v_digits from 5);
  ELSIF v_digits LIKE '84%' AND length(v_digits) BETWEEN 10 AND 12 THEN
    v_digits := '0' || substring(v_digits from 3);
  END IF;

  RETURN v_digits;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.crm_normalize_phone(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_normalize_phone(text) TO authenticated, service_role;

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS normalized_phone text,
  ADD COLUMN IF NOT EXISTS source_code text,
  ADD COLUMN IF NOT EXISTS visit_reason text,
  ADD COLUMN IF NOT EXISTS first_visit_at timestamptz,
  ADD COLUMN IF NOT EXISTS marketing_consent boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS marketing_tags jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS zalo text;

UPDATE public.customers
SET
  normalized_phone = COALESCE(normalized_phone, public.crm_normalize_phone(phone)),
  first_visit_at = COALESCE(first_visit_at, last_visit_at, created_at)
WHERE normalized_phone IS NULL
   OR first_visit_at IS NULL;

CREATE INDEX IF NOT EXISTS customers_branch_normalized_phone_idx
  ON public.customers (branch_id, normalized_phone)
  WHERE normalized_phone IS NOT NULL AND btrim(normalized_phone) <> '';

CREATE INDEX IF NOT EXISTS customers_branch_source_idx
  ON public.customers (branch_id, source_code)
  WHERE source_code IS NOT NULL;

-- -----------------------------------------------------------------------------
-- Survey event table. This is event/session-level data, not profile-level data.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crm_surveys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  table_id uuid NOT NULL REFERENCES public.tables(id) ON DELETE RESTRICT,
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  table_assignment_id uuid REFERENCES public.table_assignments(id) ON DELETE SET NULL,
  reservation_id uuid REFERENCES public.reservations(id) ON DELETE SET NULL,
  bill_id uuid REFERENCES public.bills(id) ON DELETE SET NULL,
  customer_id uuid REFERENCES public.customers(id) ON DELETE SET NULL,

  source_code text,
  visit_reason text,
  feedback text,
  improvement_note text,
  customer_name text,
  customer_phone text,
  normalized_phone text,
  zalo text,
  marketing_consent boolean NOT NULL DEFAULT false,
  tags text[] DEFAULT ARRAY[]::text[],
  note text,

  survey_status text NOT NULL DEFAULT 'assigned'
    CHECK (survey_status IN (
      'not_started',
      'assigned',
      'in_progress',
      'completed',
      'skipped',
      'customer_refused',
      'expired',
      'late_submitted'
    )),
  asked_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  asked_at timestamptz,
  submitted_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT crm_surveys_session_identity_check
    CHECK (order_id IS NOT NULL OR table_assignment_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS crm_surveys_branch_status_idx
  ON public.crm_surveys (branch_id, survey_status, created_at DESC);

CREATE INDEX IF NOT EXISTS crm_surveys_branch_order_idx
  ON public.crm_surveys (branch_id, order_id)
  WHERE order_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS crm_surveys_bill_idx
  ON public.crm_surveys (bill_id)
  WHERE bill_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS crm_surveys_one_active_per_order
  ON public.crm_surveys (order_id)
  WHERE order_id IS NOT NULL
    AND survey_status IN ('assigned', 'in_progress', 'completed');

CREATE UNIQUE INDEX IF NOT EXISTS crm_surveys_one_active_per_session
  ON public.crm_surveys (table_assignment_id)
  WHERE table_assignment_id IS NOT NULL
    AND survey_status IN ('assigned', 'in_progress', 'completed');

DROP TRIGGER IF EXISTS set_crm_surveys_updated_at ON public.crm_surveys;
CREATE TRIGGER set_crm_surveys_updated_at
  BEFORE UPDATE ON public.crm_surveys
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.crm_surveys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "crm_surveys_branch_read" ON public.crm_surveys;
CREATE POLICY "crm_surveys_branch_read" ON public.crm_surveys
  FOR SELECT
  TO authenticated
  USING (
    branch_id = public.current_branch_id()
    OR public.has_role(ARRAY['admin']::public.user_role[])
  );

DROP POLICY IF EXISTS "crm_surveys_branch_insert" ON public.crm_surveys;
CREATE POLICY "crm_surveys_branch_insert" ON public.crm_surveys
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::public.user_role[]))
    AND public.has_role(ARRAY['admin','manager','crm','staff','reception']::public.user_role[])
  );

DROP POLICY IF EXISTS "crm_surveys_branch_update" ON public.crm_surveys;
CREATE POLICY "crm_surveys_branch_update" ON public.crm_surveys
  FOR UPDATE
  TO authenticated
  USING (
    (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::public.user_role[]))
    AND public.has_role(ARRAY['admin','manager','crm','staff','reception']::public.user_role[])
  )
  WITH CHECK (
    (branch_id = public.current_branch_id()
      OR public.has_role(ARRAY['admin']::public.user_role[]))
    AND public.has_role(ARRAY['admin','manager','crm','staff','reception']::public.user_role[])
  );

GRANT SELECT, INSERT, UPDATE ON public.crm_surveys TO authenticated;
GRANT SELECT, UPDATE ON public.customers TO authenticated;

-- -----------------------------------------------------------------------------
-- Shared access guard.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crm_assert_branch_access(p_branch_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF p_branch_id IS NULL THEN
    RAISE EXCEPTION 'BRANCH_REQUIRED' USING ERRCODE = '22023';
  END IF;

  IF p_branch_id IS DISTINCT FROM public.current_branch_id()
     AND NOT public.has_role(ARRAY['admin']::public.user_role[]) THEN
    RAISE EXCEPTION 'FORBIDDEN: branch mismatch' USING ERRCODE = '28000';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.crm_assert_branch_access(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_assert_branch_access(uuid) TO authenticated, service_role;

-- -----------------------------------------------------------------------------
-- Expire stale in-progress survey rows whose dining order/session is no longer
-- active. This is intentionally non-destructive.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crm_expire_old_surveys(p_branch_id uuid DEFAULT NULL)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid := COALESCE(p_branch_id, public.current_branch_id());
  v_count int := 0;
BEGIN
  PERFORM public.crm_assert_branch_access(v_branch_id);

  UPDATE public.crm_surveys s
  SET
    survey_status = 'expired',
    closed_at = COALESCE(s.closed_at, now()),
    updated_at = now()
  WHERE s.branch_id = v_branch_id
    AND s.survey_status IN ('assigned','in_progress')
    AND (
      s.order_id IS NULL
      OR NOT EXISTS (
        SELECT 1
        FROM public.orders o
        WHERE o.id = s.order_id
          AND o.branch_id = s.branch_id
          AND o.status IN ('Pending','Preparing','Served')
      )
    );

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.crm_expire_old_surveys(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_expire_old_surveys(uuid) TO authenticated;

-- -----------------------------------------------------------------------------
-- UC 6.1: list active serving tables with CRM state for the current order/session.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crm_list_serving_tables(p_branch_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid := COALESCE(p_branch_id, public.current_branch_id());
  v_result jsonb;
BEGIN
  PERFORM public.crm_assert_branch_access(v_branch_id);
  PERFORM public.crm_expire_old_surveys(v_branch_id);

  SELECT COALESCE(jsonb_agg(row_to_json(x) ORDER BY x.table_code), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT
      t.id AS table_id,
      t.code AS table_code,
      z.name AS zone_name,
      o.id AS order_id,
      ta.id AS table_assignment_id,
      o.reservation_id,
      o.created_at AS started_at,
      COALESCE(o.guest_count, (ta.metadata->>'party_size')::int, t.capacity) AS guest_count,
      s.id AS crm_survey_id,
      COALESCE(s.survey_status, 'not_started') AS crm_status,
      s.asked_by AS crm_asked_by,
      s.asked_at AS crm_asked_at,
      s.submitted_at AS crm_submitted_at,
      s.customer_name,
      s.customer_phone
    FROM public.orders o
    JOIN public.tables t ON t.id = o.table_id
    LEFT JOIN public.zones z ON z.id = t.zone_id
    LEFT JOIN LATERAL (
      SELECT ta1.*
      FROM public.table_assignments ta1
      WHERE ta1.table_id = t.id
        AND ta1.branch_id = o.branch_id
        AND ta1.released_at IS NULL
      ORDER BY ta1.assigned_at DESC
      LIMIT 1
    ) ta ON true
    LEFT JOIN LATERAL (
      SELECT s1.*
      FROM public.crm_surveys s1
      WHERE s1.branch_id = o.branch_id
        AND (
          s1.order_id = o.id
          OR (ta.id IS NOT NULL AND s1.table_assignment_id = ta.id)
        )
        AND s1.survey_status <> 'expired'
      ORDER BY s1.created_at DESC
      LIMIT 1
    ) s ON true
    WHERE o.branch_id = v_branch_id
      AND o.status IN ('Pending','Preparing','Served')
      AND t.status = 'occupied'
  ) x;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.crm_list_serving_tables(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_list_serving_tables(uuid) TO authenticated;

-- Keep existing CRM feedback/service-request views on the RPC-only path.
CREATE OR REPLACE FUNCTION public.crm_list_customer_feedback(p_branch_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid := COALESCE(p_branch_id, public.current_branch_id());
  v_result jsonb;
BEGIN
  PERFORM public.crm_assert_branch_access(v_branch_id);

  SELECT COALESCE(jsonb_agg(row_to_json(x) ORDER BY x.created_at DESC), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT
      f.*,
      jsonb_build_object('name', c.name, 'phone', c.phone) AS customer
    FROM public.customer_feedback f
    LEFT JOIN public.customers c ON c.id = f.customer_id
    WHERE f.branch_id = v_branch_id
    ORDER BY f.created_at DESC
  ) x;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.crm_list_customer_feedback(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_list_customer_feedback(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.crm_list_service_requests(p_branch_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_branch_id uuid := COALESCE(p_branch_id, public.current_branch_id());
  v_result jsonb;
BEGIN
  PERFORM public.crm_assert_branch_access(v_branch_id);

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'service_requests'
  ) THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(x) ORDER BY x.created_at DESC), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT
      sr.*,
      jsonb_build_object('code', t.code) AS table
    FROM public.service_requests sr
    LEFT JOIN public.tables t ON t.id = sr.table_id
    WHERE sr.branch_id = v_branch_id
    ORDER BY sr.created_at DESC
  ) x;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.crm_list_service_requests(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_list_service_requests(uuid) TO authenticated;

-- -----------------------------------------------------------------------------
-- Internal helper: resolve the order/session identity for CRM actions.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crm_resolve_serving_context(
  p_branch_id uuid,
  p_table_id uuid,
  p_order_id uuid DEFAULT NULL,
  p_table_assignment_id uuid DEFAULT NULL,
  p_allow_closed_order boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_assignment public.table_assignments%ROWTYPE;
  v_is_late boolean := false;
BEGIN
  PERFORM public.crm_assert_branch_access(p_branch_id);

  IF p_order_id IS NOT NULL THEN
    SELECT * INTO v_order
    FROM public.orders
    WHERE id = p_order_id
      AND branch_id = p_branch_id
      AND (p_table_id IS NULL OR table_id = p_table_id);
  ELSE
    SELECT * INTO v_order
    FROM public.orders
    WHERE branch_id = p_branch_id
      AND table_id = p_table_id
      AND status IN ('Pending','Preparing','Served')
    ORDER BY created_at DESC
    LIMIT 1;
  END IF;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SERVING_ORDER_FOR_TABLE' USING ERRCODE = 'P0002';
  END IF;

  IF v_order.status NOT IN ('Pending','Preparing','Served') THEN
    IF NOT p_allow_closed_order THEN
      RAISE EXCEPTION 'ORDER_NOT_ACTIVE' USING ERRCODE = '22023';
    END IF;
    v_is_late := true;
  END IF;

  IF p_table_assignment_id IS NOT NULL THEN
    SELECT * INTO v_assignment
    FROM public.table_assignments
    WHERE id = p_table_assignment_id
      AND branch_id = p_branch_id
      AND table_id = COALESCE(p_table_id, v_order.table_id);
  ELSE
    SELECT * INTO v_assignment
    FROM public.table_assignments
    WHERE branch_id = p_branch_id
      AND table_id = v_order.table_id
      AND released_at IS NULL
    ORDER BY assigned_at DESC
    LIMIT 1;
  END IF;

  RETURN jsonb_build_object(
    'order_id', v_order.id,
    'table_id', v_order.table_id,
    'reservation_id', v_order.reservation_id,
    'table_assignment_id', CASE WHEN FOUND THEN v_assignment.id ELSE NULL END,
    'is_late', v_is_late
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.crm_resolve_serving_context(uuid,uuid,uuid,uuid,boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_resolve_serving_context(uuid,uuid,uuid,uuid,boolean) TO authenticated;

-- -----------------------------------------------------------------------------
-- UC 6.2/6.3: create or update survey for the current dining order/session.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crm_submit_table_survey(
  p_branch_id uuid,
  p_table_id uuid,
  p_order_id uuid DEFAULT NULL,
  p_table_assignment_id uuid DEFAULT NULL,
  p_source_code text DEFAULT NULL,
  p_visit_reason text DEFAULT NULL,
  p_feedback text DEFAULT NULL,
  p_improvement_note text DEFAULT NULL,
  p_customer_name text DEFAULT NULL,
  p_customer_phone text DEFAULT NULL,
  p_zalo text DEFAULT NULL,
  p_marketing_consent boolean DEFAULT false,
  p_tags text[] DEFAULT ARRAY[]::text[],
  p_note text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_ctx jsonb;
  v_order_id uuid;
  v_table_id uuid;
  v_assignment_id uuid;
  v_reservation_id uuid;
  v_is_late boolean;
  v_norm_phone text;
  v_customer_id uuid;
  v_survey_id uuid;
  v_status text;
  v_customer_name text := NULLIF(btrim(COALESCE(p_customer_name, '')), '');
  v_customer_phone text := NULLIF(btrim(COALESCE(p_customer_phone, '')), '');
BEGIN
  PERFORM public.crm_assert_branch_access(p_branch_id);

  v_ctx := public.crm_resolve_serving_context(
    p_branch_id,
    p_table_id,
    p_order_id,
    p_table_assignment_id,
    true
  );
  v_order_id := (v_ctx->>'order_id')::uuid;
  v_table_id := (v_ctx->>'table_id')::uuid;
  v_assignment_id := NULLIF(v_ctx->>'table_assignment_id', '')::uuid;
  v_reservation_id := NULLIF(v_ctx->>'reservation_id', '')::uuid;
  v_is_late := COALESCE((v_ctx->>'is_late')::boolean, false);
  v_status := CASE WHEN v_is_late THEN 'late_submitted' ELSE 'completed' END;

  v_norm_phone := public.crm_normalize_phone(v_customer_phone);

  IF v_norm_phone IS NOT NULL THEN
    SELECT id INTO v_customer_id
    FROM public.customers
    WHERE branch_id = p_branch_id
      AND normalized_phone = v_norm_phone
    ORDER BY updated_at DESC
    LIMIT 1
    FOR UPDATE;

    IF FOUND THEN
      UPDATE public.customers
      SET
        name = COALESCE(v_customer_name, name),
        phone = COALESCE(v_customer_phone, phone),
        normalized_phone = v_norm_phone,
        source_code = COALESCE(NULLIF(p_source_code, ''), source_code),
        visit_reason = COALESCE(NULLIF(p_visit_reason, ''), visit_reason),
        marketing_consent = COALESCE(p_marketing_consent, marketing_consent),
        marketing_tags = CASE
          WHEN cardinality(COALESCE(p_tags, ARRAY[]::text[])) > 0 THEN to_jsonb(p_tags)
          ELSE marketing_tags
        END,
        zalo = COALESCE(NULLIF(p_zalo, ''), zalo),
        first_visit_at = COALESCE(first_visit_at, now()),
        last_visit_at = now(),
        updated_at = now()
      WHERE id = v_customer_id;
    ELSE
      INSERT INTO public.customers (
        branch_id,
        name,
        phone,
        normalized_phone,
        source_code,
        visit_reason,
        marketing_consent,
        marketing_tags,
        zalo,
        first_visit_at,
        last_visit_at,
        tags
      ) VALUES (
        p_branch_id,
        COALESCE(v_customer_name, v_customer_phone, 'Guest'),
        v_customer_phone,
        v_norm_phone,
        NULLIF(p_source_code, ''),
        NULLIF(p_visit_reason, ''),
        COALESCE(p_marketing_consent, false),
        to_jsonb(COALESCE(p_tags, ARRAY[]::text[])),
        NULLIF(p_zalo, ''),
        now(),
        now(),
        to_jsonb(COALESCE(p_tags, ARRAY[]::text[]))
      )
      RETURNING id INTO v_customer_id;
    END IF;
  END IF;

  SELECT id INTO v_survey_id
  FROM public.crm_surveys
  WHERE branch_id = p_branch_id
    AND (
      order_id = v_order_id
      OR (v_assignment_id IS NOT NULL AND table_assignment_id = v_assignment_id)
    )
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF FOUND THEN
    UPDATE public.crm_surveys
    SET
      table_id = v_table_id,
      order_id = v_order_id,
      table_assignment_id = v_assignment_id,
      reservation_id = v_reservation_id,
      customer_id = COALESCE(v_customer_id, customer_id),
      source_code = NULLIF(p_source_code, ''),
      visit_reason = NULLIF(p_visit_reason, ''),
      feedback = NULLIF(p_feedback, ''),
      improvement_note = NULLIF(p_improvement_note, ''),
      customer_name = v_customer_name,
      customer_phone = v_customer_phone,
      normalized_phone = v_norm_phone,
      zalo = NULLIF(p_zalo, ''),
      marketing_consent = COALESCE(p_marketing_consent, false),
      tags = COALESCE(p_tags, ARRAY[]::text[]),
      note = NULLIF(p_note, ''),
      survey_status = v_status,
      asked_by = COALESCE(asked_by, public.current_user_id()),
      asked_at = COALESCE(asked_at, now()),
      submitted_at = now(),
      closed_at = CASE WHEN v_status IN ('completed','late_submitted') THEN now() ELSE closed_at END,
      updated_at = now()
    WHERE id = v_survey_id;
  ELSE
    INSERT INTO public.crm_surveys (
      branch_id,
      table_id,
      order_id,
      table_assignment_id,
      reservation_id,
      customer_id,
      source_code,
      visit_reason,
      feedback,
      improvement_note,
      customer_name,
      customer_phone,
      normalized_phone,
      zalo,
      marketing_consent,
      tags,
      note,
      survey_status,
      asked_by,
      asked_at,
      submitted_at,
      closed_at
    ) VALUES (
      p_branch_id,
      v_table_id,
      v_order_id,
      v_assignment_id,
      v_reservation_id,
      v_customer_id,
      NULLIF(p_source_code, ''),
      NULLIF(p_visit_reason, ''),
      NULLIF(p_feedback, ''),
      NULLIF(p_improvement_note, ''),
      v_customer_name,
      v_customer_phone,
      v_norm_phone,
      NULLIF(p_zalo, ''),
      COALESCE(p_marketing_consent, false),
      COALESCE(p_tags, ARRAY[]::text[]),
      NULLIF(p_note, ''),
      v_status,
      public.current_user_id(),
      now(),
      now(),
      now()
    )
    RETURNING id INTO v_survey_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'survey_id', v_survey_id,
    'survey_status', v_status,
    'order_id', v_order_id,
    'table_assignment_id', v_assignment_id,
    'customer_id', v_customer_id
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.crm_submit_table_survey(uuid,uuid,uuid,uuid,text,text,text,text,text,text,text,boolean,text[],text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_submit_table_survey(uuid,uuid,uuid,uuid,text,text,text,text,text,text,text,boolean,text[],text) TO authenticated;

-- -----------------------------------------------------------------------------
-- Status actions used by the CRM dashboard.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crm_set_table_survey_status(
  p_branch_id uuid,
  p_table_id uuid,
  p_order_id uuid DEFAULT NULL,
  p_table_assignment_id uuid DEFAULT NULL,
  p_status text DEFAULT 'in_progress',
  p_note text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_ctx jsonb;
  v_order_id uuid;
  v_table_id uuid;
  v_assignment_id uuid;
  v_reservation_id uuid;
  v_survey_id uuid;
  v_status text := p_status;
BEGIN
  PERFORM public.crm_assert_branch_access(p_branch_id);

  IF v_status NOT IN ('assigned','in_progress','skipped','customer_refused') THEN
    RAISE EXCEPTION 'INVALID_CRM_STATUS: %', v_status USING ERRCODE = '22023';
  END IF;

  v_ctx := public.crm_resolve_serving_context(
    p_branch_id,
    p_table_id,
    p_order_id,
    p_table_assignment_id,
    false
  );
  v_order_id := (v_ctx->>'order_id')::uuid;
  v_table_id := (v_ctx->>'table_id')::uuid;
  v_assignment_id := NULLIF(v_ctx->>'table_assignment_id', '')::uuid;
  v_reservation_id := NULLIF(v_ctx->>'reservation_id', '')::uuid;

  SELECT id INTO v_survey_id
  FROM public.crm_surveys
  WHERE branch_id = p_branch_id
    AND (
      order_id = v_order_id
      OR (v_assignment_id IS NOT NULL AND table_assignment_id = v_assignment_id)
    )
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF FOUND THEN
    UPDATE public.crm_surveys
    SET
      survey_status = v_status,
      note = COALESCE(NULLIF(p_note, ''), note),
      asked_by = COALESCE(asked_by, public.current_user_id()),
      asked_at = COALESCE(asked_at, now()),
      closed_at = CASE WHEN v_status IN ('skipped','customer_refused') THEN now() ELSE closed_at END,
      updated_at = now()
    WHERE id = v_survey_id;
  ELSE
    INSERT INTO public.crm_surveys (
      branch_id,
      table_id,
      order_id,
      table_assignment_id,
      reservation_id,
      survey_status,
      note,
      asked_by,
      asked_at,
      closed_at
    ) VALUES (
      p_branch_id,
      v_table_id,
      v_order_id,
      v_assignment_id,
      v_reservation_id,
      v_status,
      NULLIF(p_note, ''),
      public.current_user_id(),
      now(),
      CASE WHEN v_status IN ('skipped','customer_refused') THEN now() ELSE NULL END
    )
    RETURNING id INTO v_survey_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'survey_id', v_survey_id,
    'survey_status', v_status,
    'order_id', v_order_id,
    'table_assignment_id', v_assignment_id
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.crm_set_table_survey_status(uuid,uuid,uuid,uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_set_table_survey_status(uuid,uuid,uuid,uuid,text,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.crm_mark_survey_in_progress(
  p_branch_id uuid,
  p_table_id uuid,
  p_order_id uuid DEFAULT NULL,
  p_table_assignment_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.crm_set_table_survey_status(
    p_branch_id,
    p_table_id,
    p_order_id,
    p_table_assignment_id,
    'in_progress',
    NULL
  );
$$;

CREATE OR REPLACE FUNCTION public.crm_skip_table_survey(
  p_branch_id uuid,
  p_table_id uuid,
  p_order_id uuid DEFAULT NULL,
  p_table_assignment_id uuid DEFAULT NULL,
  p_note text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.crm_set_table_survey_status(
    p_branch_id,
    p_table_id,
    p_order_id,
    p_table_assignment_id,
    'skipped',
    p_note
  );
$$;

CREATE OR REPLACE FUNCTION public.crm_refuse_table_survey(
  p_branch_id uuid,
  p_table_id uuid,
  p_order_id uuid DEFAULT NULL,
  p_table_assignment_id uuid DEFAULT NULL,
  p_note text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT public.crm_set_table_survey_status(
    p_branch_id,
    p_table_id,
    p_order_id,
    p_table_assignment_id,
    'customer_refused',
    p_note
  );
$$;

REVOKE EXECUTE ON FUNCTION public.crm_mark_survey_in_progress(uuid,uuid,uuid,uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.crm_skip_table_survey(uuid,uuid,uuid,uuid,text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.crm_refuse_table_survey(uuid,uuid,uuid,uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_mark_survey_in_progress(uuid,uuid,uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.crm_skip_table_survey(uuid,uuid,uuid,uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.crm_refuse_table_survey(uuid,uuid,uuid,uuid,text) TO authenticated;

-- -----------------------------------------------------------------------------
-- UC 6.4: link surveys to the bill created by checkout. No survey is required.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.crm_link_surveys_to_bill(
  p_order_id uuid,
  p_bill_id uuid
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_bill public.bills%ROWTYPE;
  v_count int := 0;
BEGIN
  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ORDER_NOT_FOUND' USING ERRCODE = 'P0002';
  END IF;

  SELECT * INTO v_bill
  FROM public.bills
  WHERE id = p_bill_id
    AND order_id = p_order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BILL_NOT_FOUND_FOR_ORDER' USING ERRCODE = 'P0002';
  END IF;

  IF v_bill.branch_id IS DISTINCT FROM v_order.branch_id THEN
    RAISE EXCEPTION 'BILL_ORDER_BRANCH_MISMATCH' USING ERRCODE = '22023';
  END IF;

  PERFORM public.crm_assert_branch_access(v_bill.branch_id);

  UPDATE public.crm_surveys s
  SET
    bill_id = p_bill_id,
    survey_status = CASE
      WHEN s.survey_status IN ('assigned','in_progress') THEN 'expired'
      ELSE s.survey_status
    END,
    closed_at = COALESCE(s.closed_at, now()),
    updated_at = now()
  WHERE s.branch_id = v_bill.branch_id
    AND s.order_id = p_order_id
    AND (s.bill_id IS NULL OR s.bill_id = p_bill_id);

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.crm_link_surveys_to_bill(uuid,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.crm_link_surveys_to_bill(uuid,uuid) TO authenticated, service_role;

-- -----------------------------------------------------------------------------
-- Patch checkout to link existing CRM survey to the newly created bill. Checkout
-- does not require a survey and does not collect CRM data.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.process_checkout(uuid,uuid,uuid,public.payment_method,text,int);
DROP FUNCTION IF EXISTS public.process_checkout(uuid,uuid,uuid,text,text,int);

CREATE OR REPLACE FUNCTION public.process_checkout(
  p_order_id       uuid,
  p_branch_id      uuid,
  p_cashier_id     uuid,
  p_payment_method text,
  p_voucher_code   text DEFAULT NULL,
  p_points_to_use  int DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_order record;
  v_bill_id uuid;
  v_invoice_id uuid;
  v_bill_code text;
  v_invoice_number text;
  v_subtotal numeric(14,2);
  v_voucher_discount numeric(14,2) := 0;
  v_points_discount numeric(14,2) := 0;
  v_total_discount numeric(14,2);
  v_vat_rate numeric(5,4);
  v_vat_amount numeric(14,2);
  v_grand_total numeric(14,2);
  v_payment_method public.payment_method;
  v_linked_surveys int := 0;
BEGIN
  PERFORM public.crm_assert_branch_access(p_branch_id);

  v_payment_method := CASE upper(COALESCE(p_payment_method, 'other'))
    WHEN 'CASH' THEN 'cash'::public.payment_method
    WHEN 'CARD' THEN 'card'::public.payment_method
    WHEN 'TRANSFER' THEN 'transfer'::public.payment_method
    WHEN 'VOUCHER' THEN 'voucher'::public.payment_method
    WHEN 'MOMO' THEN 'transfer'::public.payment_method
    WHEN 'ZALOPAY' THEN 'transfer'::public.payment_method
    WHEN 'VNPAY' THEN 'transfer'::public.payment_method
    ELSE 'other'::public.payment_method
  END;

  SELECT o.*, b.vat_rate INTO v_order
  FROM public.orders o
  JOIN public.branches b ON b.id = o.branch_id
  WHERE o.id = p_order_id
    AND o.branch_id = p_branch_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found for this branch';
  END IF;

  IF v_order.status IN ('Paid','Cancelled') THEN
    RAISE EXCEPTION 'Order is already % - cannot checkout again', v_order.status;
  END IF;

  v_subtotal := COALESCE(v_order.subtotal, 0);
  v_vat_rate := COALESCE(v_order.vat_rate, 0.08);

  IF p_points_to_use > 0 THEN
    v_points_discount := p_points_to_use * 1000;
  END IF;

  v_total_discount := v_voucher_discount + v_points_discount;
  v_grand_total := GREATEST(0, (v_subtotal - v_total_discount) * (1 + v_vat_rate));
  v_vat_amount := v_grand_total - GREATEST(0, v_subtotal - v_total_discount);

  v_bill_code := 'BILL-' || to_char(now(), 'YYMMDD-HH24MISS') || '-'
              || substring(gen_random_uuid()::text, 1, 4);

  INSERT INTO public.bills (
    branch_id,
    bill_code,
    order_id,
    table_id,
    cashier_id,
    sub_total,
    discount_total,
    vat_8_amount,
    grand_total,
    payment_method,
    status
  ) VALUES (
    p_branch_id,
    v_bill_code,
    p_order_id,
    v_order.table_id,
    p_cashier_id,
    v_subtotal,
    v_total_discount,
    v_vat_amount,
    v_grand_total,
    v_payment_method::text,
    'PAID'
  )
  RETURNING id INTO v_bill_id;

  INSERT INTO public.bill_items (
    bill_id,
    menu_item_id,
    name_snapshot,
    quantity,
    unit_price,
    unit_cost,
    line_total
  )
  SELECT
    v_bill_id,
    oi.menu_item_id,
    oi.name_snapshot,
    oi.quantity,
    oi.unit_price,
    oi.unit_cost,
    oi.line_total
  FROM public.order_items oi
  WHERE oi.order_id = p_order_id
    AND oi.status != 'Cancelled';

  v_invoice_number := 'INV-' || to_char(now(), 'YYYYMMDD') || '-'
                   || substring(gen_random_uuid()::text, 1, 4);

  INSERT INTO public.invoices (
    branch_id,
    bill_id,
    invoice_symbol,
    invoice_number,
    issue_date,
    total_goods_amount,
    total_tax_amount,
    grand_total,
    status,
    created_by
  ) VALUES (
    p_branch_id,
    v_bill_id,
    'AA/24E',
    v_invoice_number,
    CURRENT_DATE,
    v_subtotal - v_total_discount,
    v_vat_amount,
    v_grand_total,
    'VALID',
    p_cashier_id
  )
  RETURNING id INTO v_invoice_id;

  INSERT INTO public.payments (
    branch_id,
    invoice_id,
    method,
    revenue_type,
    amount,
    received_amount,
    change_amount,
    received_by
  ) VALUES (
    p_branch_id,
    v_invoice_id,
    v_payment_method,
    'other',
    v_grand_total,
    v_grand_total,
    0,
    p_cashier_id
  );

  v_linked_surveys := public.crm_link_surveys_to_bill(p_order_id, v_bill_id);

  UPDATE public.orders
  SET
    status = 'Paid',
    vat = v_vat_amount,
    discount = v_total_discount,
    total = v_grand_total
  WHERE id = p_order_id;

  IF v_order.table_id IS NOT NULL THEN
    UPDATE public.tables
    SET status = 'available'
    WHERE id = v_order.table_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'bill_id', v_bill_id,
    'invoice_id', v_invoice_id,
    'invoice_number', v_invoice_number,
    'grand_total', v_grand_total,
    'linked_crm_surveys', v_linked_surveys
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.process_checkout(uuid,uuid,uuid,text,text,int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_checkout(uuid,uuid,uuid,text,text,int) TO authenticated;
