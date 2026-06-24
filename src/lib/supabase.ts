import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ??
  import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'Missing VITE_SUPABASE_URL or VITE_SUPABASE_PUBLISHABLE_KEY in .env.local',
  )
}

// Guard against the common typo where someone copies the PostgREST URL
// (https://<ref>.supabase.co/rest/v1/) instead of the project URL. The JS
// SDK appends `/auth/v1/...` and `/rest/v1/...` internally, so any suffix
// would make every API call return 404. Fail fast on import.
if (!/^https:\/\/[a-z0-9-]+\.supabase\.co\/?$/.test(supabaseUrl)) {
  throw new Error(
    `Invalid VITE_SUPABASE_URL "${supabaseUrl}". ` +
      'Expected format: https://<project-ref>.supabase.co (no /rest/v1/ or /auth/v1/ suffix).',
  )
}

export const supabase = createClient<any>(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
  realtime: {
    params: { eventsPerSecond: 10 },
  },
})
