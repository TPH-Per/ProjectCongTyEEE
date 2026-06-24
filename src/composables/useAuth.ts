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

  async function init() {
    if (initialized.value) return
    initialized.value = true

    const { data: { session: current } } = await supabase.auth.getSession()
    session.value = current
    if (current?.user) {
      await fetchProfile(current.user.id)
    }
    loading.value = false

    authListener = supabase.auth.onAuthStateChange(async (_event, newSession) => {
      session.value = newSession
      if (newSession?.user) {
        await fetchProfile(newSession.user.id)
      } else {
        profile.value = null
      }
    }).data.subscription
  }

  async function signIn(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  async function signOut() {
    await supabase.auth.signOut()
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
