<script setup lang="ts">
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useContent } from '@/composables/useContent'

const accessibility = useContent('accessibility')
</script>

<template>
  <div class="flex flex-col gap-8">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">{{ accessibility.title }}</h1>
      <p class="mt-2 leading-relaxed">{{ accessibility.intro }}</p>
    </div>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ accessibility.principlesTitle }}</h2>
      <div class="flex flex-col gap-4">
        <Card v-for="(principle, i) in accessibility.principles" :key="i">
          <CardHeader>
            <CardTitle>{{ principle.title }}</CardTitle>
          </CardHeader>
          <CardContent>
            <p class="leading-relaxed">{{ principle.description }}</p>
          </CardContent>
        </Card>
      </div>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ accessibility.contributingTitle }}</h2>
      <p class="leading-relaxed">{{ accessibility.contributingText }}</p>
    </section>
  </div>
</template>