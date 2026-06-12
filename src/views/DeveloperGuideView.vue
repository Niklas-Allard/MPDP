<script setup lang="ts">
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useContent } from '@/composables/useContent'

const devGuide = useContent('devGuide')
</script>

<template>
  <div class="flex flex-col gap-8">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">{{ devGuide.title }}</h1>
      <p class="mt-2 leading-relaxed">{{ devGuide.intro }}</p>
    </div>

    <section>
      <h2 class="mb-1 text-xl font-semibold">{{ devGuide.contextTitle }}</h2>
      <p class="text-muted-foreground mb-3 leading-relaxed">{{ devGuide.contextText }}</p>
      <Card>
        <CardContent class="space-y-3">
          <div v-for="(item, i) in devGuide.contextItems" :key="i">
            <code class="text-sm font-semibold">{{ item.name }}</code>
            <span class="text-muted-foreground ml-2 text-sm">{{ item.description }}</span>
          </div>
        </CardContent>
      </Card>
    </section>

    <!-- SettingsManager -->
    <section>
      <h2 class="mb-1 text-xl font-semibold">{{ devGuide.settingsManagerTitle }}</h2>
      <p class="text-muted-foreground mb-3 leading-relaxed">{{ devGuide.settingsManagerIntro }}</p>

      <Card>
        <CardHeader>
          <CardTitle class="text-base">Properties</CardTitle>
        </CardHeader>
        <CardContent class="grid gap-2 sm:grid-cols-2">
          <div v-for="(prop, i) in devGuide.settingsManagerProps" :key="i" class="flex flex-col">
            <code class="text-sm font-semibold">{{ prop.name }}</code>
            <span class="text-muted-foreground text-xs">{{ prop.type }} · {{ prop.default }}</span>
          </div>
        </CardContent>
      </Card>

      <Card class="mt-4">
        <CardHeader>
          <CardTitle class="text-base">{{ devGuide.settingsManagerColorsTitle }}</CardTitle>
        </CardHeader>
        <CardContent>
          <p class="leading-relaxed">{{ devGuide.settingsManagerColorsText }}</p>
        </CardContent>
      </Card>

      <Card class="mt-4">
        <CardHeader>
          <CardTitle class="text-base">{{ devGuide.settingsManagerMethodsTitle }}</CardTitle>
        </CardHeader>
        <CardContent class="space-y-3">
          <div v-for="(method, i) in devGuide.settingsManagerMethods" :key="i">
            <code class="text-sm font-semibold">{{ method.signature }}</code>
            <p class="text-muted-foreground mt-1 text-sm leading-relaxed">{{ method.description }}</p>
          </div>
        </CardContent>
      </Card>
    </section>

    <!-- fileHandler -->
    <section>
      <h2 class="mb-1 text-xl font-semibold">{{ devGuide.fileHandlerTitle }}</h2>
      <p class="text-muted-foreground mb-3 leading-relaxed">{{ devGuide.fileHandlerIntro }}</p>
      <Card>
        <CardContent class="space-y-4">
          <p class="text-sm leading-relaxed">{{ devGuide.fileHandlerConst }}</p>
          <div v-for="(method, i) in devGuide.fileHandlerMethods" :key="i">
            <code class="text-sm font-semibold">{{ method.signature }}</code>
            <p class="text-muted-foreground mt-1 text-sm leading-relaxed">{{ method.description }}</p>
          </div>
        </CardContent>
      </Card>
    </section>

    <!-- Media_DB -->
    <section>
      <h2 class="mb-1 text-xl font-semibold">{{ devGuide.mediaDbTitle }}</h2>
      <p class="text-muted-foreground mb-3 leading-relaxed">{{ devGuide.mediaDbIntro }}</p>

      <Card>
        <CardHeader>
          <CardTitle class="text-base">{{ devGuide.mediaDbTablesTitle }}</CardTitle>
        </CardHeader>
        <CardContent class="space-y-3">
          <div v-for="(table, i) in devGuide.mediaDbTables" :key="i">
            <code class="text-sm font-semibold">{{ table.name }}</code>
            <p class="text-muted-foreground text-xs">{{ table.columns }}</p>
            <p class="mt-1 text-sm leading-relaxed">{{ table.description }}</p>
          </div>
        </CardContent>
      </Card>

      <Card class="mt-4">
        <CardHeader>
          <CardTitle class="text-base">{{ devGuide.mediaDbMethodsTitle }}</CardTitle>
        </CardHeader>
        <CardContent class="space-y-3">
          <div v-for="(method, i) in devGuide.mediaDbMethods" :key="i">
            <code class="text-sm font-semibold">{{ method.signature }}</code>
            <p class="text-muted-foreground mt-1 text-sm leading-relaxed">{{ method.description }}</p>
          </div>
        </CardContent>
      </Card>
    </section>

    <!-- QML components -->
    <section>
      <h2 class="mb-1 text-xl font-semibold">{{ devGuide.qmlTitle }}</h2>
      <p class="text-muted-foreground mb-3 leading-relaxed">{{ devGuide.qmlIntro }}</p>
      <div class="flex flex-col gap-4">
        <Card v-for="(component, i) in devGuide.qmlComponents" :key="i">
          <CardHeader>
            <CardTitle class="font-mono text-base">{{ component.name }}</CardTitle>
            <p class="text-muted-foreground text-sm">{{ component.description }}</p>
          </CardHeader>
          <CardContent>
            <ul class="ml-5 list-disc space-y-1.5">
              <li v-for="(item, j) in component.items" :key="j">{{ item }}</li>
            </ul>
          </CardContent>
        </Card>
      </div>
    </section>

    <!-- main.py -->
    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ devGuide.mainPyTitle }}</h2>
      <Card>
        <CardContent>
          <ul class="ml-5 list-disc space-y-1.5">
            <li v-for="(item, i) in devGuide.mainPyItems" :key="i">{{ item }}</li>
          </ul>
        </CardContent>
      </Card>
    </section>
  </div>
</template>
