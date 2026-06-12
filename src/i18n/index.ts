import { createI18n } from 'vue-i18n'
import de from '@/locales/de.json'
import en from '@/locales/en.json'

export type SupportedLocale = 'de' | 'en'

const STORAGE_KEY = 'mpdp-docs-locale'

function getInitialLocale(): SupportedLocale {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (stored === 'de' || stored === 'en') return stored

  const browserLang = navigator.language.toLowerCase()
  return browserLang.startsWith('de') ? 'de' : 'en'
}

export const i18n = createI18n({
  legacy: false,
  locale: getInitialLocale(),
  fallbackLocale: 'en',
  messages: { de, en },
})

export function setLocale(locale: SupportedLocale) {
  i18n.global.locale.value = locale
  localStorage.setItem(STORAGE_KEY, locale)
  document.documentElement.lang = locale
}
