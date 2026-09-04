<script setup>
import { ref } from 'vue';

const searchQuery = ref('')
const isSearchDisabled = defineModel({ required: true });
const emit = defineEmits(['search'])

const handleSearch = () => {
    emit('search', searchQuery.value)
    isSearchDisabled.value = true
}

</script>

<template>
    <div class="search-bar">
        <input type="search" id="search" placeholder="🔍︎ Search anime..." v-model="searchQuery" />
        <button type="button" class="emphasis" :disabled="isSearchDisabled" @click="handleSearch">{{ isSearchDisabled ? '...' : 'Search' }}</button>
    </div>
</template>

<style scoped>
div.search-bar {
    display: grid;
    grid-template-columns: 2fr 0.5fr;
    gap: var(--default-margin-value);
    margin-bottom: var(--default-margin-value);
}
</style>