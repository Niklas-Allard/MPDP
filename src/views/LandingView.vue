<script setup lang="ts">
import {
  ArrowRight,
  GitFork,
  BookOpen,
  Volume2,
  Eye,
  Accessibility,
  History,
  ZoomIn,
  MousePointerClick,
  XCircle,
  CheckCircle2,
} from '@lucide/vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/components/ui/card'
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import { useContent } from '@/composables/useContent'

const landing = useContent('landing')

const GITHUB_URL = 'https://github.com/Niklas-Allard/MPDP'

const featureIcons = {
  Volume2,
  Eye,
  Accessibility,
  History,
  ZoomIn,
  MousePointerClick,
} as const
</script>

<template>
  <div class="bg-background text-foreground min-h-screen">
    <header class="sticky top-0 z-10 border-b bg-background/80 backdrop-blur">
      <div class="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-3 md:px-8">
        <router-link to="/" class="flex items-center gap-2">
          <div
            class="bg-primary text-primary-foreground flex aspect-square size-8 items-center justify-center rounded-lg font-semibold"
          >
            M
          </div>
          <div class="flex flex-col leading-tight">
            <span class="font-semibold tracking-tight">MPDP</span>
            <span class="text-muted-foreground hidden text-xs sm:block">{{ landing.nav.tagline }}</span>
          </div>
        </router-link>
        <nav class="flex items-center gap-2">
          <Button variant="ghost" size="sm" as-child>
            <router-link to="/docs">
              <BookOpen />
              <span class="hidden sm:inline">{{ landing.nav.docs }}</span>
            </router-link>
          </Button>
          <Button variant="ghost" size="sm" as-child>
            <a :href="GITHUB_URL" target="_blank" rel="noreferrer">
              <GitFork />
              <span class="hidden sm:inline">{{ landing.nav.github }}</span>
            </a>
          </Button>
          <LanguageSwitcher />
        </nav>
      </div>
    </header>

    <main>
      <!-- Hero -->
      <section class="mx-auto max-w-6xl px-4 py-16 text-center md:px-8 md:py-24">
        <Badge variant="secondary" class="mb-4">{{ landing.hero.badge }}</Badge>
        <p class="text-muted-foreground text-sm font-medium tracking-wide uppercase">
          {{ landing.hero.acronym }}
        </p>
        <h1 class="mx-auto mt-2 max-w-3xl text-4xl font-bold tracking-tight md:text-5xl">
          {{ landing.hero.title }}
        </h1>
        <p class="text-muted-foreground mx-auto mt-5 max-w-2xl text-lg leading-relaxed">
          {{ landing.hero.subtitle }}
        </p>
        <div class="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <Button size="lg" as-child>
            <a :href="GITHUB_URL" target="_blank" rel="noreferrer">
              <GitFork />
              {{ landing.hero.primaryCta }}
            </a>
          </Button>
          <Button size="lg" variant="outline" as-child>
            <router-link to="/docs">
              {{ landing.hero.secondaryCta }}
              <ArrowRight />
            </router-link>
          </Button>
        </div>
        <div class="text-muted-foreground mt-10 flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-sm">
          <span v-for="(item, i) in landing.trust.items" :key="i" class="flex items-center gap-1.5">
            <CheckCircle2 class="size-4 shrink-0" />
            {{ item }}
          </span>
        </div>
      </section>

      <!-- Problem -->
      <section class="border-t bg-muted/30">
        <div class="mx-auto max-w-6xl px-4 py-16 md:px-8">
          <div class="mx-auto max-w-2xl text-center">
            <h2 class="text-2xl font-bold tracking-tight md:text-3xl">{{ landing.problem.title }}</h2>
            <p class="text-muted-foreground mt-3 leading-relaxed">{{ landing.problem.intro }}</p>
          </div>
          <div class="mt-10 grid gap-4 sm:grid-cols-2">
            <Card v-for="(point, i) in landing.problem.points" :key="i">
              <CardHeader>
                <div class="flex items-start gap-3">
                  <XCircle class="text-destructive mt-0.5 size-5 shrink-0" />
                  <div>
                    <CardTitle class="text-base">{{ point.title }}</CardTitle>
                    <CardDescription class="mt-1.5">{{ point.description }}</CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          </div>
        </div>
      </section>

      <!-- Solution -->
      <section class="mx-auto max-w-3xl px-4 py-16 text-center md:px-8">
        <h2 class="text-2xl font-bold tracking-tight md:text-3xl">{{ landing.solution.title }}</h2>
        <p class="text-muted-foreground mt-4 text-lg leading-relaxed">{{ landing.solution.text }}</p>
      </section>

      <!-- Features -->
      <section class="border-t bg-muted/30">
        <div class="mx-auto max-w-6xl px-4 py-16 md:px-8">
          <div class="mx-auto max-w-2xl text-center">
            <h2 class="text-2xl font-bold tracking-tight md:text-3xl">{{ landing.features.title }}</h2>
            <p class="text-muted-foreground mt-3 leading-relaxed">{{ landing.features.subtitle }}</p>
          </div>
          <div class="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <Card v-for="(feature, i) in landing.features.items" :key="i" class="h-full">
              <CardHeader>
                <div
                  class="bg-primary text-primary-foreground mb-2 flex size-9 items-center justify-center rounded-lg"
                >
                  <component :is="featureIcons[feature.icon as keyof typeof featureIcons]" class="size-5" />
                </div>
                <CardTitle class="text-base">{{ feature.title }}</CardTitle>
                <CardDescription class="mt-1.5">{{ feature.description }}</CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </section>

      <!-- How it works -->
      <section class="mx-auto max-w-6xl px-4 py-16 md:px-8">
        <div class="mx-auto max-w-2xl text-center">
          <h2 class="text-2xl font-bold tracking-tight md:text-3xl">{{ landing.howItWorks.title }}</h2>
        </div>
        <div class="mt-10 grid gap-8 sm:grid-cols-3">
          <div v-for="(step, i) in landing.howItWorks.steps" :key="i" class="text-center">
            <div
              class="border-primary text-primary mx-auto flex size-10 items-center justify-center rounded-full border-2 text-lg font-semibold"
            >
              {{ i + 1 }}
            </div>
            <h3 class="mt-4 font-semibold">{{ step.title }}</h3>
            <p class="text-muted-foreground mt-2 text-sm leading-relaxed">{{ step.description }}</p>
          </div>
        </div>
      </section>

      <!-- Mission -->
      <section class="border-t bg-muted/30">
        <div class="mx-auto max-w-3xl px-4 py-16 text-center md:px-8">
          <h2 class="text-2xl font-bold tracking-tight md:text-3xl">{{ landing.mission.title }}</h2>
          <p class="text-muted-foreground mt-4 text-lg leading-relaxed">{{ landing.mission.text }}</p>
        </div>
      </section>

      <!-- FAQ -->
      <section class="mx-auto max-w-3xl px-4 py-16 md:px-8">
        <h2 class="text-center text-2xl font-bold tracking-tight md:text-3xl">{{ landing.faq.title }}</h2>
        <div class="mt-10 space-y-6">
          <div v-for="(item, i) in landing.faq.items" :key="i">
            <h3 class="font-semibold">{{ item.question }}</h3>
            <p class="text-muted-foreground mt-1.5 leading-relaxed">{{ item.answer }}</p>
          </div>
        </div>
      </section>

      <!-- CTA -->
      <section class="border-t">
        <div class="mx-auto max-w-3xl px-4 py-16 text-center md:px-8">
          <h2 class="text-2xl font-bold tracking-tight md:text-3xl">{{ landing.cta.title }}</h2>
          <p class="text-muted-foreground mt-3 text-lg leading-relaxed">{{ landing.cta.subtitle }}</p>
          <div class="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <Button size="lg" as-child>
              <a :href="GITHUB_URL" target="_blank" rel="noreferrer">
                <GitFork />
                {{ landing.cta.primaryCta }}
              </a>
            </Button>
            <Button size="lg" variant="outline" as-child>
              <router-link to="/docs">
                {{ landing.cta.secondaryCta }}
                <ArrowRight />
              </router-link>
            </Button>
          </div>
        </div>
      </section>
    </main>

    <footer class="border-t">
      <div class="mx-auto flex max-w-6xl flex-col items-center gap-3 px-4 py-8 text-center md:px-8">
        <p class="text-muted-foreground text-sm">{{ landing.footer.tagline }}</p>
        <div class="flex items-center gap-4 text-sm">
          <router-link to="/docs" class="hover:text-foreground text-muted-foreground">
            {{ landing.footer.docsLabel }}
          </router-link>
          <a
            :href="GITHUB_URL"
            target="_blank"
            rel="noreferrer"
            class="hover:text-foreground text-muted-foreground"
          >
            {{ landing.footer.githubLabel }}
          </a>
        </div>
        <p class="text-muted-foreground text-xs">{{ landing.footer.rights }}</p>
      </div>
    </footer>
  </div>
</template>
