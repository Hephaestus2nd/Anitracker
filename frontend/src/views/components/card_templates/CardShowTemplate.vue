<script setup>
const props = defineProps({
    animeData: {
        type: Object, // Must match the same format as the schema
        required: true
    }
})
</script>

<template>
    <div class="card">
        <div
            v-if="animeData.backgroundImageUrl"
            class="anime-banner"
            :style="{ backgroundImage: `url(${animeData.backgroundImageUrl})` }"
            aria-hidden="true"
        ></div>
        <RouterLink :to="`/anime/${animeData.malId}`">
            <img class="cover-pic" :src="animeData.coverImageUrl" :alt="animeData.title" />
            <div class="anime-title">{{ animeData.title }}</div>
        </RouterLink>
    </div>
</template>

<style scoped>
div.card {
    padding: 0;
    overflow: hidden;

    > div.anime-banner {
        aspect-ratio: 3 / 1;
        background-position: center;
        background-size: cover;
    }

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
    }
}
</style>