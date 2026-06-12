<script setup lang="ts">
import { useContent } from '@/composables/useContent'

const development = useContent('development')
</script>

<template>
  <div class="flex flex-col gap-8">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">{{ development.title }}</h1>
      <p class="mt-2 leading-relaxed">{{ development.intro }}</p>
    </div>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ development.codeStyleTitle }}</h2>
      <ul class="ml-5 list-disc space-y-1.5">
        <li v-for="(item, i) in development.codeStyle" :key="i">{{ item }}</li>
      </ul>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ development.notesTitle }}</h2>
      <ul class="ml-5 list-disc space-y-1.5">
        <li v-for="(item, i) in development.notes" :key="i">{{ item }}</li>
      </ul>
    </section>

    <section>
      <h2 class="mb-3 text-xl font-semibold">{{ development.fileConventionsTitle }}</h2>
      <ul class="ml-5 list-disc space-y-1.5">
        <li v-for="(item, i) in development.fileConventions" :key="i">{{ item }}</li>
      </ul>
    </section>
  </div>
</template>