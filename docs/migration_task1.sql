ALTER TABLE public.branches
  ADD COLUMN IF NOT EXISTS manager_id        uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS address           text,
  ADD COLUMN IF NOT EXISTS phone             text,
  ADD COLUMN IF NOT EXISTS capacity          int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_active         boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS operating_hours   jsonb DEFAULT '{}',
  -- {"mon":{"open":"10:00","close":"22:00"}, ...}
  ADD COLUMN IF NOT EXISTS updated_at        timestamptz DEFAULT now();

-- Trigger to auto-update updated_at
CREATE OR REPLACE TRIGGER trg_branches_updated_at
  BEFORE UPDATE ON public.branches
  FOR EACH ROW EXECUTE FUNCTION moddatetime('updated_at');

CREATE TABLE public.suppliers (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id    uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  name         text NOT NULL,
  contact_name text,
  phone        text,
  email        text,
  address      text,
  is_active    boolean DEFAULT true,
  created_at   timestamptz DEFAULT now()
);

CREATE INDEX idx_suppliers_branch ON public.suppliers(branch_id);

CREATE TABLE public.ingredient_categories (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  name_vi   text NOT NULL,
  name_en   text,
  name_ja   text,
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE public.ingredients (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id            uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  category_id          uuid REFERENCES public.ingredient_categories(id),
  supplier_id          uuid REFERENCES public.suppliers(id),
  sku                  text NOT NULL,
  name_vi              text NOT NULL,
  name_en              text,
  name_ja              text,
  unit                 text NOT NULL, -- 'kg','g','L','ml','pcs','portion'
  unit_cost            numeric(12,2) DEFAULT 0,
  low_stock_threshold  numeric(12,3) DEFAULT 0,
  expiry_tracking      boolean DEFAULT false,
  is_active            boolean DEFAULT true,
  created_at           timestamptz DEFAULT now(),
  updated_at           timestamptz DEFAULT now(),
  UNIQUE (branch_id, sku)
);

CREATE INDEX idx_ingredients_branch ON public.ingredients(branch_id);
CREATE INDEX idx_ingredients_category ON public.ingredients(category_id);

-- Current stock per ingredient per branch — updated by trigger, never edited directly
CREATE TABLE public.inventory_stock (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       uuid NOT NULL REFERENCES public.branches(id),
  ingredient_id   uuid NOT NULL REFERENCES public.ingredients(id),
  quantity        numeric(12,3) DEFAULT 0,
  last_updated_at timestamptz DEFAULT now(),
  UNIQUE (branch_id, ingredient_id)
);

CREATE TABLE public.inventory_transactions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id        uuid NOT NULL REFERENCES public.branches(id),
  ingredient_id    uuid NOT NULL REFERENCES public.ingredients(id),
  transaction_type text NOT NULL CHECK (
    transaction_type IN ('IN', 'OUT', 'ADJUST', 'WASTE', 'TRANSFER_IN', 'TRANSFER_OUT')
  ),
  -- quantity is SIGNED: positive = stock gain, negative = stock reduction
  quantity         numeric(12,3) NOT NULL,
  unit_cost        numeric(12,2),
  expiry_date      date,
  reference_type   text CHECK (reference_type IN ('REQUISITION','HANDOVER','MANUAL','ADJUSTMENT','ORDER')),
  reference_id     uuid,
  note             text,
  created_by       uuid REFERENCES auth.users(id),
  created_at       timestamptz DEFAULT now()
);

CREATE INDEX idx_inv_tx_branch_ingredient ON public.inventory_transactions(branch_id, ingredient_id);
CREATE INDEX idx_inv_tx_created_at ON public.inventory_transactions(created_at DESC);

CREATE OR REPLACE FUNCTION fn_sync_inventory_stock()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.inventory_stock (branch_id, ingredient_id, quantity, last_updated_at)
  VALUES (NEW.branch_id, NEW.ingredient_id, NEW.quantity, now())
  ON CONFLICT (branch_id, ingredient_id)
  DO UPDATE SET
    quantity        = inventory_stock.quantity + NEW.quantity,
    last_updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_inventory_stock
  AFTER INSERT ON public.inventory_transactions
  FOR EACH ROW EXECUTE FUNCTION fn_sync_inventory_stock();

CREATE TABLE public.inventory_batches (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id          uuid NOT NULL REFERENCES public.branches(id),
  ingredient_id      uuid NOT NULL REFERENCES public.ingredients(id),
  transaction_id     uuid REFERENCES public.inventory_transactions(id),
  quantity_remaining numeric(12,3) NOT NULL,
  expiry_date        date,
  received_at        timestamptz DEFAULT now()
);

CREATE INDEX idx_batches_ingredient ON public.inventory_batches(ingredient_id, expiry_date);

-- Sequence for collision-safe numbering
CREATE SEQUENCE IF NOT EXISTS req_seq_global START 1 INCREMENT 1 NO CYCLE;

CREATE TABLE public.requisitions (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id          uuid NOT NULL REFERENCES public.branches(id),
  requisition_number text NOT NULL,   -- Generated by fn: REQ-YYYY-NNNN
  type               text NOT NULL CHECK (type IN ('OUTBOUND','INBOUND','RETURN')),
  status             text NOT NULL DEFAULT 'PENDING' CHECK (
    status IN ('PENDING','APPROVED','REJECTED','PROCESSING','COMPLETED','CANCELLED')
  ),
  requested_by       uuid NOT NULL REFERENCES auth.users(id),
  approved_by        uuid REFERENCES auth.users(id),
  approved_at        timestamptz,
  rejection_reason   text,
  needed_by_date     date,
  note               text,
  created_at         timestamptz DEFAULT now(),
  updated_at         timestamptz DEFAULT now()
);

CREATE INDEX idx_req_branch_status ON public.requisitions(branch_id, status);
CREATE INDEX idx_req_created_at ON public.requisitions(created_at DESC);

CREATE TABLE public.requisition_items (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requisition_id      uuid NOT NULL REFERENCES public.requisitions(id) ON DELETE CASCADE,
  ingredient_id       uuid NOT NULL REFERENCES public.ingredients(id),
  requested_quantity  numeric(12,3) NOT NULL,
  approved_quantity   numeric(12,3),   -- set when approved
  actual_quantity     numeric(12,3),   -- set when delivery confirmed
  unit                text NOT NULL,
  note                text
);

CREATE INDEX idx_req_items_req ON public.requisition_items(requisition_id);

-- Immutable approval audit trail
CREATE TABLE public.requisition_approvals (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requisition_id uuid NOT NULL REFERENCES public.requisitions(id),
  action         text NOT NULL CHECK (action IN ('SUBMIT','APPROVE','REJECT','CANCEL','COMPLETE')),
  performed_by   uuid NOT NULL REFERENCES auth.users(id),
  note           text,
  created_at     timestamptz DEFAULT now()
);

CREATE TABLE public.kitchen_shifts (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id    uuid NOT NULL REFERENCES public.branches(id),
  shift_type   text CHECK (shift_type IN ('MORNING','AFTERNOON','EVENING','NIGHT')),
  started_at   timestamptz,
  ended_at     timestamptz,
  started_by   uuid REFERENCES auth.users(id),
  ended_by     uuid REFERENCES auth.users(id),
  status       text DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','HANDOVER','CLOSED')),
  handover_note text,
  created_at   timestamptz DEFAULT now()
);

-- Only ONE active shift per branch at a time (prevents duplicate start)
CREATE UNIQUE INDEX idx_one_active_shift_per_branch
  ON public.kitchen_shifts(branch_id)
  WHERE status = 'ACTIVE';

CREATE TABLE public.shift_inventory_counts (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shift_id          uuid NOT NULL REFERENCES public.kitchen_shifts(id),
  ingredient_id     uuid NOT NULL REFERENCES public.ingredients(id),
  system_quantity   numeric(12,3),   -- snapshot from inventory_stock at time of count
  counted_quantity  numeric(12,3) NOT NULL,
  discrepancy       numeric(12,3) GENERATED ALWAYS AS (counted_quantity - COALESCE(system_quantity,0)) STORED,
  note              text,
  counted_by        uuid REFERENCES auth.users(id),
  counted_at        timestamptz DEFAULT now()
);

CREATE TABLE public.tablet_sessions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       uuid NOT NULL REFERENCES public.branches(id),
  table_id        uuid NOT NULL REFERENCES public.tables(id),
  status          text DEFAULT 'IDLE' CHECK (status IN ('IDLE','ACTIVE','ORDERING','AWAITING_PAYMENT')),
  language        text DEFAULT 'vi' CHECK (language IN ('vi','en','ja')),
  order_id        uuid REFERENCES public.orders(id),
  started_at      timestamptz,
  last_activity_at timestamptz DEFAULT now(),
  UNIQUE (table_id)   -- one session per physical table
);

-- Content managed by admin for the idle carousel
CREATE TABLE public.tablet_content (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id    uuid NOT NULL REFERENCES public.branches(id),
  content_type text CHECK (content_type IN ('ADVERTISEMENT','MENU_HIGHLIGHT','PROMOTION')),
  title_vi     text,
  title_en     text,
  title_ja     text,
  body_vi      text,
  body_en      text,
  body_ja      text,
  image_url    text,
  display_order int DEFAULT 0,
  is_active    boolean DEFAULT true,
  valid_from   timestamptz,
  valid_until  timestamptz,
  created_at   timestamptz DEFAULT now()
);

CREATE INDEX idx_tablet_content_branch_active ON public.tablet_content(branch_id, is_active, display_order);

CREATE TABLE public.payment_integrations (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     uuid NOT NULL REFERENCES public.branches(id),
  provider      text NOT NULL CHECK (provider IN ('ZALOPAY','MOMO','VNPAY','CARD','CASH')),
  is_enabled    boolean DEFAULT false,
  config        jsonb DEFAULT '{}',  
  -- IMPORTANT: sensitive keys (api_key, secret_key) must be encrypted before storage.
  -- Use pgcrypto extension: pgp_sym_encrypt(value, app_secret).
  webhook_url   text,
  last_tested_at timestamptz,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now(),
  UNIQUE (branch_id, provider)
);

CREATE TABLE public.delivery_integrations (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id      uuid NOT NULL REFERENCES public.branches(id),
  provider       text NOT NULL CHECK (provider IN ('GRAB','SHOPEEFOOD','BAEMIN','MANUAL')),
  is_enabled     boolean DEFAULT false,
  config         jsonb DEFAULT '{}',
  webhook_url    text,
  store_id       text,
  last_synced_at timestamptz,
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now(),
  UNIQUE (branch_id, provider)
);

-- Example for requisitions: kitchen/manager can only see their own branch
ALTER TABLE public.requisitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "branch_isolation_requisitions"
  ON public.requisitions
  FOR ALL
  USING (
    branch_id = (
      SELECT (auth.jwt() -> 'app_metadata' ->> 'branch_id')::uuid
    )
    OR
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin', 'superadmin')
  );
-- Apply the same pattern to: ingredients, inventory_stock, inventory_transactions,
-- kitchen_shifts, tablet_sessions, suppliers, etc.

CREATE OR REPLACE FUNCTION public.get_inventory_with_alerts(p_branch_id uuid)
RETURNS TABLE (
  ingredient_id      uuid,
  sku                text,
  name_vi            text,
  name_en            text,
  name_ja            text,
  unit               text,
  unit_cost          numeric,
  category_id        uuid,
  category_name_vi   text,
  quantity           numeric,
  low_stock_threshold numeric,
  is_low_stock       boolean,
  next_expiry_date   date
) LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    i.id,
    i.sku,
    i.name_vi,
    i.name_en,
    i.name_ja,
    i.unit,
    i.unit_cost,
    i.category_id,
    ic.name_vi                      AS category_name_vi,
    COALESCE(s.quantity, 0)         AS quantity,
    i.low_stock_threshold,
    COALESCE(s.quantity, 0) < i.low_stock_threshold AS is_low_stock,
    (
      SELECT MIN(expiry_date)
      FROM public.inventory_batches b
      WHERE b.ingredient_id = i.id
        AND b.branch_id = p_branch_id
        AND b.quantity_remaining > 0
        AND b.expiry_date IS NOT NULL
    )                               AS next_expiry_date
  FROM public.ingredients i
  LEFT JOIN public.inventory_stock s
         ON s.ingredient_id = i.id AND s.branch_id = p_branch_id
  LEFT JOIN public.ingredient_categories ic ON ic.id = i.category_id
  WHERE i.branch_id = p_branch_id
    AND i.is_active = true
  ORDER BY is_low_stock DESC, i.name_vi ASC;
$$;

CREATE OR REPLACE FUNCTION public.create_inventory_transaction(
  p_branch_id       uuid,
  p_ingredient_id   uuid,
  p_type            text,
  p_quantity        numeric,       -- always positive; sign determined by type
  p_reference_type  text  DEFAULT NULL,
  p_reference_id    uuid  DEFAULT NULL,
  p_expiry_date     date  DEFAULT NULL,
  p_unit_cost       numeric DEFAULT NULL,
  p_note            text  DEFAULT NULL,
  p_created_by      uuid  DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_signed_qty  numeric;
  v_current_qty numeric;
  v_tx_id       uuid;
BEGIN
  -- Determine signed quantity
  IF p_type IN ('OUT', 'WASTE', 'TRANSFER_OUT') THEN
    v_signed_qty := -ABS(p_quantity);
  ELSE
    v_signed_qty := ABS(p_quantity);
  END IF;

  -- LOCK the stock row to prevent concurrent depletion (SELECT FOR UPDATE)
  SELECT COALESCE(quantity, 0)
    INTO v_current_qty
    FROM public.inventory_stock
   WHERE branch_id = p_branch_id AND ingredient_id = p_ingredient_id
     FOR UPDATE;

  -- Validate stock for outbound movements
  IF v_signed_qty < 0 AND (v_current_qty + v_signed_qty) < 0 THEN
    RAISE EXCEPTION 'INSUFFICIENT_STOCK: ingredient=%, required=%, available=%',
      p_ingredient_id, ABS(v_signed_qty), v_current_qty
      USING ERRCODE = 'P0001';
  END IF;

  -- Insert transaction (trigger updates inventory_stock automatically)
  INSERT INTO public.inventory_transactions (
    branch_id, ingredient_id, transaction_type,
    quantity, unit_cost, expiry_date,
    reference_type, reference_id, note, created_by
  ) VALUES (
    p_branch_id, p_ingredient_id, p_type,
    v_signed_qty, p_unit_cost, p_expiry_date,
    p_reference_type, p_reference_id, p_note, p_created_by
  ) RETURNING id INTO v_tx_id;

  -- If this is an IN transaction with expiry tracking, also create a batch record
  IF p_type IN ('IN', 'TRANSFER_IN') AND p_expiry_date IS NOT NULL THEN
    INSERT INTO public.inventory_batches (
      branch_id, ingredient_id, transaction_id, quantity_remaining, expiry_date
    ) VALUES (p_branch_id, p_ingredient_id, v_tx_id, ABS(p_quantity), p_expiry_date);
  END IF;

  RETURN v_tx_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_requisition_with_items(
  p_branch_id       uuid,
  p_type            text,
  p_requested_by    uuid,
  p_items           jsonb,         -- [{ingredient_id, requested_quantity, unit, note}]
  p_needed_by_date  date   DEFAULT NULL,
  p_note            text   DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_req_id     uuid;
  v_req_number text;
  v_item       jsonb;
BEGIN
  -- Collision-safe sequential number using global sequence
  v_req_number := 'REQ-' || TO_CHAR(now(), 'YYYY') || '-'
                  || LPAD(nextval('req_seq_global')::text, 5, '0');

  INSERT INTO public.requisitions (
    branch_id, requisition_number, type, status,
    requested_by, needed_by_date, note
  ) VALUES (
    p_branch_id, v_req_number, p_type, 'PENDING',
    p_requested_by, p_needed_by_date, p_note
  ) RETURNING id INTO v_req_id;

  -- Bulk insert line items
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    INSERT INTO public.requisition_items (
      requisition_id, ingredient_id, requested_quantity, unit, note
    ) VALUES (
      v_req_id,
      (v_item->>'ingredient_id')::uuid,
      (v_item->>'requested_quantity')::numeric,
      v_item->>'unit',
      v_item->>'note'
    );
  END LOOP;

  -- Audit log
  INSERT INTO public.requisition_approvals (requisition_id, action, performed_by)
  VALUES (v_req_id, 'SUBMIT', p_requested_by);

  RETURN v_req_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.approve_reject_requisition(
  p_requisition_id   uuid,
  p_action           text,   -- 'APPROVE' | 'REJECT' | 'CANCEL'
  p_performed_by     uuid,
  p_note             text    DEFAULT NULL,
  p_approved_qtys    jsonb   DEFAULT NULL
  -- [{requisition_item_id: uuid, approved_quantity: numeric}]
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status  text;
  v_item    jsonb;
BEGIN
  -- Lock the row — prevents two managers approving simultaneously
  SELECT status INTO v_status
    FROM public.requisitions
   WHERE id = p_requisition_id
     FOR UPDATE;

  IF v_status IS NULL THEN
    RAISE EXCEPTION 'NOT_FOUND: Requisition %', p_requisition_id USING ERRCODE = 'P0002';
  END IF;

  IF v_status != 'PENDING' THEN
    RAISE EXCEPTION 'INVALID_STATUS: Cannot % a requisition with status %',
      p_action, v_status USING ERRCODE = 'P0003';
  END IF;

  IF p_action = 'APPROVE' THEN
    UPDATE public.requisitions SET
      status      = 'APPROVED',
      approved_by = p_performed_by,
      approved_at = now(),
      updated_at  = now()
    WHERE id = p_requisition_id;

    IF p_approved_qtys IS NOT NULL THEN
      FOR v_item IN SELECT * FROM jsonb_array_elements(p_approved_qtys) LOOP
        UPDATE public.requisition_items SET
          approved_quantity = (v_item->>'approved_quantity')::numeric
        WHERE id = (v_item->>'requisition_item_id')::uuid;
      END LOOP;
    ELSE
      -- Default: approved_quantity = requested_quantity
      UPDATE public.requisition_items SET
        approved_quantity = requested_quantity
      WHERE requisition_id = p_requisition_id;
    END IF;

  ELSIF p_action = 'REJECT' THEN
    UPDATE public.requisitions SET
      status           = 'REJECTED',
      rejection_reason = p_note,
      updated_at       = now()
    WHERE id = p_requisition_id;

  ELSIF p_action = 'CANCEL' THEN
    UPDATE public.requisitions SET
      status     = 'CANCELLED',
      updated_at = now()
    WHERE id = p_requisition_id;
  END IF;

  INSERT INTO public.requisition_approvals (requisition_id, action, performed_by, note)
  VALUES (p_requisition_id, p_action, p_performed_by, p_note);
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_requisition_delivery(
  p_requisition_id  uuid,
  p_completed_by    uuid,
  p_actual_qtys     jsonb   -- [{requisition_item_id, actual_quantity, expiry_date?}]
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status      text;
  v_branch_id   uuid;
  v_item        jsonb;
  v_ingr_id     uuid;
  v_qty         numeric;
  v_expiry      date;
BEGIN
  SELECT status, branch_id INTO v_status, v_branch_id
    FROM public.requisitions
   WHERE id = p_requisition_id FOR UPDATE;

  IF v_status NOT IN ('APPROVED') THEN
    RAISE EXCEPTION 'INVALID_STATUS: Expected APPROVED, got %', v_status USING ERRCODE = 'P0003';
  END IF;

  -- Update actual quantities and trigger inventory IN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_actual_qtys) LOOP
    v_qty    := (v_item->>'actual_quantity')::numeric;
    v_expiry := (v_item->>'expiry_date')::date;

    -- Get ingredient_id from requisition item
    SELECT ingredient_id INTO v_ingr_id
      FROM public.requisition_items
     WHERE id = (v_item->>'requisition_item_id')::uuid;

    UPDATE public.requisition_items SET
      actual_quantity = v_qty
    WHERE id = (v_item->>'requisition_item_id')::uuid;

    -- Create inventory IN transaction (trigger updates stock)
    PERFORM public.create_inventory_transaction(
      v_branch_id, v_ingr_id, 'IN', v_qty,
      'REQUISITION', p_requisition_id, v_expiry, NULL, NULL, p_completed_by
    );
  END LOOP;

  UPDATE public.requisitions SET status = 'COMPLETED', updated_at = now()
   WHERE id = p_requisition_id;

  INSERT INTO public.requisition_approvals (requisition_id, action, performed_by)
  VALUES (p_requisition_id, 'COMPLETE', p_completed_by);
END;
$$;

CREATE OR REPLACE FUNCTION public.start_kitchen_shift(
  p_branch_id   uuid,
  p_shift_type  text,
  p_started_by  uuid
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_shift_id uuid;
BEGIN
  -- The UNIQUE partial index on (branch_id) WHERE status='ACTIVE'
  -- will throw a unique violation if a shift is already active.
  -- We catch and re-raise with a readable message.
  BEGIN
    INSERT INTO public.kitchen_shifts (
      branch_id, shift_type, status, started_at, started_by
    ) VALUES (
      p_branch_id, p_shift_type, 'ACTIVE', now(), p_started_by
    ) RETURNING id INTO v_shift_id;
  EXCEPTION WHEN unique_violation THEN
    RAISE EXCEPTION 'SHIFT_ALREADY_ACTIVE: Branch % already has an active shift', p_branch_id
      USING ERRCODE = 'P0004';
  END;

  RETURN v_shift_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.close_shift_with_handover(
  p_shift_id        uuid,
  p_ended_by        uuid,
  p_handover_note   text  DEFAULT NULL,
  p_counts          jsonb DEFAULT '[]'
  -- [{ingredient_id, counted_quantity, note}]
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_item          jsonb;
  v_system_qty    numeric;
  v_branch_id     uuid;
BEGIN
  SELECT branch_id INTO v_branch_id
    FROM public.kitchen_shifts WHERE id = p_shift_id FOR UPDATE;

  -- Insert count records with system snapshot
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_counts) LOOP
    SELECT COALESCE(quantity, 0) INTO v_system_qty
      FROM public.inventory_stock
     WHERE branch_id = v_branch_id
       AND ingredient_id = (v_item->>'ingredient_id')::uuid;

    INSERT INTO public.shift_inventory_counts (
      shift_id, ingredient_id, system_quantity, counted_quantity, note, counted_by
    ) VALUES (
      p_shift_id,
      (v_item->>'ingredient_id')::uuid,
      v_system_qty,
      (v_item->>'counted_quantity')::numeric,
      v_item->>'note',
      p_ended_by
    );

    -- Create ADJUST transaction if discrepancy found
    IF (v_item->>'counted_quantity')::numeric != v_system_qty THEN
      PERFORM public.create_inventory_transaction(
        v_branch_id,
        (v_item->>'ingredient_id')::uuid,
        'ADJUST',
        ABS((v_item->>'counted_quantity')::numeric - v_system_qty),
        'HANDOVER', p_shift_id, NULL, NULL, NULL, p_ended_by
      );
      -- If counted < system, use OUT
      IF (v_item->>'counted_quantity')::numeric < v_system_qty THEN
        PERFORM public.create_inventory_transaction(
          v_branch_id, (v_item->>'ingredient_id')::uuid, 'WASTE',
          v_system_qty - (v_item->>'counted_quantity')::numeric,
          'HANDOVER', p_shift_id, NULL, NULL, 'Handover discrepancy', p_ended_by
        );
      END IF;
    END IF;
  END LOOP;

  -- Close shift
  UPDATE public.kitchen_shifts SET
    status        = 'CLOSED',
    ended_at      = now(),
    ended_by      = p_ended_by,
    handover_note = p_handover_note
  WHERE id = p_shift_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_kitchen_dashboard_stats(p_branch_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT jsonb_build_object(
    'low_stock_count',
      (SELECT COUNT(*) FROM public.get_inventory_with_alerts(p_branch_id) WHERE is_low_stock),
    'expiring_soon_count',
      (SELECT COUNT(*) FROM public.get_inventory_with_alerts(p_branch_id)
       WHERE next_expiry_date IS NOT NULL AND next_expiry_date <= CURRENT_DATE + 3),
    'pending_requisitions',
      (SELECT COUNT(*) FROM public.requisitions
       WHERE branch_id = p_branch_id AND status = 'PENDING'),
    'active_shift_id',
      (SELECT id FROM public.kitchen_shifts
       WHERE branch_id = p_branch_id AND status = 'ACTIVE' LIMIT 1)
  );
$$;

SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION'
  AND routine_name IN (
    'get_inventory_with_alerts', 'create_inventory_transaction',
    'create_requisition_with_items', 'approve_reject_requisition',
    'complete_requisition_delivery', 'start_kitchen_shift',
    'close_shift_with_handover', 'get_kitchen_dashboard_stats'
  );
-- Should return 8 rows