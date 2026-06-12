<script setup lang="ts">
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useContent } from '@/composables/useContent'

const setup = useContent('setup')
</script>

<template>
  <div class="flex flex-col gap-8">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">{{ setup.title }}</h1>
      <p class="mt-2 leading-relaxed">{{ setup.intro }}</p>
    </div>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ setup.prereqTitle }}</h2>
      <ul class="ml-5 list-disc space-y-1.5">
        <li v-for="(item, i) in setup.prereq" :key="i">{{ item }}</li>
      </ul>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ setup.stepsTitle }}</h2>
      <ol class="flex flex-col gap-4">
        <li v-for="(step, i) in setup.steps" :key="i">
          <Card>
            <CardHeader>
              <CardTitle class="flex items-center gap-2">
                <span
                  class="bg-primary text-primary-foreground flex size-6 shrink-0 items-center justify-center rounded-full text-sm"
                >
                  {{ i + 1 }}
                </span>
                {{ step.title }}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p class="leading-relaxed">{{ step.description }}</p>
              <pre
                v-if="'code' in step && step.code"
                class="bg-muted mt-3 overflow-x-auto rounded-md p-3 text-sm"
              ><code>{{ step.code }}</code></pre>
            </CardContent>
          </Card>
        </li>
      </ol>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ setup.buildTitle }}</h2>
      <p class="leading-relaxed">{{ setup.buildText }}</p>
    </section>
  </div>
</template>