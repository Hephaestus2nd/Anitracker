<script setup>
import { provide } from 'vue';
import { RouterView } from 'vue-router'
import MainNav from '@/views/components/MainNav.vue';
import { watchStatusLabels } from './helpers/watchStatusLabels';

provide('watchStatusLabels', watchStatusLabels);
</script>

<template>
  <MainNav />

  <main>
    <RouterView />
  </main>
</template>

<style scoped></style>
