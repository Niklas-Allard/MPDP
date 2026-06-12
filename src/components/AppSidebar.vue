<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'
import {
  Home,
  Network,
  Rocket,
  PlaySquare,
  Accessibility,
  Code2,
  GitFork,
  BookOpen,
  Terminal,
} from '@lucide/vue'
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from '@/components/ui/sidebar'

const { t } = useI18n()
const route = useRoute()

const items = [
  { to: '/docs', icon: Home, key: 'home' },
  { to: '/architecture', icon: Network, key: 'architecture' },
  { to: '/setup', icon: Rocket, key: 'setup' },
  { to: '/usage', icon: PlaySquare, key: 'usage' },
  { to: '/accessibility', icon: Accessibility, key: 'accessibility' },
  { to: '/development', icon: Code2, key: 'development' },
  { to: '/user-guide', icon: BookOpen, key: 'userGuide' },
  { to: '/developer-guide', icon: Terminal, key: 'developerGuide' },
] as const
</script>

<template>
  <Sidebar>
    <SidebarHeader>
      <SidebarMenu>
        <SidebarMenuItem>
          <SidebarMenuButton size="lg" as-child>
            <router-link to="/docs">
              <div
                class="bg-primary text-primary-foreground flex aspect-square size-8 items-center justify-center rounded-lg font-semibold"
              >
                M
              </div>
              <div class="flex flex-col gap-0.5 leading-none">
                <span class="font-semibold">MPDP</span>
                <span class="text-muted-foreground text-xs">{{ t('app.title') }}</span>
              </div>
            </router-link>
          </SidebarMenuButton>
        </SidebarMenuItem>
      </SidebarMenu>
    </SidebarHeader>
    <SidebarContent>
      <SidebarGroup>
        <SidebarGroupLabel>{{ t('nav.groupTitle') }}</SidebarGroupLabel>
        <SidebarGroupContent>
          <SidebarMenu>
            <SidebarMenuItem v-for="item in items" :key="item.key">
              <SidebarMenuButton as-child :data-active="route.path === item.to || undefined">
                <router-link :to="item.to">
                  <component :is="item.icon" />
                  <span>{{ t(`nav.${item.key}`) }}</span>
                </router-link>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarGroupContent>
      </SidebarGroup>
    </SidebarContent>
    <SidebarFooter>
      <SidebarMenu>
        <SidebarMenuItem>
          <SidebarMenuButton as-child>
            <a
              href="https://github.com/Niklas-Allard/MPDP"
              target="_blank"
              rel="noreferrer"
            >
              <GitFork />
              <span>{{ t('app.githubLabel') }}</span>
            </a>
          </SidebarMenuButton>
        </SidebarMenuItem>
      </SidebarMenu>
    </SidebarFooter>
  </Sidebar>
</template>
