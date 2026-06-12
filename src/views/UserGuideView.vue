<script setup lang="ts">
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useContent } from '@/composables/useContent'

const userGuide = useContent('userGuide')
</script>

<template>
  <div class="flex flex-col gap-8">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">{{ userGuide.title }}</h1>
      <p class="mt-2 leading-relaxed">{{ userGuide.intro }}</p>
    </div>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ userGuide.sectionsTitle }}</h2>
      <div class="flex flex-col gap-4">
        <Card v-for="(section, i) in userGuide.sections" :key="i">
          <CardHeader>
            <CardTitle>{{ section.title }}</CardTitle>
          </CardHeader>
          <CardContent class="flex flex-col gap-3">
            <p class="leading-relaxed">{{ section.description }}</p>
            <ul class="ml-5 list-disc space-y-1.5">
              <li v-for="(item, j) in section.items" :key="j">{{ item }}</li>
            </ul>
          </CardContent>
        </Card>
      </div>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ userGuide.shortcutsTitle }}</h2>
      <Card>
        <CardContent class="space-y-3">
          <div v-for="(shortcut, i) in userGuide.shortcuts" :key="i">
            <code class="bg-muted rounded px-1.5 py-0.5 text-sm font-semibold">{{ shortcut.keys }}</code>
            <span class="text-muted-foreground ml-2 text-sm">{{ shortcut.description }}</span>
          </div>
        </CardContent>
      </Card>
    </section>

    <section>
      <h2 class="mb-1 text-xl font-semibold">{{ userGuide.settingsTitle }}</h2>
      <p class="text-muted-foreground mb-3 leading-relaxed">{{ userGuide.settingsIntro }}</p>
      <div class="flex flex-col gap-4">
        <Card v-for="(group, i) in userGuide.settingsGroups" :key="i">
          <CardHeader>
            <CardTitle>{{ group.title }}</CardTitle>
          </CardHeader>
          <CardContent class="space-y-4">
            <div v-for="(item, j) in group.items" :key="j">
              <div class="flex flex-wrap items-baseline gap-2">
                <span class="font-semibold">{{ item.name }}</span>
                <span class="text-muted-foreground text-xs">{{ item.value }}</span>
              </div>
              <p class="text-muted-foreground mt-1 text-sm leading-relaxed">{{ item.description }}</p>
            </div>
          </CardContent>
        </Card>
      </div>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ userGuide.imageDirTitle }}</h2>
      <p class="leading-relaxed">{{ userGuide.imageDirText }}</p>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ userGuide.mainDirsTitle }}</h2>
      <p class="leading-relaxed">{{ userGuide.mainDirsText }}</p>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ userGuide.resetTitle }}</h2>
      <p class="leading-relaxed">{{ userGuide.resetText }}</p>
    </section>
  </div>
</template>
