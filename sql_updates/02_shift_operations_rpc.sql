-- 02_shift_operations_rpc.sql
-- Run this manually to create the RPCs for Shift Operations

create or replace function public.rpc_open_shift(
  p_branch_id uuid,
  p_opened_by_profile_id uuid,
  p_opening_cash_vnd bigint
) returns jsonb as $$
declare
  v_shift_id uuid;
  v_open_count int;
begin
  -- 1. Check if there is already an open shift in this branch
  select count(*) into v_open_count
  from public.shifts
  where branch_id = p_branch_id and status = 'open';
  
  if v_open_count > 0 then
    raise exception 'Có một ca đang mở tại chi nhánh này, không thể mở thêm ca mới.';
  end if;

  -- 2. Create a new shift
  insert into public.shifts (
    branch_id,
    opened_by_profile_id,
    opening_cash_vnd,
    status
  ) values (
    p_branch_id,
    p_opened_by_profile_id,
    p_opening_cash_vnd,
    'open'
  ) returning shift_id into v_shift_id;

  return jsonb_build_object(
    'success', true,
    'shift_id', v_shift_id,
    'message', 'Đã mở ca thành công.'
  );
end;
$$ language plpgsql security definer;

create or replace function public.rpc_close_shift(
  p_branch_id uuid,
  p_shift_id uuid,
  p_closed_by_profile_id uuid,
  p_counted_cash_vnd bigint,
  p_counted_bank_vnd bigint,
  p_note text
) returns jsonb as $$
declare
  v_shift_status text;
  v_opening_cash bigint;
  
  v_cash_payments bigint := 0;
  v_cash_refunds bigint := 0;
  v_cash_expenses bigint := 0;
  v_cash_supplier_payments bigint := 0;
  
  v_bank_payments bigint := 0;
  v_bank_refunds bigint := 0;
  v_bank_supplier_payments bigint := 0;
  
  v_expected_cash bigint := 0;
  v_expected_bank bigint := 0;
begin
  -- 1. Check shift exists and is open
  select status, opening_cash_vnd into v_shift_status, v_opening_cash
  from public.shifts
  where branch_id = p_branch_id and shift_id = p_shift_id for update;
  
  if v_shift_status is null then
    raise exception 'Ca làm việc không tồn tại.';
  end if;
  
  if v_shift_status <> 'open' then
    raise exception 'Ca làm việc này đã được đóng hoặc không ở trạng thái mở.';
  end if;

  -- 2. Calculate aggregations
  -- Payments (Revenue)
  select coalesce(sum(amount_vnd), 0) into v_cash_payments
  from public.payments
  where branch_id = p_branch_id and shift_id = p_shift_id and payment_method = 'cash' and transaction_type = 'payment';
  
  select coalesce(sum(amount_vnd), 0) into v_cash_refunds
  from public.payments
  where branch_id = p_branch_id and shift_id = p_shift_id and payment_method = 'cash' and transaction_type = 'refund';
  
  select coalesce(sum(amount_vnd), 0) into v_bank_payments
  from public.payments
  where branch_id = p_branch_id and shift_id = p_shift_id and payment_method <> 'cash' and transaction_type = 'payment';
  
  select coalesce(sum(amount_vnd), 0) into v_bank_refunds
  from public.payments
  where branch_id = p_branch_id and shift_id = p_shift_id and payment_method <> 'cash' and transaction_type = 'refund';
  
  -- Expenses
  select coalesce(sum(amount_vnd), 0) into v_cash_expenses
  from public.cash_expenses
  where branch_id = p_branch_id and shift_id = p_shift_id and status = 'paid';
  
  -- Supplier Payments
  select coalesce(sum(amount_vnd), 0) into v_cash_supplier_payments
  from public.supplier_payments
  where branch_id = p_branch_id and shift_id = p_shift_id and payment_method = 'cash';
  
  select coalesce(sum(amount_vnd), 0) into v_bank_supplier_payments
  from public.supplier_payments
  where branch_id = p_branch_id and shift_id = p_shift_id and payment_method <> 'cash';
  
  -- 3. Calculate expected totals
  v_expected_cash := v_opening_cash + v_cash_payments - v_cash_refunds - v_cash_expenses - v_cash_supplier_payments;
  v_expected_bank := v_bank_payments - v_bank_refunds - v_bank_supplier_payments;

  -- 4. Update shift record
  update public.shifts
  set 
    status = 'closed',
    closed_at = now(),
    closed_by_profile_id = p_closed_by_profile_id,
    expected_cash_vnd = v_expected_cash,
    expected_bank_vnd = v_expected_bank,
    counted_cash_vnd = p_counted_cash_vnd,
    counted_bank_vnd = p_counted_bank_vnd,
    variance_cash_vnd = p_counted_cash_vnd - v_expected_cash,
    note = p_note
  where branch_id = p_branch_id and shift_id = p_shift_id;

  return jsonb_build_object(
    'success', true,
    'expected_cash', v_expected_cash,
    'expected_bank', v_expected_bank,
    'variance_cash', p_counted_cash_vnd - v_expected_cash,
    'variance_bank', p_counted_bank_vnd - v_expected_bank,
    'message', 'Đã đóng ca thành công.'
  );
end;
$$ language plpgsql security definer;
