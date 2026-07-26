import { createI18n } from 'vue-i18n'
import vi from './vi'
import ja from './ja'
import en from './en'

export type MessageSchema = typeof vi
export type AppLocale = 'vi' | 'ja' | 'en'

export const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  locale: 'vi',
  fallbackLocale: 'vi',
  messages: {
    vi,
    ja,
    en,
  },
})

/**
 * vue-i18n v9 with `legacy: false` types `i18n.global.locale` as the raw
 * `WritableComputedRef<AppLocale>`, but its `.value` setter assignment is
 * reported as a type error in some Vue 3.5 / TS 5.4 combinations. The
 * `setI18nLocale` helper hides the cast in one place.
 */
export function setI18nLocale(next: AppLocale): void {
  ;(i18n.global.locale as unknown as { value: AppLocale }).value = next
}
