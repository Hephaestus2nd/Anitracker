<script setup>
import { onMounted, ref } from 'vue';
import AddIcon from '@/assets/AddIcon.vue';
import CardShowGrid from './components/card_templates/CardShowGrid.vue';

const animeData = ref([]);

const loading = ref(false);
const error = ref('');

const showAddModal = ref(false)

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

animeData.value = [
    {
        "malId": 1,
        "title": "Akiba Maid War",
        "totalEpisodes": 12,
        "episodesWatched": 12,
        "watchStatus": "Completed",
        "coverImageUrl": "https://cdn.myanimelist.net/images/anime/1217/129604.jpg",
        "backgroundImageUrl": "https://s4.anilist.co/file/anilistcdn/media/anime/banner/151379-9adZHzFGBTpV.jpg",
        "synopsis": "Nagomi's first day seems completely normal—until she has to run an \"errand\" at a rival maid cafe along with her fellow recruit, the mature Ranko Mannen. There, things quickly go south, and Nagomi soon gets her first taste of Akihabara's violent maid wars. As she watches Ranko calmly battle her way through a horde of gun- and knife-wielding maids, Nagomi realizes that maid cafes are drastically unlike what she had envisioned."
    },
    {
        "malId": 2,
        "title": "Frieren: Beyond Journey's End",
        "totalEpisodes": 12,
        "episodesWatched": 8,
        "watchStatus": "Watching",
        "coverImageUrl": "https://cdn.myanimelist.net/images/anime/1015/138006.jpg",
        "backgroundImageUrl": "https://s4.anilist.co/file/anilistcdn/media/anime/banner/154587-ivXNJ23SM1xB.jpg",
        "synopsis": "As the years pass, Frieren gradually realizes how her days in the hero's party truly impacted her. Witnessing the deaths of two of her former companions, Frieren begins to regret having taken their presence for granted; she vows to better understand humans and create real personal connections. Although the story of that once memorable journey has long ended, a new tale is about to begin."
    },
    {
        "malId": 3,
        "title": "Uma Musume: Cinderella Gray",
        "totalEpisodes": 13,
        "episodesWatched": 0,
        "watchStatus": "Plan to Watch",
        "coverImageUrl": "https://cdn.myanimelist.net/images/anime/1626/148097.jpg",
        "backgroundImageUrl": "https://s4.anilist.co/file/anilistcdn/media/anime/banner/180516-qxKVBsTW6Czx.jpg",
        "synopsis": "Tokyo is the home of national-level horse girls and the next generation of running prodigies. Jou Kitahara, a rookie trainer with big dreams and modest expectations, does not expect to find talent in the quiet town of Kasamatsu—until he meets an ash-gray-haired girl with a wild, unconventional stride."
    }
]

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

    <!-- <p v-if="loading">Loading anime...</p>
    <p v-else-if="error">{{ error }}</p> -->
    <CardShowGrid :anime-data-array="animeData"/>
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