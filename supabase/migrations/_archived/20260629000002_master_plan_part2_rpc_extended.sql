-- Migration: master_plan_part2_rpc_extended
-- Implement missing RPCs to pass testing checklist

-- 1. create_reservation
CREATE OR REPLACE FUNCTION public.create_reservation(
    p_guest_name text,
    p_guest_phone text,
    p_reservation_time timestamptz,
    p_guest_count int,
    p_notes text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_res_id uuid;
    v_branch_id uuid;
BEGIN
    SELECT id INTO v_branch_id FROM branches LIMIT 1;
    INSERT INTO reservations (branch_id, guest_name, guest_phone, reservation_time, guest_count, status, notes)
    VALUES (v_branch_id, p_guest_name, p_guest_phone, p_reservation_time, p_guest_count, 'PENDING', p_notes)
    RETURNING id INTO v_res_id;
    RETURN v_res_id;
END;
$$;

-- 2. confirm_reservation
CREATE OR REPLACE FUNCTION public.confirm_reservation(
    p_reservation_id uuid,
    p_table_id uuid DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE reservations 
    SET status = 'CONFIRMED', assigned_table_id = p_table_id, updated_at = now()
    WHERE id = p_reservation_id AND status = 'PENDING';
END;
$$;

-- 3. seat_reservation
CREATE OR REPLACE FUNCTION public.seat_reservation(
    p_reservation_id uuid,
    p_table_id uuid DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE reservations 
    SET status = 'SEATED', assigned_table_id = COALESCE(p_table_id, assigned_table_id), updated_at = now()
    WHERE id = p_reservation_id AND status IN ('PENDING', 'CONFIRMED');
END;
$$;

-- 4. get_reservation_stats
CREATE OR REPLACE FUNCTION public.get_reservation_stats(
    p_date date DEFAULT CURRENT_DATE
) RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total int;
    v_pending int;
    v_seated int;
    v_completed int;
BEGIN
    SELECT count(*),
           count(*) FILTER (WHERE status = 'PENDING'),
           count(*) FILTER (WHERE status = 'SEATED'),
           count(*) FILTER (WHERE status = 'COMPLETED')
    INTO v_total, v_pending, v_seated, v_completed
    FROM reservations
    WHERE reservation_time::date = p_date;

    RETURN json_build_object(
        'total', v_total,
        'pending', v_pending,
        'seated', v_seated,
        'completed', v_completed
    );
END;
$$;

-- 5. get_revenue_report
CREATE OR REPLACE FUNCTION public.get_revenue_report(
    p_start_date date,
    p_end_date date
) RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_revenue numeric;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO v_total_revenue
    FROM financial_transactions
    WHERE transaction_type = 'REVENUE' AND date_trunc('day', created_at)::date BETWEEN p_start_date AND p_end_date;
    
    RETURN json_build_object('total_revenue', v_total_revenue);
END;
$$;

-- 6. get_expense_report
CREATE OR REPLACE FUNCTION public.get_expense_report(
    p_start_date date,
    p_end_date date
) RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_expense numeric;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO v_total_expense
    FROM financial_transactions
    WHERE transaction_type = 'EXPENSE' AND date_trunc('day', created_at)::date BETWEEN p_start_date AND p_end_date;
    
    RETURN json_build_object('total_expense', v_total_expense);
END;
$$;

-- 7. get_profit_loss
CREATE OR REPLACE FUNCTION public.get_profit_loss(
    p_start_date date,
    p_end_date date
) RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_revenue numeric;
    v_expense numeric;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO v_revenue
    FROM financial_transactions
    WHERE transaction_type = 'REVENUE' AND date_trunc('day', created_at)::date BETWEEN p_start_date AND p_end_date;
    
    SELECT COALESCE(SUM(amount), 0) INTO v_expense
    FROM financial_transactions
    WHERE transaction_type = 'EXPENSE' AND date_trunc('day', created_at)::date BETWEEN p_start_date AND p_end_date;

    RETURN json_build_object(
        'revenue', v_revenue,
        'expense', v_expense,
        'profit', v_revenue - v_expense
    );
END;
$$;

-- 8. generate_tax_record
CREATE OR REPLACE FUNCTION public.generate_tax_record(
    p_period_start date,
    p_period_end date
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_revenue numeric;
    v_vat_collected numeric;
    v_tax_id uuid;
    v_branch_id uuid;
BEGIN
    SELECT id INTO v_branch_id FROM branches LIMIT 1;

    SELECT COALESCE(SUM(grand_total), 0), COALESCE(SUM(vat_amount), 0)
    INTO v_revenue, v_vat_collected
    FROM invoices
    WHERE created_at::date BETWEEN p_period_start AND p_period_end;

    INSERT INTO tax_records (branch_id, period_start, period_end, total_revenue, vat_collected, status)
    VALUES (v_branch_id, p_period_start, p_period_end, v_revenue, v_vat_collected, 'DRAFT')
    RETURNING id INTO v_tax_id;

    RETURN v_tax_id;
END;
$$;

-- 9. create_campaign
CREATE OR REPLACE FUNCTION public.create_campaign(
    p_name text,
    p_type text,
    p_start_date timestamptz,
    p_end_date timestamptz,
    p_budget numeric,
    p_config jsonb
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_campaign_id uuid;
BEGIN
    INSERT INTO campaigns (name, type, start_date, end_date, budget, status, config)
    VALUES (p_name, p_type, p_start_date, p_end_date, p_budget, 'DRAFT', p_config)
    RETURNING id INTO v_campaign_id;
    
    RETURN v_campaign_id;
END;
$$;

-- 10. submit_campaign_for_approval
CREATE OR REPLACE FUNCTION public.submit_campaign_for_approval(
    p_campaign_id uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE campaigns SET status = 'PENDING_APPROVAL', updated_at = now() WHERE id = p_campaign_id AND status = 'DRAFT';
END;
$$;

-- 11. approve_reject_campaign
CREATE OR REPLACE FUNCTION public.approve_reject_campaign(
    p_campaign_id uuid,
    p_is_approved boolean,
    p_approver_id uuid,
    p_notes text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF p_is_approved THEN
        UPDATE campaigns SET status = 'ACTIVE', updated_at = now() WHERE id = p_campaign_id;
    ELSE
        UPDATE campaigns SET status = 'REJECTED', updated_at = now() WHERE id = p_campaign_id;
    END IF;

    INSERT INTO bod_approvals (target_type, target_id, approver_id, status, notes)
    VALUES ('CAMPAIGN', p_campaign_id, p_approver_id, CASE WHEN p_is_approved THEN 'APPROVED' ELSE 'REJECTED' END, p_notes);
END;
$$;

-- 12. get_executive_dashboard
CREATE OR REPLACE FUNCTION public.get_executive_dashboard()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_revenue numeric;
    v_total_expense numeric;
    v_active_campaigns int;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO v_total_revenue FROM financial_transactions WHERE transaction_type = 'REVENUE';
    SELECT COALESCE(SUM(amount), 0) INTO v_total_expense FROM financial_transactions WHERE transaction_type = 'EXPENSE';
    SELECT count(*) INTO v_active_campaigns FROM campaigns WHERE status = 'ACTIVE';

    RETURN json_build_object(
        'revenue', v_total_revenue,
        'expense', v_total_expense,
        'active_campaigns', v_active_campaigns
    );
END;
$$;

-- 13. record_customer_feedback
CREATE OR REPLACE FUNCTION public.record_customer_feedback(
    p_order_id uuid,
    p_rating int,
    p_comment text DEFAULT NULL,
    p_customer_id uuid DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_feedback_id uuid;
    v_branch_id uuid;
BEGIN
    SELECT branch_id INTO v_branch_id FROM orders WHERE id = p_order_id;
    
    INSERT INTO customer_feedback (branch_id, order_id, customer_id, rating, comment)
    VALUES (v_branch_id, p_order_id, p_customer_id, p_rating, p_comment)
    RETURNING id INTO v_feedback_id;
    
    RETURN v_feedback_id;
END;
$$;
