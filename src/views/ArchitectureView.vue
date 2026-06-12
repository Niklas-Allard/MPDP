<script setup lang="ts">
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { useContent } from '@/composables/useContent'

const architecture = useContent('architecture')
</script>

<template>
  <div class="flex flex-col gap-8">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">{{ architecture.title }}</h1>
      <p class="mt-2 leading-relaxed">{{ architecture.intro }}</p>
    </div>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ architecture.backendTitle }}</h2>
      <Card>
        <CardContent class="space-y-4">
          <div v-for="(item, i) in architecture.backend" :key="i">
            <code class="text-sm font-semibold">{{ item.name }}</code>
            <p class="text-muted-foreground mt-1 text-sm">{{ item.description }}</p>
          </div>
        </CardContent>
      </Card>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ architecture.frontendTitle }}</h2>
      <Card>
        <CardContent class="space-y-4">
          <div v-for="(item, i) in architecture.frontend" :key="i">
            <code class="text-sm font-semibold">{{ item.name }}</code>
            <p class="text-muted-foreground mt-1 text-sm">{{ item.description }}</p>
          </div>
        </CardContent>
      </Card>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ architecture.databaseTitle }}</h2>
      <Card>
        <CardContent class="space-y-4">
          <div v-for="(item, i) in architecture.database" :key="i">
            <code class="text-sm font-semibold">{{ item.name }}</code>
            <p class="text-muted-foreground mt-1 text-sm">{{ item.description }}</p>
          </div>
        </CardContent>
      </Card>

      <h3 class="mt-4 mb-2 font-semibold">{{ architecture.databaseTablesTitle }}</h3>
      <Card>
        <CardContent class="space-y-3">
          <div v-for="(item, i) in architecture.databaseTables" :key="i">
            <code class="text-sm font-semibold">{{ item.name }}</code>
            <span class="text-muted-foreground ml-2 text-sm">{{ item.description }}</span>
          </div>
        </CardContent>
      </Card>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ architecture.resourcesTitle }}</h2>
      <p class="leading-relaxed">{{ architecture.resourcesText }}</p>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ architecture.patternsTitle }}</h2>
      <div class="flex flex-col gap-4">
        <Card v-for="(pattern, i) in architecture.patterns" :key="i">
          <CardHeader>
            <CardTitle>{{ pattern.name }}</CardTitle>
          </CardHeader>
          <CardContent>
            <p class="leading-relaxed">{{ pattern.description }}</p>
            <ul v-if="pattern.items.length" class="mt-3 ml-5 list-disc space-y-1">
              <li v-for="(item, j) in pattern.items" :key="j">
                <code class="text-sm font-semibold">{{ item.name }}</code>
                <span class="text-muted-foreground"> — {{ item.description }}</span>
              </li>
            </ul>
          </CardContent>
        </Card>
      </div>
    </section>
  </div>
</template>