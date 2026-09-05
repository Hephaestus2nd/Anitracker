<script setup>
import { provide } from 'vue';
import { RouterView } from 'vue-router'
import MainNav from '@/views/components/MainNav.vue';
import { watchStatusLabels } from './helpers/watchStatusLabels';
import { apiLinks, apiQueries } from './helpers/apiStuff';

provide('watchStatusLabels', watchStatusLabels);
provide('apiLinks', apiLinks);
provide('apiQueries', apiQueries)
</script>

<template>
  <MainNav />

  <main>
    <RouterView />
  </main>
</template>

<style scoped></style>
