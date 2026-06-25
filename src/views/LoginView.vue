<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuth } from '@/composables/useAuth'
import { getHomeRouteForRole } from '@/utils/route'

const router = useRouter()
const { t } = useI18n()
const { signIn, loading: authLoading, isAuthenticated, role } = useAuth()

const form = reactive({
  email: '',
  password: '',
})

const submitting = ref(false)
const errorMsg = ref<string | null>(null)

const canSubmit = computed(
  () => !!form.email && !!form.password && !submitting.value,
)

async function onSubmit() {
  if (!canSubmit.value) return
  submitting.value = true
  errorMsg.value = null
  try {
    await signIn(form.email.trim(), form.password)
    // Role-aware landing — admin → /admin/dashboard, staff → /staff/floor-plan, etc.
    await router.push(getHomeRouteForRole(role.value))
  } catch (e) {
    errorMsg.value = e instanceof Error ? e.message : String(e)
  } finally {
    submitting.value = false
  }
}

void isAuthenticated
void authLoading
void t
</script>

<template>
  <div class="login-shell">
    <div class="login-card relative">
      
      <div class="flex justify-center items-center gap-4 mb-6">
        <img src="/images/nguucat-logo.png" alt="Ngưu Cát" class="h-16 w-auto object-contain" />
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
          <input
            v-model="form.password"
            type="password"
            autocomplete="current-password"
            required
          />
        </label>

        <p v-if="errorMsg" class="login-error">{{ errorMsg }}</p>

        <button
          type="submit"
          class="login-submit"
          :disabled="!canSubmit"
        >
          {{ submitting ? 'Signing in…' : 'Sign in' }}
        </button>

        <p class="login-hint">
          Tài khoản được cấp bởi quản lý. Liên hệ admin nếu chưa có.
        </p>
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
  width: 360px;
  padding: 32px;
  border-radius: 16px;
  background: white;
  box-shadow: 0 8px 32px rgba(44, 62, 80, 0.08);
}
.login-title {
  font-size: 28px;
  font-weight: 800;
  text-align: center;
  color: #2c3e50;
}
.login-subtitle {
  text-align: center;
  margin: 0 0 24px;
  color: #64748b;
}
.login-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
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

