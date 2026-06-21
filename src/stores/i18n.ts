import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'
import { setI18nLocale, type AppLocale } from '@/locales'
import vi from '@/locales/vi'
import ja from '@/locales/ja'

/**
 * ============================================================
 *  useI18nStore
 *  ------------------------------------------------------------
 *  Pinia store quản lý chuyển ngữ Việt ↔ Nhật cho toàn project.
 *
 *  • Lưu locale vào localStorage để giữ qua các lần reload.
 *  • Tự động phát hiện ngôn ngữ trình duyệt lần đầu.
 *  • Đồng bộ locale với vue-i18n để các component dùng `t()`.
 *  • Cung cấp:
 *      - locale, isVi, isJa (state/getters)
 *      - availableLocales, languageMeta (meta)
 *      - setLocale, toggleLocale, t (actions)
 *      - onChange callback cho mọi component muốn lắng nghe
 * ============================================================
 */

const STORAGE_KEY = 'ngu-cat.locale'
const SUPPORTED: AppLocale[] = ['vi', 'ja']

export interface LanguageMeta {
  code: AppLocale
  label: string
  nativeLabel: string
  flag: string
}

export const LANGUAGE_META: Record<AppLocale, LanguageMeta> = {
  vi: { code: 'vi', label: 'Vietnamese',  nativeLabel: 'Tiếng Việt',  flag: '🇻🇳' },
  ja: { code: 'ja', label: 'Japanese',    nativeLabel: '日本語',       flag: '🇯🇵' },
}

/* ---------- Helpers ---------- */
function detectInitialLocale(): AppLocale {
  if (typeof window === 'undefined') return 'vi'
  const stored = window.localStorage.getItem(STORAGE_KEY) as AppLocale | null
  if (stored && SUPPORTED.includes(stored)) return stored
  const browser = window.navigator?.language?.toLowerCase() ?? 'vi'
  if (browser.startsWith('ja')) return 'ja'
  return 'vi'
}

function applyDocumentLang(locale: AppLocale) {
  if (typeof document === 'undefined') return
  document.documentElement.setAttribute('lang', locale)
  document.documentElement.setAttribute('data-locale', locale)
}

function persistLocale(locale: AppLocale) {
  if (typeof window === 'undefined') return
  window.localStorage.setItem(STORAGE_KEY, locale)
}

/* ---------- Store factory ---------- */
export const useI18nStore = defineStore('i18n', () => {
  /* ===== state ===== */
  const locale = ref<AppLocale>(detectInitialLocale())
  const isSwitching = ref(false)

  /* ===== getters ===== */
  const isVi = computed(() => locale.value === 'vi')
  const isJa = computed(() => locale.value === 'ja')

  const availableLocales = computed<AppLocale[]>(() => [...SUPPORTED])

  const currentMeta = computed<LanguageMeta>(
    () => LANGUAGE_META[locale.value] ?? LANGUAGE_META.vi,
  )

  const messages = computed(() => ({
    vi,
    ja,
  }))

  /* ===== actions ===== */
  function setLocale(next: AppLocale) {
    if (!SUPPORTED.includes(next)) return
    if (next === locale.value) return
    isSwitching.value = true
    locale.value = next
    // Đồng bộ với vue-i18n ngay lập tức
    setI18nLocale(next)
    applyDocumentLang(next)
    persistLocale(next)
    // Tắt cờ switching sau 1 frame để component kịp render transition
    if (typeof window !== 'undefined') {
      window.requestAnimationFrame(() => {
        isSwitching.value = false
      })
    }
  }

  function toggleLocale() {
    setLocale(locale.value === 'vi' ? 'ja' : 'vi')
  }

  /**
   * Hàm dịch trực tiếp từ store — tiện cho component không dùng `useI18n()`.
   * Hỗ trợ dot-path:  t('nav.timeline')  ->  "Lịch đặt bàn"
   * Hỗ trợ interpolation:  t('greet', { name: 'Per' })
   */
  function t(key: string, params?: Record<string, unknown>): string {
    const lookup = (l: AppLocale): unknown =>
      key.split('.').reduce<unknown>(
        (acc, segment) =>
          acc && typeof acc === 'object'
            ? (acc as Record<string, unknown>)[segment]
            : undefined,
        l === 'vi' ? vi : ja,
      )
    const raw: unknown = lookup(locale.value) ?? lookup('vi') ?? key
    if (typeof raw !== 'string') return key
    if (!params) return raw
    return Object.entries(params).reduce(
      (acc, [k, v]) => acc.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v)),
      raw,
    )
  }

  /* ===== init ===== */
  // Đồng bộ vue-i18n + <html lang> với giá trị ban đầu.
  setI18nLocale(locale.value)
  applyDocumentLang(locale.value)

  // Watcher: nếu locale thay đổi từ bên ngoài (VD: devtools), vẫn giữ sync.
  watch(locale, (next) => {
    setI18nLocale(next)
    applyDocumentLang(next)
    persistLocale(next)
  })

  return {
    /* state */
    locale,
    isSwitching,
    /* getters */
    isVi,
    isJa,
    availableLocales,
    currentMeta,
    messages,
    /* actions */
    setLocale,
    toggleLocale,
    t,
  }
})

export type I18nStore = ReturnType<typeof useI18nStore>