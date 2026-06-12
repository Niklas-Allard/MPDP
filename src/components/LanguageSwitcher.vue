<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { Languages } from '@lucide/vue'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { setLocale, type SupportedLocale } from '@/i18n'

const { t, locale } = useI18n()

function selectLocale(value: SupportedLocale) {
  setLocale(value)
}
</script>

<template>
  <DropdownMenu>
    <DropdownMenuTrigger as-child>
      <Button variant="ghost" size="sm" :aria-label="t('language.label')">
        <Languages class="size-4" />
        <span class="hidden sm:inline">{{ t(`language.${locale}`) }}</span>
      </Button>
    </DropdownMenuTrigger>
    <DropdownMenuContent align="end">
      <DropdownMenuItem @click="selectLocale('de')">
        {{ t('language.de') }}
      </DropdownMenuItem>
      <DropdownMenuItem @click="selectLocale('en')">
        {{ t('language.en') }}
      </DropdownMenuItem>
    </DropdownMenuContent>
  </DropdownMenu>
</template>
