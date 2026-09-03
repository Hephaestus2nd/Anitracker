<script setup>
import { ref, watch } from 'vue'
import { useRoute } from 'vue-router'

const currRoute = useRoute()
const animeData = ref(null)

const loading = ref(true)
const error = ref('')

async function fetchAnimeData(malId) {
    loading.value = true
    error.value = ''
    try {
        const response = await fetch(`/api/anime/${malId}`)
        if (!response.ok) {
            throw new Error('Anime not found')
        }
        animeData.value = await response.json()
    } catch (fetchError) {
        animeData.value = null
        error.value = fetchError.message
    } finally {
        loading.value = false
    }
}

watch(() => currRoute.params.id, (newId) => {
    fetchAnimeData(newId)
}, { immediate: true })

</script>

<template>
    <p v-if="loading">Loading anime...</p>
    <p v-else-if="error">{{ error }}</p>
    <section v-else class="data-container">
        <div class="banner-section">
            <img class="banner" :src="animeData.backgroundImageUrl" :alt="`${animeData.title} Banner`">
        </div>

        <div class="cover-section">
            <img class="cover-pic" :src="animeData.coverImageUrl" :alt="animeData.title">
        </div>

        <section class="user-data">

        </section>
    </section>
</template>

<style scoped>
section.data-container {
    display: grid;
    grid-template-columns: 1fr 3fr;
    gap: var(--default-margin-value);
}

div {
    &.banner-section {
        grid-column: 1 / span 2;
    }

    &.cover-section {
        --margin-side: calc(var(--default-margin-value) * 2);

        margin-left: var(--margin-side);
        margin-right: var(--margin-side);
        margin-top: calc(-4 * var(--margin-side));
    }

    > img {
        border-radius: var(--default-border-radius);
    }

    > img.banner {
        position: relative; /* Need for the z-index to work */
        opacity: 0.5;
        z-index: -1; /* So as to not overlap */
    }
}
</style>