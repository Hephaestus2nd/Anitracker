<script setup>
import { onMounted, ref } from 'vue';
import AddIcon from '@/assets/AddIcon.vue';
import CardShowGrid from './components/card_templates/CardShowGrid.vue';

const animeData = ref([]);
const loading = ref(true);
const error = ref('');

async function fetchAnimeData() {
    try {
        const response = await fetch('/api/anime');
        if (!response.ok) {
            throw new Error('Unable to load anime');
        }
        animeData.value = await response.json();
    } catch (fetchError) {
        error.value = fetchError.message;
    } finally {
        loading.value = false;
    }
}

onMounted(fetchAnimeData);
</script>

<template>
    <header class="main-header">
        <h1>Welcome to <span class="logo-text">Anitracker</span>!</h1>
        <p>Keep your plan to watch list, currently watching list, and completed lists all in one place!</p>
    </header>

    <section class="main-list">
        <header>
            <h2>Anime in your list...</h2>
            <button class="emphasis icon-span-container"><AddIcon />Add</button>
        </header>

    <p v-if="loading">Loading anime...</p>
    <p v-else-if="error">{{ error }}</p>
    <CardShowGrid v-else :anime-data-array="animeData"/>
    </section>
</template>

<style scoped>
section.main-list {
    width: 100%;

    > header {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        align-items: baseline;
        width: 100%;

        > h2 {
            margin: 0;
        }

        > button {
            justify-self: end;
        }
    }
}

header.main-header {
    display: grid;
    grid-template-rows: repeat(2, auto);
    text-align: center;
    justify-items: center;
    align-items: center;
    gap: 0.75rem;
    padding: 40px;
    border-radius: var(--default-border-radius);
    background: linear-gradient(to right, var(--color-secondary), var(--color-secondary-light));

    > * {
        margin: 0;
        line-height: 1.2; /* So that the text heights are even */
    }
}
</style>