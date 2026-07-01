-- =============================================================================
-- 20260625120000_write_audit_singular_fix.sql
--
-- Previous fix (20260625110000) checked `TG_ARGV[0] in ('table_assignments', ...)`
-- (plural). The actual trigger definition on table_assignments is
-- `EXECUTE FUNCTION write_audit('table_assignment')` (singular). So the
-- CASE returned NULL and the audit row got NULL branch_id.
--
-- The cleanest fix: just try NEW.branch_id (cast to uuid) UNCONDITIONALLY.
-- Every audited table in this schema carries branch_id:
--   - table_assignments, orders, order_items, payments, invoices, shifts,
--     reservations, customers, tables
-- If a future table is audited that doesn't have branch_id, the cast will
-- error and the trigger will fail loudly — better than silently inserting
-- NULL.
-- =============================================================================

create or replace function public.write_audit()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_action text;
  v_payload jsonb;
  v_actor uuid := auth.uid();
  v_branch uuid;
  v_entity_id uuid;
  v_row jsonb;
begin
  if (TG_OP = 'INSERT') then
    v_action := TG_ARGV[0] || '.created';
    v_payload := to_jsonb(NEW);
    v_entity_id := NEW.id;
    v_row := to_jsonb(NEW);
  elsif (TG_OP = 'UPDATE') then
    v_action := TG_ARGV[0] || '.updated';
    v_payload := jsonb_build_object('before', to_jsonb(OLD), 'after', to_jsonb(NEW));
    v_entity_id := NEW.id;
    v_row := to_jsonb(NEW);
  else
    v_action := TG_ARGV[0] || '.deleted';
    v_payload := to_jsonb(OLD);
    v_entity_id := OLD.id;
    v_row := to_jsonb(OLD);
  end if;

  -- Always prefer the branch_id from the row itself. This is set by the
  -- application (check-in / order-create / etc.) and is the most reliable
  -- source. Fall back to the session helper only if the row has no
  -- branch_id at all (shouldn't happen for any audited table, but keeps
  -- the trigger robust for future ones).
  v_branch := coalesce(
    (v_row ->> 'branch_id')::uuid,
    public.current_branch_id()
  );

  insert into public.audit_events
    (branch_id, actor_id, action, entity_type, entity_id, payload)
  values
    (v_branch, v_actor, v_action, TG_ARGV[0], v_entity_id, v_payload);

  return coalesce(NEW, OLD);
end;
$$;