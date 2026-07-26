import { useLanguageStore } from '@/stores/useLanguageStore'
import { useI18nStore } from '@/stores/i18n'
import { i18n } from '@/locales'

// Tầng 1: Flat Key (Không lồng nhau)
function resolveFlatKey(key: string, lang: string): string | undefined {
  const globalMessages = (i18n.global.messages as any).value || i18n.global.messages;
  return globalMessages?.[lang]?.[key] || globalMessages?.['vi']?.[key];
}

// Tầng 2: Nested Key (Vue I18n Standard)
function resolveNestedKey(key: string): string | undefined {
  try {
    const hasKey = i18n.global.te(key);
    if (hasKey) {
      return i18n.global.t(key) as string;
    }
  } catch {
    // ignore
  }
  return undefined;
}

// Tầng 3: Fallback Dictionary
function resolveFromDict(key: string, lang: string): string | undefined {
  const store = useLanguageStore()
  // Try state.lang or vi fallback from dict
  return store.dict?.[lang]?.[key] || store.dict?.[key];
}

export function setApplicationLanguage(lang: 'vi' | 'en' | 'ja') {
  const store = useLanguageStore()
  store.setLanguage(lang)
  
  const i18nStore = useI18nStore()
  i18nStore.setLocale(lang)
  
  // Update HTML lang attribute
  if (typeof document !== 'undefined') {
    document.documentElement.lang = lang
    document.documentElement.setAttribute('data-locale', lang)
  }
  
  console.log(`[i18n] Language changed to: ${lang}`)
}

export function t(key: string, params?: Record<string, any>): string {
  const store = useLanguageStore()
  const lang = store.lang || 'vi'
  
  // Multi-tier resolution
  let translation = 
    resolveFlatKey(key, lang) ||
    resolveNestedKey(key) ||
    resolveFromDict(key, lang) ||
    key // Fallback to key
  
  // Apply params if any
  if (params && typeof translation === 'string') {
    translation = Object.entries(params).reduce((result, [paramKey, value]) => {
      return result.replace(`{${paramKey}}`, String(value));
    }, translation);
  }
  
  return translation;
}
