<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuth } from '@/composables/useAuth'
import { getHomeRouteForRole } from '@/utils/route'
import { Eye, EyeOff } from 'lucide-vue-next'
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'

const router = useRouter()
const { t } = useI18n()
const { signIn, profile, role, isAuthenticated } = useAuth()

const form = reactive({
  email: '',
  password: '',
})

const submitting = ref(false)
const errorMsg = ref<string | null>(null)
const showPassword = ref(false)
const rememberMe = ref(true)

// Persisted credentials are stored under these keys so the form
// re-hydrates the next time the user opens /login on the same browser.
// SECURITY: we deliberately store ONLY the email — passwords are NEVER
// cached to localStorage. The "remember me" flag controls whether the
// email is pre-filled, not whether the password is replayed.
const REMEMBER_KEY = 'nguucat.login.rememberedEmail'
const REMEMBER_FLAG = 'nguucat.login.remember'

const canSubmit = computed(
  () => !!form.email && !!form.password && !submitting.value,
)

onMounted(() => {
  // Re-hydrate the email from localStorage if the user previously
  // checked "Ghi nhớ đăng nhập". The password stays blank by design.
  try {
    const flag = localStorage.getItem(REMEMBER_FLAG) === '1'
    const saved = localStorage.getItem(REMEMBER_KEY)
    if (flag && saved) {
      form.email = saved
      rememberMe.value = true
    } else {
      rememberMe.value = false
    }
  } catch {
    // localStorage may be unavailable (private mode, SSR, …) — fall
    // back to the default state and surface nothing.
  }
})

async function onSubmit() {
  if (!canSubmit.value) return
  submitting.value = true
  errorMsg.value = null
  try {
    // signIn() now awaits fetchProfile internally — by the time it
    // returns, `profile` and `role` are populated and we can route
    // without a race. If the profile is missing or is_active=false,
    // signIn throws and the session is torn down, so
    // isAuthenticated will be false here.
    await signIn(form.email.trim(), form.password)

    if (!isAuthenticated.value || !profile.value || !role.value) {
      // Defensive: should be unreachable because signIn throws in
      // this case. Keeps the redirect safe if a future refactor
      // breaks the contract.
      errorMsg.value = 'Đăng nhập thất công: hồ sơ chưa sẵn sàng. Vui lòng thử lại.'
      return
    }

    // Persist (or clear) the remembered email BEFORE we navigate away.
    try {
      if (rememberMe.value) {
        localStorage.setItem(REMEMBER_FLAG, '1')
        localStorage.setItem(REMEMBER_KEY, form.email.trim())
      } else {
        localStorage.removeItem(REMEMBER_FLAG)
        localStorage.removeItem(REMEMBER_KEY)
      }
    } catch {
      // Ignore — failing to persist is non-fatal.
    }

    // Role-aware landing — admin → /admin/dashboard, staff → /staff/floor-plan, …
    await router.push(getHomeRouteForRole(role.value))
  } catch (e) {
    errorMsg.value = e instanceof Error ? e.message : String(e)
  } finally {
    submitting.value = false
  }
}

void t
</script>

<template>
  <div class="login-shell relative">
    <div class="absolute top-6 right-6">
      <LanguageSwitcher />
    </div>
    <div class="login-card relative">

      <!--
        Brand: now text-only (t('login.nguu_cat_1') in the Cormorant Garamond
        premium serif) with the Vietnamese subtitle. The previous
        gradient orb has been removed per UX feedback — admins said
        the orb read as a low-resolution orange blob and didn't carry
        the brand name. The wordmark stays crisp at every DPI and
        renders identically in every browser.
      -->
      <div class="brand-header">
        <h1 class="brand-title">{{ $t('login.nguu_cat') }}</h1>
        <p class="brand-subtitle">{{ $t('login.he_thong_quan_ly') }}</p>
      </div>

      <form @submit.prevent="onSubmit" class="login-form">
        <label class="login-field">
          <span>Email</span>
          <input
            v-model="form.email"
            type="email"
            autocomplete="email"
            required
            placeholder="admin@nguucat.vn"
          />
        </label>

        <label class="login-field">
          <span>Password</span>
          <div class="login-password-wrap">
            <input
              v-model="form.password"
              :type="showPassword ? 'text' : 'password'"
              autocomplete="current-password"
              required
              class="login-password-input"
            />
            <button
              type="button"
              class="login-password-toggle"
              :aria-label="showPassword ? $t('login.an_mat_khau') : $t('login.hien_mat_khau')"
              :title="showPassword ? $t('login.an_mat_khau') : $t('login.hien_mat_khau')"
              @click="showPassword = !showPassword"
            >
              <EyeOff v-if="showPassword" :size="18" />
              <Eye v-else :size="18" />
            </button>
          </div>
        </label>

        <label class="login-remember">
          <input
            v-model="rememberMe"
            type="checkbox"
            class="login-remember-checkbox"
          />
          <span>{{ $t('login.ghi_nho_dang_nhap') }}</span>
        </label>

        <p v-if="errorMsg" class="login-error">{{ errorMsg }}</p>

        <button
          type="submit"
          class="login-submit"
          :disabled="!canSubmit"
        >
          {{ submitting ? 'Signing in…' : 'Sign in' }}
        </button>

        <p class="login-hint">{{ $t('login.tai_khoan_duoc_cap') }}</p>
      </form>
    </div>
  </div>
</template>

<style scoped>
.login-shell {
  min-height: 100vh;
  display: grid;
  place-items: center;
  background: #FFF8F5;
}
.login-card {
  width: 380px;
  padding: 36px 32px 32px;
  border-radius: 18px;
  background: white;
  box-shadow: 0 8px 32px rgba(44, 62, 80, 0.08);
}
.brand-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 24px;
}
.brand-title {
  margin: 0;
  /* Premium serif — registered as `font-brand` in tailwind.config.ts
     and also loaded directly via Google Fonts in index.html. */
  font-family: 'Cormorant Garamond', 'Playfair Display', Georgia, serif;
  font-weight: 700;
  font-size: 36px;
  letter-spacing: 0.06em;
  line-height: 1;
  text-align: center;
  background: linear-gradient(135deg, #FF8E61 0%, #FF672E 100%);
  -webkit-background-clip: text;
          background-clip: text;
  -webkit-text-fill-color: transparent;
          color: transparent;
}
.brand-subtitle {
  margin: 10px 0 0;
  text-align: center;
  color: #64748b;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.18em;
  text-transform: uppercase;
}
.login-form {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.login-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 14px;
  color: #2c3e50;
}
.login-field input {
  padding: 10px 12px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  font-size: 14px;
}
.login-field input:focus {
  outline: none;
  border-color: #FF672E;
  box-shadow: 0 0 0 3px rgba(255, 103, 46, 0.12);
}
.login-password-wrap {
  position: relative;
  display: flex;
  align-items: center;
}
.login-password-input {
  width: 100%;
  padding-right: 40px; /* leave room for the eye toggle */
}
.login-password-toggle {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  color: #64748b;
  cursor: pointer;
  border-radius: 6px;
  transition: background-color 120ms ease, color 120ms ease;
}
.login-password-toggle:hover {
  background: #f1f5f9;
  color: #FF672E;
}
.login-password-toggle:focus-visible {
  outline: 2px solid #FF672E;
  outline-offset: 1px;
}
.login-remember {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #475569;
  cursor: pointer;
  user-select: none;
  margin-top: -2px;
}
.login-remember-checkbox {
  width: 16px;
  height: 16px;
  accent-color: #FF672E;
  cursor: pointer;
}
.login-error {
  margin: 0;
  padding: 8px 12px;
  border-radius: 8px;
  background: #fee2e2;
  color: #b91c1c;
  font-size: 13px;
}
.login-submit {
  margin-top: 8px;
  padding: 12px;
  border-radius: 10px;
  border: none;
  background: #FF672E;
  color: white;
  font-weight: 700;
  font-size: 15px;
  cursor: pointer;
  transition: background-color 120ms ease;
}
.login-submit:hover:not(:disabled) {
  background: #F54C0D;
}
.login-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.login-hint {
  margin: 0;
  text-align: center;
  font-size: 12px;
  color: #64748b;
  font-style: italic;
}
</style>