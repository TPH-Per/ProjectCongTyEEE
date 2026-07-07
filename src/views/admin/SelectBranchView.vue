<script setup lang="ts">
import { useI18nStore } from '@/stores/i18n'

const i18n = useI18nStore()
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useBranch } from '@/composables/useBranch'
import { getHomeRouteForRole } from '@/utils/route'
import type { Branch } from '@/types/database'
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import { Store } from 'lucide-vue-next'

const router = useRouter()
const { role } = useAuth()
const { selectBranch, listBranches } = useBranch()



const branches = ref<Branch[]>([])
const loading = ref(true)
const errorMsg = ref<string | null>(null)
const submitting = ref(false)

onMounted(async () => {
  try {
    branches.value = await listBranches()
  } catch (e) {
    errorMsg.value = e instanceof Error ? e.message : String(e)
  } finally {
    loading.value = false
  }
})

async function onSelectBranch(id: string) {
  if (submitting.value) return
  submitting.value = true
  try {
    selectBranch(id)
    if (role.value) {
      await router.push(getHomeRouteForRole(role.value))
    } else {
      await router.push('/')
    }
  } catch (e) {
    errorMsg.value = e instanceof Error ? e.message : String(e)
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="select-branch-shell relative">
    <div class="absolute top-6 right-6">
      <LanguageSwitcher />
    </div>
    <div class="select-branch-card relative">
      <div class="brand-header">
        <h1 class="brand-title">{{ i18n.t('select_branch.brand_title') }}</h1>
        <p class="brand-subtitle">{{ i18n.t('select_branch.choose_branch') }}</p>
      </div>

      <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>

      <div v-if="loading" class="loading-state">
        {{ i18n.t('select_branch.loading_branches') }}
      </div>
      
      <div v-else-if="branches.length === 0" class="empty-state">
        {{ i18n.t('select_branch.no_active_branches') }}
      </div>

      <div v-else class="branch-grid">
        <button
          v-for="branch in branches"
          :key="branch.id"
          class="branch-card"
          @click="onSelectBranch(branch.id)"
          :disabled="submitting"
        >
          <div class="branch-icon">
            <Store :size="24" />
          </div>
          <div class="branch-info">
            <h3>{{ branch.name }}</h3>
            <p>{{ branch.address || branch.code }}</p>
          </div>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.select-branch-shell {
  min-height: 100vh;
  display: grid;
  place-items: center;
  background: #FFF8F5;
  padding: 24px;
}
.select-branch-card {
  width: 100%;
  max-width: 600px;
  padding: 36px 32px 32px;
  border-radius: 18px;
  background: white;
  box-shadow: 0 8px 32px rgba(44, 62, 80, 0.08);
}
.brand-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 32px;
}
.brand-title {
  margin: 0;
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
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.error-msg {
  margin: 0 0 16px 0;
  padding: 12px 16px;
  border-radius: 8px;
  background: #fee2e2;
  color: #b91c1c;
  font-size: 14px;
  text-align: center;
}

.loading-state, .empty-state {
  text-align: center;
  color: #64748b;
  padding: 32px 0;
  font-size: 15px;
}

.branch-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 16px;
}

.branch-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  background: white;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: left;
}

.branch-card:hover:not(:disabled) {
  border-color: #FF672E;
  background: #fffafa;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(255, 103, 46, 0.1);
}

.branch-card:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.branch-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 10px;
  background: #fff0eb;
  color: #FF672E;
  flex-shrink: 0;
}

.branch-card:hover:not(:disabled) .branch-icon {
  background: #FF672E;
  color: white;
}

.branch-info h3 {
  margin: 0 0 4px 0;
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
}

.branch-info p {
  margin: 0;
  font-size: 13px;
  color: #64748b;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
