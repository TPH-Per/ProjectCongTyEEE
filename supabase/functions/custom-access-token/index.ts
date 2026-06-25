// supabase/functions/custom-access-token/index.ts
//
// RETIRED — do NOT enable this in Supabase Dashboard.
//
// As of the auth-flow audit on 2026-06-25, the Custom Access Token hook is
// implemented as a Postgres Database Function
// (`public.custom_access_token_hook`), NOT as an Edge Function.
//
// Why:
//   1. Single source of truth — every claim lives in one place (the DB row
//      in `public.users`), and the hook reads it transactionally with login.
//   2. Latency — DB functions are in-process; Edge Functions add a network
//      hop and a cold-start risk.
//   3. Security — the DB function runs as `supabase_auth_admin` which has
//      explicit grants on `public.users`. An Edge Function variant would
//      need the service-role key baked into the runtime, which is a much
//      bigger attack surface.
//
// If you accidentally enable this Edge Function as the hook in Dashboard:
//   Authentication → Hooks → Custom Access Token → Type → change from
//   "Edge Function" to "Database Function" → select
//   `public.custom_access_token_hook`.
//
// This file returns 410 Gone so a misconfigured deployment surfaces a loud
// failure instead of silently dropping claims.

Deno.serve(() =>
  new Response(
    JSON.stringify({
      error: 'gone',
      message:
        'Custom access token hook is implemented as public.custom_access_token_hook (Postgres function), not as an Edge Function. Update Supabase Dashboard → Authentication → Hooks → Custom Access Token → Type → Database Function.',
    }),
    { status: 410, headers: { 'Content-Type': 'application/json' } },
  ),
)
