<script setup lang="ts">
import { Badge } from '@/components/ui/badge'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { useContent } from '@/composables/useContent'

const home = useContent('home')
</script>

<template>
  <div class="flex flex-col gap-8">
    <div>
      <Badge variant="secondary" class="mb-3">{{ home.badge }}</Badge>
      <h1 class="text-3xl font-bold tracking-tight">{{ home.title }}</h1>
      <p class="text-muted-foreground mt-2 text-lg">{{ home.subtitle }}</p>
      <p class="mt-4 leading-relaxed">{{ home.description }}</p>
    </div>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ home.goalsTitle }}</h2>
      <ul class="ml-5 list-disc space-y-1.5">
        <li v-for="(goal, i) in home.goals" :key="i">{{ goal }}</li>
      </ul>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ home.techStackTitle }}</h2>
      <Card>
        <CardContent class="grid gap-3 sm:grid-cols-2">
          <div v-for="(item, i) in home.techStack" :key="i" class="flex flex-col">
            <span class="text-muted-foreground text-sm">{{ item.label }}</span>
            <span class="font-medium">{{ item.value }}</span>
          </div>
        </CardContent>
      </Card>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ home.quickLinksTitle }}</h2>
      <div class="grid gap-4 sm:grid-cols-2">
        <router-link v-for="(link, i) in home.quickLinks" :key="i" :to="link.to">
          <Card class="h-full transition-colors hover:border-primary">
            <CardHeader>
              <CardTitle>{{ link.title }}</CardTitle>
              <CardDescription>{{ link.description }}</CardDescription>
            </CardHeader>
          </Card>
        </router-link>
      </div>
    </section>
  </div>
</template>