import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { DEFAULT_BRANCH_ID } from '@/lib/branch-constants'
import type { Session, Subscription } from '@supabase/supabase-js'
import type { AppUser, UserRole } from '@/types/database'

// =============================================================================
// useAuth — Centralised Supabase auth state for the Vue app.
//
// Senior full-stack review (2026-06-25) — what this file MUST do:
//
//   1. Never invent / verify / decode JWTs in the frontend.
//      Every authorization decision comes from Supabase Auth or from
//      `public.users`. The JWT itself is opaque to us — we just attach it.
//
//   2. Never use `supabase.auth.getSession()` for authorization.
//      `getSession()` reads from localStorage and can be stale; only
//      `getUser()` re-validates against GoTrue. We use `getUser()` for
//      meaningful checks and treat `getSession()` purely as "is there a
//      token in storage right now".
//
//   3. Use only the publishable / anon key. The service_role key is never
//      loaded into the browser bundle (VITE_* vars are inlined at build).
//
//   4. Role + branch authorization MUST come from `app_metadata` (set by
//      the custom_access_token_hook on login) or from `public.users` —
//      never from `user_metadata` (which any signed-in user can edit via
//      `auth.updateUser()` and is therefore attacker-controlled).
//
//   5. signIn() must `await fetchProfile(userId)` before returning. The
//      router guard and LoginView both gate on `role.value`, so leaving the
//      function before the profile is in state is a race that ships
//      users to the wrong portal (or to a 403).
//
//   6. signOut() must use `scope: 'local'` so we don't nuke a session the
//      user might have open in another tab; clear mock storage and reset
//      local reactive state regardless.
//
//   7. Mock login is a developer affordance. It is allowed ONLY when the
//      project URL is a placeholder (no real backend configured) OR the
//      caller explicitly opted in via VITE_ENABLE_MOCK_AUTH=true. Falling
//      back to mock login on a transient network failure against a real
//      project is dangerous: it would log the user in with no password
//      check. The previous code did this — it no longer does.
// =============================================================================

// Module-scoped state — survives across `useAuth()` calls (Pinia-style singleton).
const session = ref<Session | null>(null)
const profile = ref<AppUser | null>(null)
const loading = ref<boolean>(true)
const initialized = ref<boolean>(false)
let authListener: Subscription | null = null

// ─── Mock auth gate ──────────────────────────────────────────────────────────
function isMockAuthAllowed(): boolean {
  const url = import.meta.env.VITE_SUPABASE_URL ?? ''
  const isPlaceholder = !url || url.includes('placeholder') || url.includes('<project-ref>')
  const explicitlyEnabled = import.meta.env.VITE_ENABLE_MOCK_AUTH === 'true'
  // Placeholder URL = no real backend yet, mock is the only way to develop.
  // Explicit flag = developer consciously opted in. Anything else → real auth.
  return isPlaceholder || explicitlyEnabled
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function clearMockStorage() {
  localStorage.removeItem('ngu-cat.mock-session')
  localStorage.removeItem('ngu-cat.mock-profile')
}

/**
 * Read role + branch_id from the JWT's `app_metadata`. This is what the
 * `custom_access_token_hook` writes on every login + refresh, so reading
 * from here is the fastest path (no DB round-trip) and is safe (signed).
 *
 * `user_metadata` is intentionally NOT read. It's user-editable.
 */
function readClaimsFromSession(s: Session | null): {
  role: UserRole | undefined
  branchId: string | undefined
} {
  const claims = s?.user?.app_metadata ?? {}
  const role = claims.role as UserRole | undefined
  const branchId = claims.branch_id as string | undefined
  return { role, branchId }
}

/**
 * Map a `public.users.role` row → our `UserRole` enum, normalising case.
 * The DB enum is already validated, but a defensive cast catches any drift
 * if someone manually inserts a row.
 */
function normaliseRole(raw: unknown): UserRole | undefined {
  const r = String(raw ?? '').toLowerCase()
  if (r === 'superadmin') {
    return 'admin'
  }
  const validRoles: UserRole[] = [
    'admin',
    'manager',
    'reception',
    'staff',
    'kitchen',
    'purchasing',
    'accounting',
    'crm',
    'marketing',
    'bod',
    'tablet',
    'customer'
  ]
  if (validRoles.includes(r as UserRole)) {
    return r as UserRole
  }
  return undefined
}

// ─── Mock login (dev only) ──────────────────────────────────────────────────

function performMockLogin(email: string) {
  const cleanEmail = email.trim().toLowerCase()
  let detectedRole: UserRole = 'staff'
  if (cleanEmail.startsWith('admin')) detectedRole = 'admin'
  else if (cleanEmail.startsWith('manager')) detectedRole = 'manager'
  else if (cleanEmail.startsWith('reception')) detectedRole = 'reception'
  else if (cleanEmail.startsWith('staff')) detectedRole = 'staff'
  else if (cleanEmail.startsWith('kitchen')) detectedRole = 'kitchen'

  const mockUser: AppUser = {
    id: 'mock-id-' + detectedRole,
    // IMPORTANT: branch_id here MUST be a UUID (the DB column type). Using
    // 'B001' (text code) would 22P02 any query that filters on it.
    branch_id: DEFAULT_BRANCH_ID,
    full_name: detectedRole.charAt(0).toUpperCase() + detectedRole.slice(1) + ' User',
    email: cleanEmail,
    phone: '0909123456',
    role: detectedRole,
    is_active: true,
    preferences: {},
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  }

  // Mock JWT shape mirrors what the real hook would produce, so downstream
  // code that reads `app_metadata.role` / `app_metadata.branch_id` works
  // identically in dev and prod.
  const sessionData = {
    access_token: 'mock-access-token',
    token_type: 'bearer',
    expires_in: 3600,
    refresh_token: 'mock-refresh-token',
    user: {
      id: mockUser.id,
      aud: 'authenticated',
      email: mockUser.email,
      created_at: mockUser.created_at,
      app_metadata: {
        role: detectedRole,
        branch_id: DEFAULT_BRANCH_ID,
        mock: true,
      },
      user_metadata: {},
    },
  }
  session.value = sessionData as any
  profile.value = mockUser
  loading.value = false

  localStorage.setItem('ngu-cat.mock-session', JSON.stringify(sessionData))
  localStorage.setItem('ngu-cat.mock-profile', JSON.stringify(mockUser))
}

function restoreMockSession(): boolean {
  const savedSession = localStorage.getItem('ngu-cat.mock-session')
  const savedProfile = localStorage.getItem('ngu-cat.mock-profile')
  if (!savedSession || !savedProfile) return false
  try {
    session.value = JSON.parse(savedSession)
    profile.value = JSON.parse(savedProfile)
    return true
  } catch {
    clearMockStorage()
    return false
  }
}

// ─── Real auth: fetch profile + assert active ───────────────────────────────

/**
 * Load `public.users` for the given auth user id. Returns the profile or
 * throws if the user is missing / inactive (signOut will be called by the
 * caller so the user is left in a logged-out state, not stuck in limbo).
 */
async function fetchProfile(userId: string): Promise<AppUser> {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .maybeSingle<AppUser>()

  if (error) {
    throw new Error(`Không truy vấn được hồ sơ: ${error.message}`)
  }
  if (!data) {
    throw new Error('Tài khoản chưa có hồ sơ trong hệ thống. Liên hệ admin.')
  }
  if (data.is_active === false) {
    throw new Error('Tài khoản đã bị vô hiệu hoá. Liên hệ admin.')
  }
  // Normalise role from DB row (defensive — the column has a CHECK constraint
  // but we don't trust the wire format unconditionally).
  const normalised = normaliseRole(data.role)
  if (!normalised) {
    throw new Error(`Role không hợp lệ: '${data.role}'. Liên hệ admin.`)
  }
  return { ...data, role: normalised }
}

// ─── Public composable ──────────────────────────────────────────────────────

export function useAuth() {
  async function init() {
    if (initialized.value) return
    initialized.value = true

    if (isMockAuthAllowed()) {
      // Dev / placeholder mode: try to restore a previous mock session,
      // otherwise the user starts logged out and must call signIn().
      restoreMockSession()
      loading.value = false
      return
    }

    // Real Supabase mode
    try {
      const { data: { session: current } } = await supabase.auth.getSession()
      session.value = current
      if (current?.user) {
        try {
          profile.value = await fetchProfile(current.user.id)
        } catch (e) {
          // Profile missing or inactive → log out so we don't leave the
          // user stuck on a half-initialised state.
          console.warn('[useAuth] fetchProfile failed during init:', e)
          await safeSignOut()
        }
      }
    } catch (error) {
      console.error('[useAuth] Failed to initialize session:', error)
    } finally {
      loading.value = false
    }

    // Subscribe to auth events AFTER init to avoid stomping our own state.
    try {
      authListener = supabase.auth.onAuthStateChange(async (_event, newSession) => {
        session.value = newSession
        if (newSession?.user) {
          try {
            profile.value = await fetchProfile(newSession.user.id)
          } catch (e) {
            console.warn('[useAuth] fetchProfile failed on auth change:', e)
            profile.value = null
          }
        } else {
          profile.value = null
        }
      }).data.subscription
    } catch (error) {
      console.error('[useAuth] Failed to subscribe to auth state changes:', error)
    }
  }

  /**
   * Sign in with email + password.
   *
   * Race-condition fix (2026-06-25 review): previously this function
   * returned immediately after `signInWithPassword` succeeded, leaving the
   * router guard to discover `profile.value === null` and bounce the user
   * to /login. Now we `await fetchProfile(user.id)` and only return once
   * `role.value` / `branchId.value` are populated.
   *
   * If the profile is missing or `is_active=false`, we signOut() the
   * half-session and throw a clear error — never leave the user logged in
   * without a profile (that would let them hit RLS walls later).
   */
  async function signIn(email: string, password: string): Promise<void> {
    if (isMockAuthAllowed()) {
      performMockLogin(email)
      return
    }

    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error

    const user = data.user
    const newSession = data.session
    if (!user || !newSession) {
      throw new Error('Đăng nhập thất bại: phản hồi không hợp lệ từ máy chủ')
    }

    // Sync state immediately so the router guard doesn't bounce.
    session.value = newSession

    // Load profile synchronously so the caller can `router.push(roleHome)`
    // without racing the auth listener.
    try {
      profile.value = await fetchProfile(user.id)
    } catch (e) {
      // Profile missing / inactive → tear down the session so we don't
      // leave a half-authenticated ghost.
      await safeSignOut()
      throw e
    }
  }

  /**
   * Sign out the current session. Uses `scope: 'local'` so we don't kill
   * sessions the user might have open in other tabs / apps sharing the
   * same auth storage. Mock storage + local reactive state are always
   * cleared regardless of whether the Supabase call succeeds.
   */
  async function signOut(): Promise<void> {
    await safeSignOut()
  }

  async function safeSignOut() {
    clearMockStorage()
    try {
      // `local` scope = only this tab/session. 'global' would invalidate
      // ALL sessions for this user across devices, which we never want
      // from a single "log out" click.
      await supabase.auth.signOut({ scope: 'local' })
    } catch (e) {
      console.warn('[useAuth] Supabase signOut error (continuing):', e)
    }
    session.value = null
    profile.value = null
  }

  async function getCurrentUser() {
    // `getUser()` re-validates the token against GoTrue. Use this when you
    // need to be SURE the user is still authorised, not just "has a token
    // in localStorage". Never use `getSession()` for authorization.
    const { data: { user }, error } = await supabase.auth.getUser()
    if (error) throw error
    return user
  }

  // ─── Reactive selectors ────────────────────────────────────────────────

  const role = computed<UserRole | undefined>(() => {
    // Prefer app_metadata.role from the JWT (set by the hook → signed →
    // can't be tampered with). Fall back to the public.users row.
    const fromClaims = readClaimsFromSession(session.value).role
    const fromProfile = normaliseRole(profile.value?.role)
    return fromClaims ?? fromProfile
  })

  const branchId = computed<string | undefined>(() => {
    // Same priority: signed JWT claim wins, then the DB row, then nothing.
    const fromClaims = readClaimsFromSession(session.value).branchId
    const fromProfile = profile.value?.branch_id ?? undefined
    return fromClaims ?? fromProfile ?? undefined
  })

  const isAuthenticated = computed<boolean>(() => !!session.value && !!profile.value)
  const isAdmin = computed<boolean>(() => role.value === 'admin')
  const isManager = computed<boolean>(
    () => role.value === 'admin' || role.value === 'manager',
  )

  return {
    session,
    profile,
    loading,
    role,
    branchId,
    isAuthenticated,
    isAdmin,
    isManager,
    signIn,
    signOut,
    getCurrentUser,
    init,
  }
}

/**
 * Auto-init helper for main.ts. Returns nothing; just guarantees init runs.
 */
export function bootstrapAuth() {
  const auth = useAuth()
  onMounted(() => auth.init())
  onUnmounted(() => {
    authListener?.unsubscribe()
    authListener = null
  })
}
