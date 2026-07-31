<!--
  SettingsModal.vue
  ─────────────────────────────────────────────────────────────────────────────
  Simple configuration modal for username/password.  Self-contained form
  state.  Parent toggles `isOpen` and handles `save`.
-->
<template>
  <Transition name="fade">
    <div v-if="isOpen" class="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-[9999] p-4">
      <div class="settings-modal w-full max-w-[500px] bg-white rounded-2xl overflow-hidden shadow-2xl border border-gray-100 text-[#333333]">

        <!-- Header -->
        <div class="modal-header bg-[#1a5276] text-white p-4 flex items-center justify-between">
          <h2 class="text-base font-black uppercase tracking-wide">{{ t('reception.configuration') }}</h2>
          <button @click="$emit('close')" class="text-white/80 hover:text-white transition-colors" type="button">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>

        <!-- Form Content -->
        <div class="modal-content p-5 space-y-4">
          <!-- Username -->
          <div class="form-row flex flex-col gap-1">
            <label class="text-xs font-bold text-gray-600">{{ t('reception.username') }}</label>
            <div class="input-group flex items-center gap-1.5">
              <input
                v-model="username"
                type="text"
                class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                :placeholder="t('reception.enter_username')"
              />
              <button type="button" class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all">...</button>
            </div>
          </div>

          <!-- Password -->
          <div class="form-row flex flex-col gap-1">
            <label class="text-xs font-bold text-gray-600">{{ t('reception.password') }}</label>
            <div class="input-group flex items-center gap-1.5">
              <input
                v-model="password"
                type="password"
                class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                :placeholder="t('reception.enter_password')"
              />
              <button type="button" class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all">...</button>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="modal-footer p-4 border-t border-gray-200 bg-gray-50 flex items-center justify-end gap-3">
          <button
            type="button"
            class="btn btn-confirm px-6 py-2 bg-[#4DB6AC] hover:bg-[#40a095] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95"
            @click="handleSave"
          >{{ t('reception.confirm') }}</button>
          <button
            type="button"
            class="btn btn-skip px-6 py-2 bg-[#E57373] hover:bg-[#d9534f] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95"
            @click="$emit('close')"
          >{{ t('reception.ignore') }}</button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useLanguageStore } from '@/stores/useLanguageStore'

export interface SettingsPayload {
  username: string
  password: string
}

const props = defineProps<{
  isOpen: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'save', payload: SettingsPayload): void
}>()

const langStore = useLanguageStore()
const t = langStore.t

const username = ref('mo')
const password = ref('')

function handleSave() {
  emit('save', { username: username.value, password: password.value })
}

// Reset form when modal opens
watch(
  () => props.isOpen,
  (open) => {
    if (open) {
      username.value = 'mo'
      password.value = ''
    }
  },
)
</script>

<style scoped>
.settings-modal {
  width: 100%;
  max-width: 500px;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.btn-confirm {
  background: #4DB6AC;
  color: white;
}

.btn-confirm:hover {
  background: #40a095;
}

.btn-skip {
  background: #E57373;
  color: white;
}

.btn-skip:hover {
  background: #d9534f;
}
</style>
