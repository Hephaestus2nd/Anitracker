<script setup>
import CardShowTemplate from './CardShowTemplate.vue';

const props = defineProps({
    animeDataArray: {
        type: Array, // Each item must match the same format as the schema
        required: true
    }
})
</script>

<template>
    <div class="card-grid-container">
        <CardShowTemplate v-for="animeData in animeDataArray" :key="animeData.malId" :anime-data="animeData" />
    </div>
</template>

<style scoped></style>