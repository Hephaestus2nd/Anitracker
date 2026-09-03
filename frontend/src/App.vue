<script setup>
import { RouterView } from 'vue-router'
import MainNav from '@/views/components/MainNav.vue';
</script>

<template>
  <MainNav />

  <main>
    <RouterView />
  </main>
</template>

<style scoped></style>
