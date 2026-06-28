# IMPLEMENTATION PLAN — Module 2 & 3
## Voucher Management + Customer Membership / Loyalty System

> **Repo:** `TPH-Per/ProjectCongTyEEE` (Vue 3 + Pinia + Supabase)  
> **Style:** Upscale Japanese Yakiniku — dark, ember-gold, Noto Serif JP  
> **i18n:** 3-language Pinia store (vi / en / ja) — keys appended to `useLanguageStore.ts`  
> **Execution order:** Database migrations → RPC functions → Composables → Views → i18n keys

---

## TABLE OF CONTENTS

1. [Module A — Voucher Management](#module-a--voucher-management)
   - 1.1 Database Schema Patch
   - 1.2 RPC Functions (race-condition-safe)
   - 1.3 Composable `useVoucher.ts`
   - 1.4 Business Logic & Edge Cases
   - 1.5 UX/UI Design
2. [Module B — Membership / Loyalty System](#module-b--membership--loyalty-system)
   - 2.1 Database Schema (new tables + customer patch)
   - 2.2 RPC Functions
   - 2.3 Composable `useMembership.ts`
   - 2.4 Extend `useCustomer.ts`
   - 2.5 Business Logic & Edge Cases
   - 2.6 UX/UI Design
3. [i18n Keys — Additions to `useLanguageStore.ts`](#3-i18n-keys--additions-to-uselanguagestorets)
4. [Race Condition & Concurrency Summary](#4-race-condition--concurrency-summary)
5. [N+1 Prevention Summary](#5-n1-prevention-summary)
6. [Agent Task List (Ordered)](#6-agent-task-list-ordered)

---

## MODULE A — Voucher Management

### A.1 Database Schema Patch

> The existing `vouchers` table is solid. Apply minimal additive patches; do not drop existing columns.

```sql
-- PATCH 1: Add business rule columns that were missing
ALTER TABLE public.vouchers
  ADD COLUMN IF NOT EXISTS min_order_value    numeric(12,2) DEFAULT 0,
  -- minimum bill total required to apply this voucher
  ADD COLUMN IF NOT EXISTS max_discount_amount numeric(12,2) DEFAULT NULL,
  -- cap on discount for percent-type vouchers (e.g. 10% but no more than 50k)
  ADD COLUMN IF NOT EXISTS customer_id        uuid REFERENCES public.customers(id) DEFAULT NULL,
  -- NULL = public voucher; non-null = personalized (only that customer can use it)
  ADD COLUMN IF NOT EXISTS usage_limit_per_customer int DEFAULT 1,
  -- how many times one customer can use this voucher (default: once)
  ADD COLUMN IF NOT EXISTS description_vi     text,
  ADD COLUMN IF NOT EXISTS description_en     text,
  ADD COLUMN IF NOT EXISTS description_ja     text,
  ADD COLUMN IF NOT EXISTS is_deleted         boolean DEFAULT false;
  -- soft-delete: never hard-delete vouchers (audit trail)

-- Index for fast code lookup at checkout
CREATE UNIQUE INDEX IF NOT EXISTS idx_vouchers_code_branch
  ON public.vouchers(UPPER(code), branch_id)
  WHERE is_deleted = false;

-- For management list filtering
CREATE INDEX IF NOT EXISTS idx_vouchers_branch_active
  ON public.vouchers(branch_id, is_active, valid_until);
```

**New table: `voucher_usages`** — tracks exactly who used which voucher on which invoice (enables per-customer usage limit, analytics, and audit)

```sql
CREATE TABLE IF NOT EXISTS public.voucher_usages (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  voucher_id  uuid NOT NULL REFERENCES public.vouchers(id),
  invoice_id  uuid NOT NULL REFERENCES public.invoices(id),
  customer_id uuid REFERENCES public.customers(id),
  branch_id   uuid NOT NULL REFERENCES public.branches(id),
  discount_amount numeric(12,2) NOT NULL,
  used_at     timestamptz DEFAULT now()
);

CREATE INDEX idx_voucher_usages_voucher ON public.voucher_usages(voucher_id);
CREATE INDEX idx_voucher_usages_customer ON public.voucher_usages(customer_id);
CREATE INDEX idx_voucher_usages_invoice ON public.voucher_usages(invoice_id);
```

**RLS for vouchers:**
```sql
ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voucher_usages ENABLE ROW LEVEL SECURITY;

-- Managers and above can CRUD vouchers for their branch
CREATE POLICY "voucher_branch_isolation"
  ON public.vouchers FOR ALL
  USING (
    branch_id = (auth.jwt()->'app_metadata'->>'branch_id')::uuid
    OR (auth.jwt()->'app_metadata'->>'role') IN ('admin','superadmin')
  );
```

---

### A.2 RPC Functions (Race-Condition-Safe)

#### `validate_voucher` — Read-only validation, no side effects

```sql
CREATE OR REPLACE FUNCTION public.validate_voucher(
  p_code          text,
  p_branch_id     uuid,
  p_order_total   numeric,
  p_customer_id   uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  v_voucher   public.vouchers%ROWTYPE;
  v_used_by   int;
  v_discount  numeric(12,2);
BEGIN
  -- Case-insensitive code lookup
  SELECT * INTO v_voucher
    FROM public.vouchers
   WHERE UPPER(code) = UPPER(p_code)
     AND (branch_id = p_branch_id OR branch_id IS NULL)
     AND is_deleted = false
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_NOT_FOUND');
  END IF;

  IF NOT v_voucher.is_active THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_INACTIVE');
  END IF;

  IF v_voucher.valid_from IS NOT NULL AND now() < v_voucher.valid_from THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_NOT_YET_VALID');
  END IF;

  IF v_voucher.valid_until IS NOT NULL AND now() > v_voucher.valid_until THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_EXPIRED');
  END IF;

  IF v_voucher.max_uses IS NOT NULL AND v_voucher.used_count >= v_voucher.max_uses THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_EXHAUSTED');
  END IF;

  IF p_order_total < COALESCE(v_voucher.min_order_value, 0) THEN
    RETURN jsonb_build_object(
      'valid', false, 'error', 'ORDER_BELOW_MINIMUM',
      'min_order_value', v_voucher.min_order_value
    );
  END IF;

  -- Personalized voucher check
  IF v_voucher.customer_id IS NOT NULL AND v_voucher.customer_id != p_customer_id THEN
    RETURN jsonb_build_object('valid', false, 'error', 'VOUCHER_NOT_FOR_YOU');
  END IF;

  -- Per-customer usage limit check
  IF p_customer_id IS NOT NULL AND v_voucher.usage_limit_per_customer IS NOT NULL THEN
    SELECT COUNT(*) INTO v_used_by
      FROM public.voucher_usages
     WHERE voucher_id = v_voucher.id AND customer_id = p_customer_id;

    IF v_used_by >= v_voucher.usage_limit_per_customer THEN
      RETURN jsonb_build_object('valid', false, 'error', 'CUSTOMER_USAGE_LIMIT_REACHED');
    END IF;
  END IF;

  -- Calculate actual discount
  IF v_voucher.type = 'percent' THEN
    v_discount := ROUND(p_order_total * v_voucher.value / 100, 0);
    -- Apply cap if configured
    IF v_voucher.max_discount_amount IS NOT NULL THEN
      v_discount := LEAST(v_discount, v_voucher.max_discount_amount);
    END IF;
  ELSE
    v_discount := LEAST(v_voucher.value, p_order_total); -- cannot discount more than total
  END IF;

  RETURN jsonb_build_object(
    'valid',            true,
    'voucher_id',       v_voucher.id,
    'code',             v_voucher.code,
    'type',             v_voucher.type,
    'discount_amount',  v_discount,
    'description_vi',   v_voucher.description_vi,
    'description_en',   v_voucher.description_en,
    'description_ja',   v_voucher.description_ja
  );
END;
$$;
```

**Input:** `{ p_code, p_branch_id, p_order_total, p_customer_id? }`  
**Output:** `{ valid: boolean, error?: string, discount_amount?: number, voucher_id?: uuid, ... }`  
**No side effects** — safe to call on every keystroke in checkout UI

---

#### `redeem_voucher` — Atomic increment, race-condition-safe

```sql
CREATE OR REPLACE FUNCTION public.redeem_voucher(
  p_voucher_id    uuid,
  p_invoice_id    uuid,
  p_branch_id     uuid,
  p_order_total   numeric,
  p_customer_id   uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_voucher        public.vouchers%ROWTYPE;
  v_discount       numeric(12,2);
  v_rows_updated   int;
BEGIN
  -- Atomic increment with guard — prevents race condition (two cashiers redeeming same code)
  UPDATE public.vouchers SET
    used_count = used_count + 1,
    updated_at = now()
  WHERE id = p_voucher_id
    AND is_active = true
    AND is_deleted = false
    AND (max_uses IS NULL OR used_count < max_uses)
    AND (valid_until IS NULL OR valid_until > now())
  RETURNING * INTO v_voucher;

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

  IF v_rows_updated = 0 THEN
    -- Voucher was exhausted or deactivated between validate and redeem
    RAISE EXCEPTION 'VOUCHER_NO_LONGER_VALID: Voucher % could not be redeemed',
      p_voucher_id USING ERRCODE = 'P0010';
  END IF;

  -- Calculate discount (same logic as validate_voucher)
  IF v_voucher.type = 'percent' THEN
    v_discount := ROUND(p_order_total * v_voucher.value / 100, 0);
    IF v_voucher.max_discount_amount IS NOT NULL THEN
      v_discount := LEAST(v_discount, v_voucher.max_discount_amount);
    END IF;
  ELSE
    v_discount := LEAST(v_voucher.value, p_order_total);
  END IF;

  -- Record the usage for analytics & per-customer limit tracking
  INSERT INTO public.voucher_usages (
    voucher_id, invoice_id, customer_id, branch_id, discount_amount
  ) VALUES (
    p_voucher_id, p_invoice_id, p_customer_id, p_branch_id, v_discount
  );

  RETURN jsonb_build_object(
    'success',          true,
    'discount_amount',  v_discount,
    'code',             v_voucher.code,
    'new_used_count',   v_voucher.used_count
  );
END;
$$;
```

**Input:** `{ p_voucher_id, p_invoice_id, p_branch_id, p_order_total, p_customer_id? }`  
**Output:** `{ success: true, discount_amount: number }` or raises `P0010`  
**Race-condition safety:** Single atomic `UPDATE ... WHERE used_count < max_uses`. If two cashiers call simultaneously, only one gets `ROW_COUNT = 1`. The second gets `ROW_COUNT = 0` → raises exception.

---

#### `get_voucher_stats` — Dashboard stats, single query

```sql
CREATE OR REPLACE FUNCTION public.get_voucher_stats(p_branch_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT jsonb_build_object(
    'total_vouchers',
      (SELECT COUNT(*) FROM public.vouchers
       WHERE branch_id = p_branch_id AND is_deleted = false),
    'active_vouchers',
      (SELECT COUNT(*) FROM public.vouchers
       WHERE branch_id = p_branch_id AND is_active = true
         AND is_deleted = false
         AND (valid_until IS NULL OR valid_until > now())),
    'expired_vouchers',
      (SELECT COUNT(*) FROM public.vouchers
       WHERE branch_id = p_branch_id AND is_deleted = false
         AND valid_until < now()),
    'total_discount_given',
      (SELECT COALESCE(SUM(discount_amount), 0)
       FROM public.voucher_usages WHERE branch_id = p_branch_id),
    'total_redemptions',
      (SELECT COUNT(*) FROM public.voucher_usages WHERE branch_id = p_branch_id),
    'most_used_code',
      (SELECT code FROM public.vouchers v
       WHERE v.branch_id = p_branch_id
       ORDER BY v.used_count DESC LIMIT 1)
  );
$$;
```

---

### A.3 Composable `useVoucher.ts`

**File:** `src/composables/useVoucher.ts`

```typescript
// ---- types ----
interface Voucher {
  id: string;
  branch_id: string;
  code: string;
  type: 'percent' | 'amount';
  value: number;
  min_order_value: number;
  max_discount_amount: number | null;
  valid_from: string | null;
  valid_until: string | null;
  max_uses: number | null;
  used_count: number;
  usage_limit_per_customer: number;
  is_active: boolean;
  is_deleted: boolean;
  customer_id: string | null;
  description_vi: string | null;
  description_en: string | null;
  description_ja: string | null;
  created_by: string | null;
  metadata: Record<string, unknown>;
}

interface CreateVoucherInput {
  code: string;
  type: 'percent' | 'amount';
  value: number;
  min_order_value?: number;
  max_discount_amount?: number | null;
  valid_from?: string | null;
  valid_until?: string | null;
  max_uses?: number | null;
  usage_limit_per_customer?: number;
  description_vi?: string;
  description_en?: string;
  description_ja?: string;
  customer_id?: string | null;
}

// ---- composable ----
export function useVoucher() {
  const vouchers   = ref<Voucher[]>([]);
  const stats      = ref<VoucherStats | null>(null);
  const loading    = ref(false);
  const error      = ref<string | null>(null);
  const { activeBranchId } = useBranchStore();
  const { id: userId }     = useAuthStore();

  // LIST — with optional filters, no N+1 (flat select)
  async function listVouchers(filters?: {
    onlyActive?: boolean;
    onlyExpired?: boolean;
    type?: 'percent' | 'amount';
    search?: string;
  }) {
    loading.value = true;
    let query = supabase
      .from('vouchers')
      .select(`
        id, code, type, value, min_order_value, max_discount_amount,
        valid_from, valid_until, max_uses, used_count, is_active,
        usage_limit_per_customer, customer_id, description_vi,
        description_en, description_ja, created_by, metadata, created_at,
        customer:customer_id (id, name, phone)
      `)
      .eq('branch_id', activeBranchId!)
      .eq('is_deleted', false)
      .order('created_at', { ascending: false });

    if (filters?.onlyActive)  query = query.eq('is_active', true).gte('valid_until', new Date().toISOString());
    if (filters?.onlyExpired) query = query.lt('valid_until', new Date().toISOString());
    if (filters?.type)        query = query.eq('type', filters.type);
    if (filters?.search)      query = query.ilike('code', `%${filters.search}%`);

    const { data, error: err } = await query;
    if (err) { error.value = err.message; throw err; }
    vouchers.value = data ?? [];
    loading.value = false;
  }

  // CREATE
  async function createVoucher(input: CreateVoucherInput): Promise<Voucher> {
    // Validate code uniqueness before insert (client-side pre-check for UX)
    const { data: existing } = await supabase
      .from('vouchers')
      .select('id')
      .eq('branch_id', activeBranchId!)
      .ilike('code', input.code)
      .eq('is_deleted', false)
      .maybeSingle();
    if (existing) throw new Error('DUPLICATE_CODE');

    const { data, error: err } = await supabase
      .from('vouchers')
      .insert({
        branch_id: activeBranchId!,
        created_by: userId,
        used_count: 0,
        is_active: true,
        ...input,
        code: input.code.toUpperCase().trim()
      })
      .select()
      .single();
    if (err) throw err;
    vouchers.value.unshift(data);
    return data;
  }

  // UPDATE (partial patch)
  async function updateVoucher(id: string, patch: Partial<CreateVoucherInput>): Promise<Voucher> {
    const { data, error: err } = await supabase
      .from('vouchers')
      .update({ ...patch, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    if (err) throw err;
    const idx = vouchers.value.findIndex(v => v.id === id);
    if (idx >= 0) vouchers.value[idx] = data;
    return data;
  }

  // TOGGLE ACTIVE
  async function toggleVoucher(id: string, isActive: boolean): Promise<void> {
    await updateVoucher(id, { is_active: isActive });
  }

  // SOFT DELETE
  async function deleteVoucher(id: string): Promise<void> {
    const { error: err } = await supabase
      .from('vouchers')
      .update({ is_deleted: true, is_active: false })
      .eq('id', id);
    if (err) throw err;
    vouchers.value = vouchers.value.filter(v => v.id !== id);
  }

  // VALIDATE (for checkout — no side effect)
  async function validateVoucherAtCheckout(
    code: string,
    orderTotal: number,
    customerId?: string
  ): Promise<ValidateVoucherResult> {
    const { data, error: err } = await supabase.rpc('validate_voucher', {
      p_code:        code,
      p_branch_id:   activeBranchId!,
      p_order_total: orderTotal,
      p_customer_id: customerId ?? null
    });
    if (err) throw err;
    return data as ValidateVoucherResult;
  }

  // REDEEM (called inside checkout RPC after invoice created)
  async function redeemVoucher(
    voucherId: string,
    invoiceId: string,
    orderTotal: number,
    customerId?: string
  ): Promise<{ discount_amount: number }> {
    const { data, error: err } = await supabase.rpc('redeem_voucher', {
      p_voucher_id:  voucherId,
      p_invoice_id:  invoiceId,
      p_branch_id:   activeBranchId!,
      p_order_total: orderTotal,
      p_customer_id: customerId ?? null
    });
    if (err) {
      if (err.message.includes('P0010')) throw new Error('VOUCHER_NO_LONGER_VALID');
      throw err;
    }
    return data;
  }

  // STATS (single RPC, no N+1)
  async function fetchStats() {
    const { data } = await supabase.rpc('get_voucher_stats', { p_branch_id: activeBranchId! });
    stats.value = data;
  }

  // COMPUTED
  const activeVouchers  = computed(() => vouchers.value.filter(v => v.is_active));
  const expiredVouchers = computed(() => vouchers.value.filter(v =>
    v.valid_until && new Date(v.valid_until) < new Date()
  ));
  const usagePercent = (v: Voucher) =>
    v.max_uses ? Math.round((v.used_count / v.max_uses) * 100) : null;

  return {
    vouchers, stats, loading, error,
    listVouchers, createVoucher, updateVoucher,
    toggleVoucher, deleteVoucher,
    validateVoucherAtCheckout, redeemVoucher,
    fetchStats,
    activeVouchers, expiredVouchers, usagePercent
  };
}
```

---

### A.4 Business Logic & Edge Cases

| Scenario | Rule | Enforcement |
|---|---|---|
| Code must be uppercase | Strip whitespace + `.toUpperCase()` in `createVoucher` before insert | Composable + DB unique index on `UPPER(code)` |
| Cannot create duplicate code for same branch | Pre-check in composable + UNIQUE index enforces at DB level | Both layers |
| `percent` type with no cap → cannot give more than order total | In RPC: `LEAST(calculated, order_total)` | RPC |
| `amount` type → cannot give more than order total | `LEAST(value, order_total)` | RPC |
| `max_uses` reached between validate and redeem | Atomic `UPDATE ... WHERE used_count < max_uses` — zero rows → exception | `redeem_voucher` RPC |
| Two cashiers redeem same last use simultaneously | Both call `redeem_voucher`; one gets `ROW_COUNT = 0` → client shows "Voucher already fully redeemed" | `redeem_voucher` RPC |
| Voucher deactivated mid-checkout by admin | `redeem_voucher` checks `is_active = true` atomically | `redeem_voucher` RPC |
| Personalized voucher used by wrong customer | `validate_voucher` checks `customer_id` match | `validate_voucher` RPC |
| Per-customer usage limit | Count `voucher_usages` per `customer_id + voucher_id` | `validate_voucher` RPC |
| Delete voucher with existing usages | Soft delete only (`is_deleted = true`) — preserve `voucher_usages` audit trail | Composable |
| Min order value not met | `validate_voucher` returns `ORDER_BELOW_MINIMUM` with the threshold | `validate_voucher` RPC |

**Checkout Integration Sequence:**
```
1. Cashier enters voucher code (UI)
2. Frontend calls validateVoucherAtCheckout(code, orderTotal, customerId?) → get preview discount
3. Show discount preview to cashier ("GIAM10K: -50,000đ")
4. Cashier confirms checkout
5. Backend/Edge Function creates invoice record
6. Immediately after invoice created: calls redeemVoucher(voucherId, invoiceId, ...)
7. On P0010 error: revert invoice, show "Voucher expired between steps — please try again"
```

---

### A.5 UX/UI Design

#### Views to Create/Modify

**New view:** `src/views/manager/ManagerVoucherView.vue`  
**New view:** `src/views/admin/AdminVoucherView.vue` (same component, different permission level)

---

**Layout:** Three-zone layout — stats row at top, filter tabs + search bar in middle, table/grid below.

**Stats Row (4 cards):**
- Total Active Vouchers (gold number, dark card)
- Total Redeemed (count of `voucher_usages`)
- Total Discount Given (formatted VND/¥ depending on language)
- Avg Discount per Use

**Filter Tab Bar:** `All | Active | Expiring Soon (<7 days) | Expired | Personalized`

**Voucher Row/Card fields to show:**
- Code in monospace bold (copyable on click → clipboard toast)
- Type badge: `%` chip (amber) or `đ` chip (blue)
- Value displayed: "10%" or "50,000đ"
- Min order: "Min: 200,000đ" (gray, hidden if 0)
- Usage bar: thin horizontal bar (used_count / max_uses), percentage text below
- Date range: "22/12 – 15/01" or "No expiry"
- Status toggle switch (green=active, gray=inactive)
- Actions: Edit pencil icon, Delete trash icon (with confirmation)

**Create/Edit Form (slide-in right panel, 440px):**

Fields (top to bottom):
1. Code — text input, auto-uppercased, live unique check, monospace font
2. Type — segmented button: `Giảm %` | `Giảm cố định đ`
3. Value — number input (% shows "%" suffix, amount shows "đ" suffix)
4. Min order value — number input (optional, hint: "Leave 0 for no minimum")
5. Max discount cap — number input, only shown for % type (hint: "e.g. 50,000đ max even if order is large")
6. Valid period — date range picker: From / Until (optional)
7. Max total uses — number input (optional, hint: "Leave blank for unlimited")
8. Per-customer limit — number input (default: 1)
9. Personalized? — toggle → if on, customer phone search appears
10. Description (3 language tabs)
11. Save button → loading state → success toast → panel closes

**Empty state:** Dark card with voucher illustration, "Chưa có mã giảm giá nào. Tạo mã đầu tiên →"

---

## MODULE B — Membership / Loyalty System

### B.1 Database Schema — New Tables + Customer Patch

#### Patch `customers` table

```sql
ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS current_points   int DEFAULT 0,
  -- spendable balance right now
  ADD COLUMN IF NOT EXISTS lifetime_points  int DEFAULT 0,
  -- total ever earned (never decremented, used for tier calculation)
  ADD COLUMN IF NOT EXISTS tier_id          uuid REFERENCES public.membership_tiers(id) DEFAULT NULL;
  -- FK resolved after membership_tiers created

-- Index for tier-based queries
CREATE INDEX IF NOT EXISTS idx_customers_tier ON public.customers(tier_id);
CREATE INDEX IF NOT EXISTS idx_customers_branch_spent ON public.customers(branch_id, total_spent DESC);
```

#### New table: `membership_tiers`

Configurable by Superadmin/Admin — defines the tier ladder.

```sql
CREATE TABLE IF NOT EXISTS public.membership_tiers (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id         uuid REFERENCES public.branches(id),
  -- NULL = applies to all branches (global tier)
  name_vi           text NOT NULL,
  name_en           text,
  name_ja           text,
  min_spent         numeric(14,0) NOT NULL DEFAULT 0,
  -- customers with total_spent >= this value qualify for this tier
  discount_percent  numeric(5,2) DEFAULT 0,
  -- auto-applied bill discount for this tier (e.g. 5.00 = 5%)
  points_multiplier numeric(4,2) DEFAULT 1.0,
  -- earn multiplier (Gold members earn 1.5x points)
  color             text DEFAULT '#C9A85C',
  -- hex color for badge UI
  icon_name         text DEFAULT 'star',
  -- lucide icon name for the badge
  sort_order        int NOT NULL DEFAULT 0,
  -- display order; ALSO used to determine rank (higher = better)
  created_at        timestamptz DEFAULT now()
);

-- Seed default tiers (agent must run this after table creation)
INSERT INTO public.membership_tiers
  (name_vi, name_en, name_ja, min_spent, discount_percent, points_multiplier, color, icon_name, sort_order)
VALUES
  ('Đồng',       'Bronze',   'ブロンズ', 0,          0,   1.0,  '#CD7F32', 'award',   1),
  ('Bạc',        'Silver',   'シルバー',  2000000,    3,   1.2,  '#C0C0C0', 'shield',  2),
  ('Vàng',       'Gold',     'ゴールド',  5000000,    5,   1.5,  '#C9A85C', 'star',    3),
  ('Kim Cương',  'Diamond',  'ダイヤ',   10000000,   10,  2.0,  '#B9F2FF', 'gem',     4)
ON CONFLICT DO NOTHING;
```

#### New table: `loyalty_rules`

One row per branch (or global if `branch_id` IS NULL) — configures earn/redeem rates.

```sql
CREATE TABLE IF NOT EXISTS public.loyalty_rules (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id           uuid REFERENCES public.branches(id),
  -- NULL = global rule, branch-specific overrides global
  points_per_vnd      numeric(10,4) DEFAULT 0.001,
  -- 0.001 = 1 point per 1,000 VND spent
  vnd_per_point       numeric(10,2) DEFAULT 1000,
  -- 1,000 VND discount per 1 point redeemed
  min_redeem_points   int DEFAULT 100,
  -- minimum points needed to redeem
  max_redeem_percent  numeric(5,2) DEFAULT 50,
  -- max % of bill that can be paid with points (e.g. 50 = max 50% off)
  is_active           boolean DEFAULT true,
  updated_at          timestamptz DEFAULT now()
);

-- Seed default global rule
INSERT INTO public.loyalty_rules (branch_id, points_per_vnd, vnd_per_point, min_redeem_points)
VALUES (NULL, 0.001, 1000, 100)
ON CONFLICT DO NOTHING;
```

#### New table: `loyalty_transactions`

Immutable points ledger — never update, only insert.

```sql
CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id    uuid NOT NULL REFERENCES public.customers(id),
  branch_id      uuid NOT NULL REFERENCES public.branches(id),
  type           text NOT NULL CHECK (type IN ('EARN','REDEEM','EXPIRE','ADJUST_ADD','ADJUST_SUB')),
  points         int NOT NULL,
  -- ALWAYS POSITIVE. Sign determined by type (REDEEM/EXPIRE/ADJUST_SUB reduce balance).
  balance_after  int NOT NULL,
  -- snapshot of current_points AFTER this transaction (for audit/reconstruction)
  order_id       uuid REFERENCES public.orders(id) DEFAULT NULL,
  description    text,
  created_by     uuid REFERENCES auth.users(id) DEFAULT NULL,
  created_at     timestamptz DEFAULT now()
);

CREATE INDEX idx_loyalty_tx_customer ON public.loyalty_transactions(customer_id, created_at DESC);
CREATE INDEX idx_loyalty_tx_branch ON public.loyalty_transactions(branch_id, created_at DESC);
```

---

### B.2 RPC Functions

#### `get_customer_with_loyalty` — Full profile, single call, no N+1

```sql
CREATE OR REPLACE FUNCTION public.get_customer_with_loyalty(
  p_customer_id uuid
)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  v_customer  public.customers%ROWTYPE;
  v_tier      public.membership_tiers%ROWTYPE;
  v_next_tier public.membership_tiers%ROWTYPE;
  v_rule      public.loyalty_rules%ROWTYPE;
  v_txs       jsonb;
BEGIN
  SELECT * INTO v_customer FROM public.customers WHERE id = p_customer_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_FOUND' USING ERRCODE = 'P0020';
  END IF;

  -- Current tier
  SELECT * INTO v_tier FROM public.membership_tiers WHERE id = v_customer.tier_id;

  -- Next tier (the next tier above current, sorted by min_spent)
  SELECT * INTO v_next_tier
    FROM public.membership_tiers
   WHERE (branch_id = v_customer.branch_id OR branch_id IS NULL)
     AND min_spent > v_customer.total_spent
   ORDER BY min_spent ASC LIMIT 1;

  -- Loyalty rule (branch-specific, fall back to global)
  SELECT * INTO v_rule
    FROM public.loyalty_rules
   WHERE (branch_id = v_customer.branch_id OR branch_id IS NULL)
     AND is_active = true
   ORDER BY branch_id DESC NULLS LAST -- branch-specific first
   LIMIT 1;

  -- Recent transactions (last 20)
  SELECT jsonb_agg(t ORDER BY t.created_at DESC)
    INTO v_txs
    FROM (
      SELECT id, type, points, balance_after, description, created_at
        FROM public.loyalty_transactions
       WHERE customer_id = p_customer_id
       ORDER BY created_at DESC
       LIMIT 20
    ) t;

  RETURN jsonb_build_object(
    'customer',          row_to_json(v_customer),
    'tier',              row_to_json(v_tier),
    'next_tier',         row_to_json(v_next_tier),
    'spent_to_next_tier',
      CASE WHEN v_next_tier.id IS NOT NULL
           THEN v_next_tier.min_spent - v_customer.total_spent
           ELSE NULL END,
    'loyalty_rule',      row_to_json(v_rule),
    'recent_transactions', COALESCE(v_txs, '[]'::jsonb)
  );
END;
$$;
```

**Input:** `{ p_customer_id: uuid }`  
**Output:** Full JSON object with customer, current tier, next tier, progress to next tier, loyalty rules, last 20 transactions

---

#### `earn_points_for_order` — Called after checkout, auto-upgrades tier

```sql
CREATE OR REPLACE FUNCTION public.earn_points_for_order(
  p_customer_id  uuid,
  p_branch_id    uuid,
  p_order_id     uuid,
  p_order_amount numeric
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_rule         public.loyalty_rules%ROWTYPE;
  v_customer     public.customers%ROWTYPE;
  v_points_earn  int;
  v_new_points   int;
  v_new_lifetime int;
  v_new_tier_id  uuid;
  v_multiplier   numeric := 1.0;
BEGIN
  -- Fetch loyalty rule (branch > global fallback)
  SELECT * INTO v_rule
    FROM public.loyalty_rules
   WHERE (branch_id = p_branch_id OR branch_id IS NULL) AND is_active = true
   ORDER BY branch_id DESC NULLS LAST LIMIT 1;

  -- Lock customer row to prevent race with concurrent checkout
  SELECT * INTO v_customer FROM public.customers WHERE id = p_customer_id FOR UPDATE;

  -- Get current tier multiplier
  IF v_customer.tier_id IS NOT NULL THEN
    SELECT points_multiplier INTO v_multiplier
      FROM public.membership_tiers WHERE id = v_customer.tier_id;
  END IF;

  -- Calculate earned points
  v_points_earn  := FLOOR(p_order_amount * COALESCE(v_rule.points_per_vnd, 0.001) * v_multiplier);
  v_new_points   := v_customer.current_points + v_points_earn;
  v_new_lifetime := v_customer.lifetime_points + v_points_earn;

  -- Check for tier upgrade based on total_spent (already updated by checkout flow)
  SELECT id INTO v_new_tier_id
    FROM public.membership_tiers
   WHERE (branch_id = p_branch_id OR branch_id IS NULL)
     AND min_spent <= v_customer.total_spent
   ORDER BY min_spent DESC LIMIT 1;

  -- Update customer
  UPDATE public.customers SET
    current_points  = v_new_points,
    lifetime_points = v_new_lifetime,
    tier_id         = v_new_tier_id,
    updated_at      = now()
  WHERE id = p_customer_id;

  -- Insert loyalty transaction
  INSERT INTO public.loyalty_transactions (
    customer_id, branch_id, type, points, balance_after, order_id, description
  ) VALUES (
    p_customer_id, p_branch_id, 'EARN', v_points_earn, v_new_points,
    p_order_id,
    'Tích điểm từ đơn hàng ' || p_order_id::text
  );

  RETURN jsonb_build_object(
    'points_earned',   v_points_earn,
    'new_balance',     v_new_points,
    'tier_upgraded',   (v_new_tier_id IS DISTINCT FROM v_customer.tier_id),
    'new_tier_id',     v_new_tier_id
  );
END;
$$;
```

**Input:** `{ p_customer_id, p_branch_id, p_order_id, p_order_amount }`  
**Output:** `{ points_earned, new_balance, tier_upgraded: boolean, new_tier_id }`  
**Race condition safety:** `SELECT ... FOR UPDATE` on customers row before computing + updating  
**Tier upgrade:** Automatic, atomic, same transaction

---

#### `redeem_points` — Race-condition-safe deduction

```sql
CREATE OR REPLACE FUNCTION public.redeem_points(
  p_customer_id   uuid,
  p_branch_id     uuid,
  p_points        int,    -- points to redeem (must be positive)
  p_order_id      uuid DEFAULT NULL,
  p_description   text  DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_rule          public.loyalty_rules%ROWTYPE;
  v_current_pts   int;
  v_new_balance   int;
  v_discount_vnd  numeric(12,2);
BEGIN
  -- Fetch rule
  SELECT * INTO v_rule
    FROM public.loyalty_rules
   WHERE (branch_id = p_branch_id OR branch_id IS NULL) AND is_active = true
   ORDER BY branch_id DESC NULLS LAST LIMIT 1;

  IF p_points < COALESCE(v_rule.min_redeem_points, 100) THEN
    RAISE EXCEPTION 'BELOW_MIN_REDEEM: Minimum % points required, got %',
      v_rule.min_redeem_points, p_points USING ERRCODE = 'P0021';
  END IF;

  -- Lock customer row to prevent concurrent deduction
  SELECT current_points INTO v_current_pts
    FROM public.customers WHERE id = p_customer_id FOR UPDATE;

  IF v_current_pts < p_points THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS: Has %, needs %',
      v_current_pts, p_points USING ERRCODE = 'P0022';
  END IF;

  v_new_balance := v_current_pts - p_points;

  UPDATE public.customers SET
    current_points = v_new_balance,
    updated_at = now()
  WHERE id = p_customer_id;

  INSERT INTO public.loyalty_transactions (
    customer_id, branch_id, type, points, balance_after, order_id, description
  ) VALUES (
    p_customer_id, p_branch_id, 'REDEEM', p_points, v_new_balance,
    p_order_id, COALESCE(p_description, 'Đổi điểm lấy ưu đãi')
  );

  v_discount_vnd := p_points * COALESCE(v_rule.vnd_per_point, 1000);

  RETURN jsonb_build_object(
    'success',         true,
    'points_redeemed', p_points,
    'new_balance',     v_new_balance,
    'discount_vnd',    v_discount_vnd
  );
END;
$$;
```

**Input:** `{ p_customer_id, p_branch_id, p_points, p_order_id?, p_description? }`  
**Output:** `{ success, points_redeemed, new_balance, discount_vnd }` or raises `P0021`/`P0022`

---

#### `adjust_points` — Manual admin adjustment

```sql
CREATE OR REPLACE FUNCTION public.adjust_points(
  p_customer_id  uuid,
  p_branch_id    uuid,
  p_type         text,    -- 'ADJUST_ADD' | 'ADJUST_SUB'
  p_points       int,     -- always positive
  p_reason       text,
  p_admin_id     uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_current  int;
  v_new_bal  int;
BEGIN
  SELECT current_points INTO v_current
    FROM public.customers WHERE id = p_customer_id FOR UPDATE;

  IF p_type = 'ADJUST_SUB' AND v_current < p_points THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS' USING ERRCODE = 'P0022';
  END IF;

  v_new_bal := CASE p_type
    WHEN 'ADJUST_ADD' THEN v_current + p_points
    WHEN 'ADJUST_SUB' THEN v_current - p_points
  END;

  UPDATE public.customers SET
    current_points = v_new_bal,
    lifetime_points = CASE WHEN p_type = 'ADJUST_ADD'
      THEN lifetime_points + p_points ELSE lifetime_points END,
    updated_at = now()
  WHERE id = p_customer_id;

  INSERT INTO public.loyalty_transactions (
    customer_id, branch_id, type, points, balance_after, description, created_by
  ) VALUES (
    p_customer_id, p_branch_id, p_type, p_points, v_new_bal, p_reason, p_admin_id
  );

  RETURN jsonb_build_object('new_balance', v_new_bal);
END;
$$;
```

---

#### `get_crm_dashboard_stats` — Replace all hardcoded mock data

```sql
CREATE OR REPLACE FUNCTION public.get_crm_dashboard_stats(p_branch_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT jsonb_build_object(
    -- Customer counts
    'total_customers',
      (SELECT COUNT(*) FROM public.customers WHERE branch_id = p_branch_id),
    'new_customers_this_month',
      (SELECT COUNT(*) FROM public.customers
       WHERE branch_id = p_branch_id
         AND created_at >= date_trunc('month', now())),
    'repeater_customers',
      (SELECT COUNT(*) FROM public.customers
       WHERE branch_id = p_branch_id AND total_visits > 1),
    'vip_customers',
      (SELECT COUNT(*) FROM public.customers c
       JOIN public.membership_tiers t ON t.id = c.tier_id
       WHERE c.branch_id = p_branch_id AND t.sort_order >= 3),
    -- Spending
    'avg_spent_per_customer',
      (SELECT ROUND(AVG(total_spent), 0) FROM public.customers
       WHERE branch_id = p_branch_id AND total_spent > 0),
    'total_revenue_from_members',
      (SELECT COALESCE(SUM(total_spent), 0) FROM public.customers
       WHERE branch_id = p_branch_id),
    -- Tier distribution (for pie chart)
    'tier_distribution',
      (SELECT jsonb_agg(jsonb_build_object(
        'tier_id',   t.id,
        'name_vi',   t.name_vi,
        'name_en',   t.name_en,
        'name_ja',   t.name_ja,
        'color',     t.color,
        'count',     COUNT(c.id)
       ) ORDER BY t.sort_order)
       FROM public.membership_tiers t
       LEFT JOIN public.customers c ON c.tier_id = t.id AND c.branch_id = p_branch_id
       WHERE t.branch_id = p_branch_id OR t.branch_id IS NULL
       GROUP BY t.id, t.name_vi, t.name_en, t.name_ja, t.color, t.sort_order),
    -- Loyalty
    'total_points_in_circulation',
      (SELECT COALESCE(SUM(current_points), 0) FROM public.customers
       WHERE branch_id = p_branch_id),
    'total_points_redeemed',
      (SELECT COALESCE(SUM(points), 0) FROM public.loyalty_transactions
       WHERE branch_id = p_branch_id AND type = 'REDEEM'),
    -- Top 5 customers by spending
    'top_customers',
      (SELECT jsonb_agg(jsonb_build_object(
        'id',           c.id,
        'name',         c.name,
        'phone',        c.phone,
        'total_spent',  c.total_spent,
        'total_visits', c.total_visits,
        'current_points', c.current_points,
        'tier_name',    t.name_vi,
        'tier_color',   t.color
       ) ORDER BY c.total_spent DESC)
       FROM (
         SELECT c.*, t.name_vi, t.color
           FROM public.customers c
           LEFT JOIN public.membership_tiers t ON t.id = c.tier_id
          WHERE c.branch_id = p_branch_id
          ORDER BY c.total_spent DESC
          LIMIT 5
       ) c)
  );
$$;
```

---

#### `list_customers_with_tier` — Single join, no N+1, with filters & pagination

```sql
CREATE OR REPLACE FUNCTION public.list_customers_with_tier(
  p_branch_id   uuid,
  p_search      text   DEFAULT NULL,
  p_tier_id     uuid   DEFAULT NULL,
  p_limit       int    DEFAULT 30,
  p_offset      int    DEFAULT 0,
  p_sort_by     text   DEFAULT 'total_spent',
  p_sort_dir    text   DEFAULT 'desc'
)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  v_customers  jsonb;
  v_total      int;
BEGIN
  SELECT COUNT(*) INTO v_total
    FROM public.customers c
   WHERE c.branch_id = p_branch_id
     AND (p_tier_id IS NULL OR c.tier_id = p_tier_id)
     AND (p_search IS NULL
          OR c.name  ILIKE '%' || p_search || '%'
          OR c.phone ILIKE '%' || p_search || '%'
          OR c.email ILIKE '%' || p_search || '%');

  SELECT jsonb_agg(row) INTO v_customers FROM (
    SELECT
      c.id, c.name, c.phone, c.email,
      c.total_visits, c.total_spent, c.last_visit_at,
      c.current_points, c.lifetime_points,
      c.tags, c.is_vip, c.created_at,
      jsonb_build_object(
        'id',       t.id,
        'name_vi',  t.name_vi,
        'name_en',  t.name_en,
        'name_ja',  t.name_ja,
        'color',    t.color,
        'icon_name',t.icon_name,
        'discount_percent', t.discount_percent
      ) AS tier
    FROM public.customers c
    LEFT JOIN public.membership_tiers t ON t.id = c.tier_id
    WHERE c.branch_id = p_branch_id
      AND (p_tier_id IS NULL OR c.tier_id = p_tier_id)
      AND (p_search IS NULL
           OR c.name  ILIKE '%' || p_search || '%'
           OR c.phone ILIKE '%' || p_search || '%'
           OR c.email ILIKE '%' || p_search || '%')
    ORDER BY
      CASE WHEN p_sort_by = 'total_spent'   AND p_sort_dir = 'desc' THEN c.total_spent   END DESC NULLS LAST,
      CASE WHEN p_sort_by = 'total_visits'  AND p_sort_dir = 'desc' THEN c.total_visits  END DESC NULLS LAST,
      CASE WHEN p_sort_by = 'current_points'AND p_sort_dir = 'desc' THEN c.current_points END DESC NULLS LAST,
      CASE WHEN p_sort_by = 'last_visit_at' AND p_sort_dir = 'desc' THEN c.last_visit_at END DESC NULLS LAST,
      c.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) row;

  RETURN jsonb_build_object(
    'customers', COALESCE(v_customers, '[]'),
    'total',     v_total,
    'limit',     p_limit,
    'offset',    p_offset
  );
END;
$$;
```

---

### B.3 Composable `useMembership.ts`

**File:** `src/composables/useMembership.ts`

```typescript
export function useMembership() {
  const tiers     = ref<MembershipTier[]>([]);
  const rules     = ref<LoyaltyRule | null>(null);
  const { activeBranchId } = useBranchStore();
  const { id: adminId }    = useAuthStore();

  // Fetch all tier configurations
  async function fetchTiers() {
    const { data } = await supabase
      .from('membership_tiers')
      .select('*')
      .or(`branch_id.eq.${activeBranchId},branch_id.is.null`)
      .order('sort_order', { ascending: true });
    tiers.value = data ?? [];
  }

  // Admin: update tier thresholds
  async function updateTier(tierId: string, patch: Partial<MembershipTierPatch>) {
    const { data, error } = await supabase
      .from('membership_tiers')
      .update(patch)
      .eq('id', tierId)
      .select()
      .single();
    if (error) throw error;
    const i = tiers.value.findIndex(t => t.id === tierId);
    if (i >= 0) tiers.value[i] = data;
    return data;
  }

  // Fetch loyalty rules
  async function fetchRules() {
    const { data } = await supabase
      .from('loyalty_rules')
      .select('*')
      .or(`branch_id.eq.${activeBranchId},branch_id.is.null`)
      .order('branch_id', { ascending: false, nullsLast: true })
      .limit(1)
      .single();
    rules.value = data;
  }

  // Admin: update earn/redeem rates
  async function updateRules(patch: Partial<LoyaltyRule>) {
    const { error } = await supabase
      .from('loyalty_rules')
      .update({ ...patch, updated_at: new Date().toISOString() })
      .or(`branch_id.eq.${activeBranchId}`);
    if (error) throw error;
    if (rules.value) Object.assign(rules.value, patch);
  }

  // Calculate earn preview (client-side, for checkout UI)
  function previewEarnPoints(orderAmount: number, tierMultiplier = 1.0): number {
    if (!rules.value) return 0;
    return Math.floor(orderAmount * rules.value.points_per_vnd * tierMultiplier);
  }

  // Calculate redeem discount (client-side)
  function previewRedeemValue(points: number): number {
    if (!rules.value) return 0;
    return points * rules.value.vnd_per_point;
  }

  // Earn points after checkout
  async function earnPoints(customerId: string, orderId: string, orderAmount: number) {
    const { data, error } = await supabase.rpc('earn_points_for_order', {
      p_customer_id:  customerId,
      p_branch_id:    activeBranchId!,
      p_order_id:     orderId,
      p_order_amount: orderAmount
    });
    if (error) throw error;
    return data;
  }

  // Redeem points during checkout
  async function redeemPoints(customerId: string, points: number, orderId?: string) {
    const { data, error } = await supabase.rpc('redeem_points', {
      p_customer_id: customerId,
      p_branch_id:   activeBranchId!,
      p_points:      points,
      p_order_id:    orderId ?? null
    });
    if (error) {
      if (error.message.includes('P0022')) throw new Error('INSUFFICIENT_POINTS');
      if (error.message.includes('P0021')) throw new Error('BELOW_MIN_REDEEM');
      throw error;
    }
    return data;
  }

  // Admin: manual points adjustment
  async function adjustPoints(customerId: string, type: 'ADJUST_ADD' | 'ADJUST_SUB', points: number, reason: string) {
    const { data, error } = await supabase.rpc('adjust_points', {
      p_customer_id: customerId,
      p_branch_id:   activeBranchId!,
      p_type:        type,
      p_points:      points,
      p_reason:      reason,
      p_admin_id:    adminId
    });
    if (error) throw error;
    return data;
  }

  // Computed
  const tierById = computed(() =>
    Object.fromEntries(tiers.value.map(t => [t.id, t]))
  );

  return {
    tiers, rules, tierById,
    fetchTiers, updateTier, fetchRules, updateRules,
    previewEarnPoints, previewRedeemValue,
    earnPoints, redeemPoints, adjustPoints
  };
}
```

---

### B.4 Extend `useCustomer.ts`

Add these to the existing composable:

```typescript
// Full profile with loyalty data
async function getCustomerProfile(customerId: string): Promise<CustomerProfile> {
  const { data, error } = await supabase
    .rpc('get_customer_with_loyalty', { p_customer_id: customerId });
  if (error) throw error;
  return data;
}

// Paginated list with tier join (replaces existing flat query)
async function listCustomers(params?: {
  search?: string;
  tierId?: string;
  limit?: number;
  offset?: number;
  sortBy?: string;
}) {
  const { data, error } = await supabase.rpc('list_customers_with_tier', {
    p_branch_id: activeBranchId!,
    p_search:    params?.search ?? null,
    p_tier_id:   params?.tierId ?? null,
    p_limit:     params?.limit ?? 30,
    p_offset:    params?.offset ?? 0,
    p_sort_by:   params?.sortBy ?? 'total_spent'
  });
  if (error) throw error;
  return data; // { customers: [...], total: number }
}

// CRM Dashboard stats (replaces all hardcoded vars in ManagerCRMView.vue)
async function fetchCrmStats() {
  const { data } = await supabase
    .rpc('get_crm_dashboard_stats', { p_branch_id: activeBranchId! });
  return data;
}

// Remove the fallback mock data block — the function above always returns real data.
// If DB is empty, RPC returns zeroes, which is correct.
```

---

### B.5 Business Logic & Edge Cases

| Scenario | Rule | Enforcement |
|---|---|---|
| Two checkouts for same customer simultaneously | Both call `earn_points_for_order`; second waits on `FOR UPDATE` lock, then earns correctly | `earn_points_for_order` RPC |
| Customer redeems points they don't have | `INSUFFICIENT_POINTS` exception from `redeem_points` | `redeem_points` RPC |
| Below minimum redeem threshold | `BELOW_MIN_REDEEM` exception | `redeem_points` RPC |
| Tier upgrade doesn't happen automatically after admin changes thresholds | Tier is recalculated from `total_spent` every time `earn_points_for_order` is called | `earn_points_for_order` RPC — always recalculates `tier_id` |
| Admin wants to force-upgrade a customer's tier | Use `adjustPoints` + manually run `UPDATE customers SET tier_id=? WHERE id=?` (admin-only route) | Admin composable action |
| Points earned on a cancelled/refunded order | Create `loyalty_transactions` with `type='ADJUST_SUB'` equal to the `EARN` transaction on cancel | Order cancellation flow must call `adjustPoints` |
| VIP flag (`is_vip`) conflicts with new tier system | Keep `is_vip` for backward compat; sync it: `is_vip = (tier.sort_order >= 3)` in `earn_points_for_order` RPC | Set `is_vip = (v_new_tier.sort_order >= 3)` in UPDATE |
| CRM dashboard was all hardcoded mock | Replace `summaryStats`, `channelBars`, `ageBars` in `ManagerCRMView.vue` with result from `get_crm_dashboard_stats()` | View migration task |
| Fallback mock list (6 fake customers) | Remove the `if (!data?.length) return mockCustomers` block entirely | View migration task |
| Points balance inconsistency (drift) | `balance_after` column on every `loyalty_transactions` allows reconstruction; run integrity check: `SELECT SUM(signed_points) = current_points` | Data audit script (optional) |
| Checkout: max % of bill paid with points | Enforce in `redeem_points` or client side: `Math.min(points, floor(orderTotal * maxRedeemPercent / 100 / vndPerPoint))` | Composable `previewRedeemValue` with cap |

**Full Checkout Points Integration Sequence:**
```
1. Cashier scans/enters customer phone → searchByPhone → load customer profile (getCustomerProfile)
2. Show customer: name, tier badge, current_points balance
3. Optional: Customer wants to redeem points
   a. Cashier enters points to redeem (max shown = min(current_points, floor(total * maxRedeemPct/100 / vndPerPoint)))
   b. Preview: "100 điểm = -100,000đ"
   c. On confirm checkout → calls redeemPoints() atomically
4. Post-checkout (after invoice created):
   a. Call earnPoints(customerId, orderId, finalAmount) — final amount AFTER voucher/point discount
   b. If tier_upgraded = true in response → show "Chúc mừng! Bạn đã lên hạng Vàng 🎉"
5. Print receipt with: earned points, new balance, tier name
```

---

### B.6 UX/UI Design

#### Views to Create/Modify

| File | Action |
|---|---|
| `src/views/manager/ManagerCRMView.vue` | Modify: Replace all hardcoded stats + mock customer list |
| `src/views/manager/ManagerMembershipView.vue` | Create: Tier configuration + loyalty rules admin panel |
| `src/components/customer/CustomerDetailDrawer.vue` | Create: Full customer profile with points history |
| `src/components/customer/TierBadge.vue` | Create: Reusable tier badge chip |
| `src/components/loyalty/PointsPreview.vue` | Create: Earn/redeem preview for checkout |

---

**`ManagerCRMView.vue` Redesign:**

Top section — Real stats in 4 cards (from `get_crm_dashboard_stats`):
- Total Members (with vs last month delta badge)
- Repeat Rate: `repeater_customers / total_customers * 100`%
- Avg Spend per Customer (formatted VND)
- Points in Circulation

Middle section — Tier distribution pie/donut chart using computed `tier_distribution` from RPC. Each slice uses the tier's `color` hex. Render as an SVG donut (no external chart lib needed).

Customer list — Replace hardcoded table with:
- Search bar (debounced 300ms, calls `listCustomers({ search })`)
- Filter chips: All | Bronze | Silver | Gold | Diamond
- Table columns: Name + phone | Tier badge | Total spent | Points | Last visit | Actions
- Pagination: 30 per page, load more button
- Sort: click column header cycles `asc/desc`

Remove: `summaryStats`, `channelBars`, `ageBars` variables and their hardcoded values.

---

**`CustomerDetailDrawer.vue` — Right slide-in panel:**

Header section:
- Large avatar initials (first letter of name, colored by tier color)
- Name + phone
- Tier badge (icon + name + color from `membership_tiers`)
- Join date

Points section (mid panel, most prominent):
- Current balance in large gold number: `◆ 1,240 điểm`
- Progress bar to next tier: "Còn 3,500,000đ để lên Kim Cương"
- Earn rate shown: "1 điểm / 1,000đ chi tiêu"
- Admin action: "+" button → modal to add/subtract points manually (with reason field)

Stats strip:
- Total Spent | Total Visits | Last Visit

Transaction history — Timeline list (last 20):
- Each item: icon (arrow-up=EARN, arrow-down=REDEEM, pencil=ADJUST), points ±, date, description
- EARN rows: green text, `+150 điểm`
- REDEEM rows: amber text, `-100 điểm`
- ADJUST rows: gray text

---

**`ManagerMembershipView.vue` — Tier + Rules Config:**

Two tabs: "Membership Tiers" | "Earn & Redeem Rules"

**Tiers tab:**
- Card per tier, vertically stacked in order (Bronze → Diamond)
- Each card: colored border-left matching tier color, icon, name (3 language inputs inline), min_spent threshold, discount_percent, points_multiplier
- Inline edit: click value to edit in place, auto-save on blur
- Live preview: "A customer who spent 5,000,000đ qualifies for Gold tier and earns 1.5x points per purchase"

**Rules tab:**
- Simple form (3 fields):
  - Points per VND spent (e.g. `0.001` → "1 point per 1,000đ")
  - VND value per point (e.g. `1000` → "1 point = 1,000đ discount")
  - Minimum points to redeem
  - Maximum % of bill payable with points
- Save button → calls `updateRules()`

---

**`TierBadge.vue` — Reusable component:**

```vue
<!-- Usage: <TierBadge :tier="customer.tier" size="sm|md|lg" /> -->
<!-- Renders a pill with: colored background, icon, tier name in current language -->
```

Small variant: just icon + abbreviated name `◆ KD`  
Medium variant: icon + full name `◆ Kim Cương`  
Large variant: icon + full name + discount `◆ Kim Cương · -10%`

---

## 3. i18n Keys — Additions to `useLanguageStore.ts`

Add these to all three language objects in the `dict`:

```typescript
// Vietnamese
{
  // Voucher
  'voucher.title':              'Mã Giảm Giá',
  'voucher.create':             'Tạo mã mới',
  'voucher.code':               'Mã voucher',
  'voucher.type.percent':       'Giảm %',
  'voucher.type.amount':        'Giảm tiền mặt',
  'voucher.value':              'Giá trị',
  'voucher.min_order':          'Đơn tối thiểu',
  'voucher.max_discount':       'Giảm tối đa',
  'voucher.valid_from':         'Từ ngày',
  'voucher.valid_until':        'Đến ngày',
  'voucher.max_uses':           'Số lượng phát hành',
  'voucher.used_count':         'Đã sử dụng',
  'voucher.per_customer_limit': 'Giới hạn / khách',
  'voucher.personalized':       'Voucher cá nhân hóa',
  'voucher.status.active':      'Đang hoạt động',
  'voucher.status.inactive':    'Đã tắt',
  'voucher.status.expired':     'Hết hạn',
  'voucher.copy_code':          'Đã sao chép mã!',
  'voucher.apply':              'Áp dụng',
  'voucher.applied':            'Đã áp dụng',
  'voucher.error.not_found':    'Mã voucher không tồn tại',
  'voucher.error.expired':      'Mã voucher đã hết hạn',
  'voucher.error.exhausted':    'Mã voucher đã hết lượt sử dụng',
  'voucher.error.min_order':    'Đơn hàng chưa đạt mức tối thiểu {min}',
  'voucher.error.not_for_you':  'Mã này không áp dụng cho bạn',
  'voucher.error.used_up':      'Bạn đã dùng mã này rồi',
  'voucher.stats.total_given':  'Tổng tiền đã giảm',
  'voucher.stats.total_used':   'Tổng lượt dùng',
  // Membership
  'membership.title':           'Hội Viên',
  'membership.tier':            'Hạng thành viên',
  'membership.points':          'Điểm thưởng',
  'membership.points_balance':  'Số điểm hiện tại',
  'membership.earn':            'Tích điểm',
  'membership.redeem':          'Đổi điểm',
  'membership.tier.bronze':     'Đồng',
  'membership.tier.silver':     'Bạc',
  'membership.tier.gold':       'Vàng',
  'membership.tier.diamond':    'Kim Cương',
  'membership.next_tier':       'Còn {amount} để lên {tier}',
  'membership.discount':        'Ưu đãi hội viên: -{percent}%',
  'membership.earn_preview':    '+{points} điểm sau đơn này',
  'membership.redeem_preview':  '{points} điểm = -{amount}đ',
  'membership.history':         'Lịch sử điểm',
  'membership.adjust_add':      'Cộng điểm',
  'membership.adjust_sub':      'Trừ điểm',
  'membership.reason':          'Lý do',
  'membership.tier_upgraded':   'Chúc mừng! Bạn đã lên hạng {tier}! 🎉',
  'membership.error.insufficient': 'Không đủ điểm',
  'membership.error.below_min': 'Cần tối thiểu {min} điểm để đổi',
  // CRM
  'crm.total_customers':        'Tổng Khách Hàng',
  'crm.repeat_rate':            'Tỷ lệ Khách Quen',
  'crm.avg_spent':              'Chi tiêu TB / Người',
  'crm.points_circulating':     'Điểm đang lưu hành',
  'crm.top_customers':          'Khách hàng nổi bật',
  'crm.tier_distribution':      'Phân bổ hạng thành viên',
}

// English (same keys)
{
  'voucher.title':              'Voucher Management',
  'voucher.create':             'Create Voucher',
  'voucher.code':               'Voucher Code',
  'voucher.type.percent':       'Percentage Discount',
  'voucher.type.amount':        'Fixed Amount',
  'voucher.min_order':          'Min. Order Value',
  'voucher.max_discount':       'Max Discount Cap',
  'voucher.valid_from':         'Valid From',
  'voucher.valid_until':        'Valid Until',
  'voucher.max_uses':           'Total Uses Allowed',
  'voucher.used_count':         'Times Used',
  'voucher.per_customer_limit': 'Limit per Customer',
  'voucher.personalized':       'Personalized Voucher',
  'voucher.status.active':      'Active',
  'voucher.status.inactive':    'Inactive',
  'voucher.status.expired':     'Expired',
  'voucher.copy_code':          'Code copied!',
  'voucher.apply':              'Apply',
  'voucher.applied':            'Applied',
  'voucher.error.not_found':    'Voucher code not found',
  'voucher.error.expired':      'This voucher has expired',
  'voucher.error.exhausted':    'This voucher has been fully redeemed',
  'voucher.error.min_order':    'Order must be at least {min}',
  'voucher.error.not_for_you':  'This voucher is not for your account',
  'voucher.error.used_up':      'You have already used this voucher',
  'voucher.stats.total_given':  'Total Savings Given',
  'voucher.stats.total_used':   'Total Redemptions',
  'membership.title':           'Membership',
  'membership.tier':            'Tier',
  'membership.points':          'Points',
  'membership.points_balance':  'Current Points',
  'membership.earn':            'Earn Points',
  'membership.redeem':          'Redeem Points',
  'membership.tier.bronze':     'Bronze',
  'membership.tier.silver':     'Silver',
  'membership.tier.gold':       'Gold',
  'membership.tier.diamond':    'Diamond',
  'membership.next_tier':       '{amount} more to reach {tier}',
  'membership.discount':        'Member discount: -{percent}%',
  'membership.earn_preview':    '+{points} pts after this order',
  'membership.redeem_preview':  '{points} pts = -{amount} off',
  'membership.history':         'Points History',
  'membership.adjust_add':      'Add Points',
  'membership.adjust_sub':      'Deduct Points',
  'membership.reason':          'Reason',
  'membership.tier_upgraded':   'Congratulations! You reached {tier}! 🎉',
  'membership.error.insufficient': 'Not enough points',
  'membership.error.below_min': 'Minimum {min} points required to redeem',
  'crm.total_customers':        'Total Members',
  'crm.repeat_rate':            'Repeat Rate',
  'crm.avg_spent':              'Avg. Spend / Person',
  'crm.points_circulating':     'Points in Circulation',
  'crm.top_customers':          'Top Customers',
  'crm.tier_distribution':      'Tier Distribution',
}

// Japanese
{
  'voucher.title':              'クーポン管理',
  'voucher.create':             'クーポン作成',
  'voucher.code':               'クーポンコード',
  'voucher.type.percent':       '割引率',
  'voucher.type.amount':        '金額割引',
  'voucher.min_order':          '最低注文金額',
  'voucher.max_discount':       '最大割引額',
  'voucher.valid_from':         '有効開始日',
  'voucher.valid_until':        '有効期限',
  'voucher.max_uses':           '発行数',
  'voucher.used_count':         '利用回数',
  'voucher.per_customer_limit': '1人あたりの制限',
  'voucher.personalized':       '個人向けクーポン',
  'voucher.status.active':      '有効',
  'voucher.status.inactive':    '無効',
  'voucher.status.expired':     '期限切れ',
  'voucher.copy_code':          'コードをコピーしました！',
  'voucher.apply':              '適用',
  'voucher.applied':            '適用済み',
  'voucher.error.not_found':    'クーポンが見つかりません',
  'voucher.error.expired':      'クーポンの有効期限が切れています',
  'voucher.error.exhausted':    'クーポンの使用上限に達しました',
  'voucher.error.min_order':    '注文金額が{min}以上必要です',
  'voucher.error.not_for_you':  'このクーポンはご利用いただけません',
  'voucher.error.used_up':      'このクーポンは既に使用済みです',
  'voucher.stats.total_given':  '合計割引額',
  'voucher.stats.total_used':   '合計利用回数',
  'membership.title':           '会員システム',
  'membership.tier':            '会員ランク',
  'membership.points':          'ポイント',
  'membership.points_balance':  '現在のポイント',
  'membership.earn':            'ポイント獲得',
  'membership.redeem':          'ポイント利用',
  'membership.tier.bronze':     'ブロンズ',
  'membership.tier.silver':     'シルバー',
  'membership.tier.gold':       'ゴールド',
  'membership.tier.diamond':    'ダイヤモンド',
  'membership.next_tier':       '{tier}まであと{amount}',
  'membership.discount':        '会員割引：-{percent}%',
  'membership.earn_preview':    'このご注文で+{points}pt',
  'membership.redeem_preview':  '{points}pt = -{amount}円引き',
  'membership.history':         'ポイント履歴',
  'membership.adjust_add':      'ポイント追加',
  'membership.adjust_sub':      'ポイント減算',
  'membership.reason':          '理由',
  'membership.tier_upgraded':   'おめでとうございます！{tier}になりました！🎉',
  'membership.error.insufficient': 'ポイントが不足しています',
  'membership.error.below_min': '最低{min}ポイント必要です',
  'crm.total_customers':        '総会員数',
  'crm.repeat_rate':            'リピート率',
  'crm.avg_spent':              '1人あたり平均消費',
  'crm.points_circulating':     '流通ポイント数',
  'crm.top_customers':          'トップ顧客',
  'crm.tier_distribution':      '会員ランク分布',
}
```

---

## 4. Race Condition & Concurrency Summary

| Scenario | Layer | Method |
|---|---|---|
| Two cashiers redeem last voucher use at same time | DB | `UPDATE vouchers SET used_count = used_count + 1 WHERE used_count < max_uses` — `ROW_COUNT = 0` on loser |
| Voucher deactivated between validate & redeem | DB | `redeem_voucher` checks `is_active = true` atomically in the same UPDATE |
| Two checkouts earn points for same customer simultaneously | DB | `SELECT ... FOR UPDATE` in `earn_points_for_order` — second waits on lock |
| Two simultaneous point redemptions (double-spend) | DB | `SELECT ... FOR UPDATE` in `redeem_points` — second fails balance check |
| Admin adjusts tier thresholds while checkout is in progress | No race risk | Tier is recalculated from `total_spent` at time of `earn_points_for_order` call |
| Code uniqueness: two admins create same code simultaneously | DB | `UNIQUE INDEX ON UPPER(code), branch_id` — one gets DB error, composable catches + re-surfaces |

---

## 5. N+1 Prevention Summary

| Old pattern (❌) | Replacement (✅) |
|---|---|
| Loop customers → fetch tier for each | `list_customers_with_tier()` RPC returns customers + tier in one flat join |
| Multiple separate stat queries in `ManagerCRMView` | `get_crm_dashboard_stats()` single RPC call |
| Load customer + points + tier + transactions in 4 calls | `get_customer_with_loyalty()` single RPC, returns all as one JSON |
| Fetch voucher then separately fetch usage count | `voucher_usages` aggregated in `get_voucher_stats()` RPC; `used_count` lives on voucher row |
| Checkout: validate, then fetch discount calc client-side, then redeem | `validate_voucher()` returns `discount_amount` already; `redeem_voucher()` recalculates atomically |

---

## 6. Agent Task List (Ordered)

Execute in this exact sequence. Each task is self-contained.

---

### TASK A-1 — Patch `vouchers` Table

**File:** Supabase SQL Editor  
**Run:** `ALTER TABLE` from §A.1 (add `min_order_value`, `max_discount_amount`, `customer_id`, `usage_limit_per_customer`, `description_*`, `is_deleted`)  
**Run:** `CREATE TABLE voucher_usages` from §A.1  
**Run:** `CREATE UNIQUE INDEX idx_vouchers_code_branch`  
**Verify:** `\d vouchers` shows all new columns; `\d voucher_usages` shows table

---

### TASK A-2 — Create Voucher RPC Functions

**File:** Supabase SQL Editor  
**Run in order:**
1. `validate_voucher()` function from §A.2
2. `redeem_voucher()` function from §A.2
3. `get_voucher_stats()` function from §A.2

**Verify:**
```sql
SELECT public.validate_voucher('TEST', '<your-branch-id>', 100000, NULL);
-- Should return { valid: false, error: 'VOUCHER_NOT_FOUND' }
```

---

### TASK A-3 — Create `useVoucher.ts`

**File:** `src/composables/useVoucher.ts`  
**Content:** Full composable from §A.3  
**Dependencies:** `useBranchStore`, `useAuthStore`, Supabase client

---

### TASK A-4 — Create `ManagerVoucherView.vue`

**File:** `src/views/manager/ManagerVoucherView.vue`  
**Template structure:**
1. `onMounted`: call `fetchStats()` + `listVouchers()`
2. Stats row: 4 cards, data from `stats` ref
3. Filter tabs + search bar (use `@click` on tabs → `listVouchers({ onlyActive: true })`)
4. Voucher table/list with columns from §A.5
5. Slide-in panel (`:class="{ open: panelOpen }"`) for create/edit
6. In the panel: form fields from §A.5, `@submit` calls `createVoucher()` or `updateVoucher()`
7. Toggle: `<toggle-switch @change="toggleVoucher(v.id, !v.is_active)" />`
8. Delete: confirmation dialog → `deleteVoucher(id)`
9. All strings via `t('voucher.*')` from language store

**Add route** in `router/index.ts`:
```typescript
{ path: '/manager/vouchers', name: 'ManagerVouchers', component: ManagerVoucherView, meta: { requiresRole: ['manager','admin','superadmin'] } }
```

**Add nav link** in manager sidebar.

---

### TASK A-5 — Wire Checkout to `validateVoucherAtCheckout` + `redeemVoucher`

**File:** `src/views/reception/ReceptionCheckoutView.vue` (or wherever checkout lives)

**Changes:**
1. Voucher input field: on `@keyup.enter` or blur → call `validateVoucherAtCheckout(code, orderTotal, customerId?)` 
2. Show preview result: green chip "GIAM10K: -50,000đ" or red error message from `t('voucher.error.' + errorCode.toLowerCase())`
3. After invoice created: call `redeemVoucher(voucherId, invoiceId, orderTotal, customerId?)`
4. On `P0010` error: show toast "Mã voucher vừa hết hiệu lực" and remove discount from total

---

### TASK B-1 — Database Migrations (Membership)

**File:** Supabase SQL Editor  
**Run in order:**
1. `CREATE TABLE membership_tiers` from §B.1
2. `INSERT INTO membership_tiers` (default 4 tiers seed) from §B.1
3. `CREATE TABLE loyalty_rules` from §B.1
4. `INSERT INTO loyalty_rules` (default global rule seed) from §B.1
5. `CREATE TABLE loyalty_transactions` from §B.1
6. `ALTER TABLE customers ADD COLUMN` from §B.1 (current_points, lifetime_points, tier_id + FK)

**Verify:**
```sql
SELECT * FROM membership_tiers ORDER BY sort_order;
-- Should return 4 rows: Bronze, Silver, Gold, Diamond
SELECT * FROM loyalty_rules;
-- Should return 1 row with points_per_vnd = 0.001
```

---

### TASK B-2 — Create Membership RPC Functions

**File:** Supabase SQL Editor  
**Run in order:**
1. `get_customer_with_loyalty()`
2. `earn_points_for_order()`
3. `redeem_points()`
4. `adjust_points()`
5. `get_crm_dashboard_stats()`
6. `list_customers_with_tier()`

**Verify:**
```sql
SELECT public.get_crm_dashboard_stats('<your-branch-id>');
-- Should return valid JSON with all keys, zeroes if DB is empty
```

---

### TASK B-3 — Create `useMembership.ts`

**File:** `src/composables/useMembership.ts`  
**Content:** Full composable from §B.3

---

### TASK B-4 — Extend `useCustomer.ts`

**File:** `src/composables/useCustomer.ts`  
**Add:** `getCustomerProfile()`, updated `listCustomers()` (call `list_customers_with_tier` RPC), `fetchCrmStats()`  
**Remove:** Any `if (!data?.length) return mockCustomers` fallback blocks

---

### TASK B-5 — Update `ManagerCRMView.vue`

**File:** `src/views/manager/ManagerCRMView.vue`  

**Remove completely:**
- `summaryStats` hardcoded object
- `channelBars` hardcoded array
- `ageBars` hardcoded array
- Any reference to `Nguyễn Thị Lan`, `Trần Minh Quân` mock customers

**Replace with:**
```typescript
onMounted(async () => {
  stats.value = await fetchCrmStats();
  const result = await listCustomers({ limit: 30 });
  customers.value = result.customers;
  totalCount.value = result.total;
});
```

- Bind `stats.total_customers` → stat card
- Bind `stats.repeater_customers / stats.total_customers * 100` → repeat rate card
- Bind `stats.avg_spent_per_customer` → avg spend card
- Render `stats.tier_distribution` → pie/donut SVG (simple arc calculation, no chart library needed)
- Render `stats.top_customers` → top customers list

---

### TASK B-6 — Create `CustomerDetailDrawer.vue`

**File:** `src/components/customer/CustomerDetailDrawer.vue`  

**Props:** `customerId: string | null`  
**Emits:** `close`

**Lifecycle:**
- Watch `customerId`; when non-null, call `getCustomerProfile(customerId)` → populate local refs
- On close, reset

**Sections:** As described in §B.6  
**Admin actions:** Points adjustment form (visible only if `isManager || isAdmin`)

---

### TASK B-7 — Create `ManagerMembershipView.vue`

**File:** `src/views/manager/ManagerMembershipView.vue`  
**Content:** Tier config + Rules config as described in §B.6  
**Add route** in `router/index.ts`:  
```typescript
{ path: '/manager/membership', name: 'ManagerMembership', component: ManagerMembershipView, meta: { requiresRole: ['manager','admin','superadmin'] } }
```

---

### TASK B-8 — Create Reusable `TierBadge.vue`

**File:** `src/components/customer/TierBadge.vue`  
**Props:** `tier: MembershipTier | null`, `size: 'sm' | 'md' | 'lg'`  
**Renders:** Pill badge, colored per `tier.color`, with icon (`tier.icon_name`) and name in current language (`t('membership.tier.' + tier.name_en.toLowerCase())`)

---

### TASK B-9 — Wire Checkout to Loyalty

**File:** `src/views/reception/ReceptionCheckoutView.vue`

**Add to checkout flow (after customer lookup):**
1. Show `TierBadge` next to customer name
2. Show points balance: `◆ customer.current_points điểm`
3. If `current_points >= rules.min_redeem_points`: show "Dùng điểm" toggle
4. When toggled: show slider/input for points (capped at `min(current_points, floor(total * maxRedeemPct/100 / vndPerPoint))`)
5. Show preview: `t('membership.redeem_preview', { points, amount })` 
6. After invoice created → call `earnPoints(customerId, orderId, finalAmount)`
7. If `tier_upgraded` in response → show congratulations toast
8. If redeem was used → call `redeemPoints(customerId, points, orderId)` before `earnPoints`

---

### TASK B-10 — Add i18n Keys

**File:** `src/stores/useLanguageStore.ts`  
**Action:** Append all keys from §3 to `vi`, `en`, `ja` objects in the `dict`  
**Note:** Keys with `{placeholder}` use the `params` argument:
```typescript
t('membership.next_tier', { amount: formatVND(500000), tier: t('membership.tier.diamond') })
```

---

*End of Plan — Module A (Vouchers) + Module B (Membership/Loyalty)*  
*Targeting ProjectCongTyEEE@main — Vue 3 + Pinia + Supabase*
