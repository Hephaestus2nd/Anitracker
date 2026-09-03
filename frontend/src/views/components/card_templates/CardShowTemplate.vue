<script setup>
const props = defineProps({
    animeData: {
        type: Object,
        required: true
    }
})
</script>

<template>
    <div class="card">
        <RouterLink :to="`/anime/${animeData.malId}`">
            <img :src="animeData.coverImageUrl" :alt="animeData.title" />
            <div class="anime-title">{{ animeData.title }}</div>
        </RouterLink>
    </div>
</template>

<style scoped>
div.card {
    padding: 0;

    > a {
        display: inline-grid;
        grid-template-rows: auto 1fr;
        justify-items: center;
        color: var(--color-text);

        > div.anime-title {
            padding: 8px;
            font-weight: bold;
            text-align: center;
        }

        > img {
            aspect-ratio: 2 / 3;
            width: 100%;
        }
    }
}
</style>