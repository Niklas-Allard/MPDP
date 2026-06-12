<script setup lang="ts">
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useContent } from '@/composables/useContent'

const usage = useContent('usage')
</script>

<template>
  <div class="flex flex-col gap-8">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">{{ usage.title }}</h1>
      <p class="mt-2 leading-relaxed">{{ usage.intro }}</p>
    </div>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ usage.startTitle }}</h2>
      <p class="leading-relaxed">{{ usage.startText }}</p>
    </section>

    <section>
      <Card>
        <CardHeader>
          <CardTitle>{{ usage.browserTitle }}</CardTitle>
        </CardHeader>
        <CardContent class="flex flex-col gap-3">
          <p class="leading-relaxed">{{ usage.browserText }}</p>
          <ul class="ml-5 list-disc space-y-1.5">
            <li v-for="(item, i) in usage.browserFeatures" :key="i">{{ item }}</li>
          </ul>
        </CardContent>
      </Card>
    </section>

    <section>
      <Card>
        <CardHeader>
          <CardTitle>{{ usage.playerTitle }}</CardTitle>
        </CardHeader>
        <CardContent class="flex flex-col gap-3">
          <p class="leading-relaxed">{{ usage.playerText }}</p>
          <ul class="ml-5 list-disc space-y-1.5">
            <li v-for="(item, i) in usage.playerFeatures" :key="i">{{ item }}</li>
          </ul>
        </CardContent>
      </Card>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ usage.progressTitle }}</h2>
      <p class="leading-relaxed">{{ usage.progressText }}</p>
    </section>
  </div>
</template>