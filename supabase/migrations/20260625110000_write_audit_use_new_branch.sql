-- =============================================================================
-- 20260625110000_write_audit_use_new_branch.sql
--
-- The `write_audit` trigger on table_assignments / orders / order_items /
-- payments / invoices / shifts / reservations reads branch_id via
-- `public.current_branch_id()`. That helper depends on either:
--   (a) `request.jwt.claims` being set on the session, or
--   (b) `auth.uid()` returning a real user.
--
-- Edge Functions run with the service role — NEITHER is available:
--   - `request.jwt.claims` is empty (no JWT context)
--   - `auth.uid()` is NULL (no authenticated user)
--
-- We tried to fix this in check-in by calling `set_config('request.jwt.claims', ...)`
-- before inserts, but PostgREST connection pooling means that RPC runs on a
-- different connection than the subsequent INSERT — the config is gone.
--
-- Better fix: the row being inserted ALREADY carries branch_id (every audited
-- table in this schema does). Read it straight from NEW instead of relying on
-- session config. This works for every caller (Edge Function, RLS user, admin).
--
-- Fallback order: NEW.branch_id → current_branch_id() → NULL (will fail the
-- NOT NULL audit_events constraint, which is the correct behavior — caller
-- MUST provide branch_id on the row).
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
begin
  -- Prefer the branch_id from the row being inserted/updated/deleted.
  -- Falls back to the session helper for tables that may not have branch_id.
  if (TG_OP = 'INSERT') then
    v_action := TG_ARGV[0] || '.created';
    v_payload := to_jsonb(NEW);
    v_entity_id := NEW.id;
    v_branch := coalesce(
      (case when TG_ARGV[0] in ('table_assignments','orders','order_items','payments','invoices','shifts','reservations','customers','tables')
            then (NEW.branch_id)::uuid end),
      public.current_branch_id()
    );
  elsif (TG_OP = 'UPDATE') then
    v_action := TG_ARGV[0] || '.updated';
    v_payload := jsonb_build_object('before', to_jsonb(OLD), 'after', to_jsonb(NEW));
    v_entity_id := NEW.id;
    v_branch := coalesce(
      (case when TG_ARGV[0] in ('table_assignments','orders','order_items','payments','invoices','shifts','reservations','customers','tables')
            then (NEW.branch_id)::uuid end),
      public.current_branch_id()
    );
  else
    v_action := TG_ARGV[0] || '.deleted';
    v_payload := to_jsonb(OLD);
    v_entity_id := OLD.id;
    v_branch := coalesce(
      (case when TG_ARGV[0] in ('table_assignments','orders','order_items','payments','invoices','shifts','reservations','customers','tables')
            then (OLD.branch_id)::uuid end),
      public.current_branch_id()
    );
  end if;

  insert into public.audit_events
    (branch_id, actor_id, action, entity_type, entity_id, payload)
  values
    (v_branch, v_actor, v_action, TG_ARGV[0], v_entity_id, v_payload);

  return coalesce(NEW, OLD);
end;
$$;