<script setup>
import { ref } from 'vue';

const searchQuery = ref('')

</script>

<template>
    <input type="search" id="search" placeholder="Search anime..." v-model="searchQuery" />
    <button type="button" class="emphasis" @click="$emit('search', searchQuery)">Search</button>
</template>

<style scoped></style>