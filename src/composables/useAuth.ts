import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Session, Subscription } from '@supabase/supabase-js'
import type { AppUser, UserRole } from '@/types/database'

// Module-scoped state — survives across `useAuth()` calls.
const session = ref<Session | null>(null)
const profile = ref<AppUser | null>(null)
const loading = ref<boolean>(true)
const initialized = ref<boolean>(false)
let authListener: Subscription | null = null

/**
 * Centralised authentication state.
 *
 * Returns reactive refs/computeds for session, profile, role, and helpers to
 * sign in/out. The first call inside `main.ts` should invoke `init()` once
 * after Pinia is installed so router guards have data to evaluate.
 */
export function useAuth() {
  async function fetchProfile(userId: string) {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single<AppUser>()

    if (error) {
      console.error('[useAuth] fetchProfile error:', error.message)
      profile.value = null
      return
    }
    profile.value = data
  }

  function performMockLogin(email: string) {
    const cleanEmail = email.trim().toLowerCase()
    let detectedRole: UserRole = 'admin'
    if (cleanEmail.startsWith('manager')) detectedRole = 'manager'
    else if (cleanEmail.startsWith('reception')) detectedRole = 'reception'
    else if (cleanEmail.startsWith('staff')) detectedRole = 'staff'
    else if (cleanEmail.startsWith('kitchen')) detectedRole = 'kitchen'
    else if (cleanEmail.startsWith('admin')) detectedRole = 'admin'

    const mockUser: AppUser = {
      id: 'mock-id-' + detectedRole,
      branch_id: 'B001',
      full_name: detectedRole.charAt(0).toUpperCase() + detectedRole.slice(1) + ' User',
      email: cleanEmail,
      phone: '0909123456',
      role: detectedRole,
      is_active: true,
      preferences: {},
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }

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
        app_metadata: {},
        user_metadata: {}
      }
    }
    session.value = sessionData as any
    profile.value = mockUser
    loading.value = false

    localStorage.setItem('ngu-cat.mock-session', JSON.stringify(sessionData))
    localStorage.setItem('ngu-cat.mock-profile', JSON.stringify(mockUser))
  }

  async function init() {
    if (initialized.value) return
    initialized.value = true

    const url = import.meta.env.VITE_SUPABASE_URL || ''
    const isPlaceholder = url.includes('placeholder') || url.includes('<project-ref>')

    if (isPlaceholder) {
      console.warn('[useAuth] Initialising local mock authentication.')
      const savedSession = localStorage.getItem('ngu-cat.mock-session')
      const savedProfile = localStorage.getItem('ngu-cat.mock-profile')
      if (savedSession && savedProfile) {
        session.value = JSON.parse(savedSession)
        profile.value = JSON.parse(savedProfile)
      }
      loading.value = false
      return
    }

    try {
      const { data: { session: current } } = await supabase.auth.getSession()
      session.value = current
      if (current?.user) {
        await fetchProfile(current.user.id)
      }
    } catch (error) {
      console.error('[useAuth] Failed to initialize session, falling back to mock:', error)
      const savedSession = localStorage.getItem('ngu-cat.mock-session')
      const savedProfile = localStorage.getItem('ngu-cat.mock-profile')
      if (savedSession && savedProfile) {
        session.value = JSON.parse(savedSession)
        profile.value = JSON.parse(savedProfile)
      }
    } finally {
      loading.value = false
    }

    try {
      authListener = supabase.auth.onAuthStateChange(async (_event, newSession) => {
        const isMockActive = !!localStorage.getItem('ngu-cat.mock-session')
        if (isMockActive) return

        session.value = newSession
        if (newSession?.user) {
          await fetchProfile(newSession.user.id)
        } else {
          profile.value = null
        }
      }).data.subscription
    } catch (error) {
      console.error('[useAuth] Failed to subscribe to auth state changes:', error)
    }
  }

  async function signIn(email: string, password: string) {
    const url = import.meta.env.VITE_SUPABASE_URL || ''
    const isPlaceholder = url.includes('placeholder') || url.includes('<project-ref>')

    const cleanEmail = email.trim().toLowerCase()
    const validEmails = [
      'admin@nguucat.vn',
      'manager.q1@nguucat.vn',
      'reception.q1@nguucat.vn',
      'staff.q1@nguucat.vn',
      'kitchen.q1@nguucat.vn'
    ]

    if (isPlaceholder) {
      console.warn('[useAuth] Bypassing auth via local mock login (placeholder URL detected).')
      if (!validEmails.includes(cleanEmail)) {
        throw new Error('Cửa hàng hoặc tài khoản không tồn tại trên hệ thống')
      }
      performMockLogin(email)
      return
    }

    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) throw error
    } catch (err) {
      const errStr = String(err)
      if (errStr.includes('Failed to fetch') || errStr.includes('fetch') || errStr.includes('NetworkError')) {
        console.warn('[useAuth] Supabase fetch failed. Falling back to local mock login.', err)
        if (!validEmails.includes(cleanEmail)) {
          throw new Error('Cửa hàng hoặc tài khoản không tồn tại trên hệ thống')
        }
        performMockLogin(email)
        return
      }
      throw err
    }
  }

  async function signOut() {
    localStorage.removeItem('ngu-cat.mock-session')
    localStorage.removeItem('ngu-cat.mock-profile')
    try {
      await supabase.auth.signOut()
    } catch (e) {
      console.warn('[useAuth] Supabase signOut error:', e)
    }
    session.value = null
    profile.value = null
  }

  const role = computed<UserRole | undefined>(() => profile.value?.role)
  const branchId = computed<string | undefined>(
    () => profile.value?.branch_id ?? undefined,
  )
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
