import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import de from '@/locales/de.json'
import en from '@/locales/en.json'

const content = { de, en }

export function useContent<K extends keyof typeof de>(section: K) {
  const { locale } = useI18n()
  return computed(() => content[locale.value as 'de' | 'en'][section])
}