import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ??
  import.meta.env.VITE_SUPABASE_ANON_KEY

const isConfigured = !!(
  supabaseUrl &&
  supabaseAnonKey &&
  /^https:\/\/[a-z0-9-]+\.supabase\.co\/?$/.test(supabaseUrl)
)

if (!isConfigured) {
  console.warn(
    '[supabase] VITE_SUPABASE_URL / VITE_SUPABASE_PUBLISHABLE_KEY chưa cấu hình hoặc sai định dạng. ' +
      'App sẽ chạy ở chế độ offline (mock data). Tạo .env.local để kết nối Supabase thật.',
  )
}

/**
 * Khi chưa cấu hình Supabase, tạo một client placeholder với URL/key giả.
 * Mọi gọi API sẽ fail gracefully (trả error) thay vì crash toàn bộ app.
 * Điều này cho phép UI tĩnh hoạt động để test frontend mà không cần backend.
 */
export const supabase = createClient<any>(
  supabaseUrl || 'https://placeholder.supabase.co',
  supabaseAnonKey || 'placeholder-anon-key',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
    realtime: {
      params: { eventsPerSecond: 10 },
    },
  },
)

export const isSupabaseConfigured = isConfigured
