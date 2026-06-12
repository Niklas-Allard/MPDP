<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'
import AppSidebar from '@/components/AppSidebar.vue'
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import { Separator } from '@/components/ui/separator'
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from '@/components/ui/sidebar'

const { t } = useI18n()
const route = useRoute()
</script>

<template>
  <router-view v-if="route.meta.standalone" />
  <SidebarProvider v-else>
    <AppSidebar />
    <SidebarInset>
      <header
        class="flex h-14 shrink-0 items-center gap-2 border-b px-4"
      >
        <SidebarTrigger class="-ml-1" />
        <Separator orientation="vertical" class="mr-2 h-4" />
        <span class="font-medium">{{ t('app.title') }}</span>
        <div class="ml-auto">
          <LanguageSwitcher />
        </div>
      </header>
      <main class="flex flex-1 flex-col gap-6 p-4 md:p-8">
        <div class="mx-auto w-full max-w-3xl">
          <router-view />
        </div>
      </main>
    </SidebarInset>
  </SidebarProvider>
</template>