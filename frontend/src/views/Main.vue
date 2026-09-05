<script setup>
import { onMounted, ref, watch, inject } from 'vue';
import AddIcon from '@/assets/AddIcon.vue';
import CardShowGrid from './components/card_templates/CardShowGrid.vue';
import ModalGeneric from './components/ModalGeneric.vue';
import EpisodesAndStatusFormSection from './components/EpisodesAndStatusFormSection.vue';
import SearchBarGeneric from './components/search/SearchBarGeneric.vue';
import SearchResult from './components/search/SearchResult.vue';
import ErrorMsg from './components/ErrorMsg.vue';
import FullBlockLoadingSpinner from './components/FullBlockLoadingSpinner.vue';

// Default template for adding anime
const defaultNewAnimeData = {
    "malId": null,
    "title": null,
    "totalEpisodes": null,
    "episodesWatched": null,
    "watchStatus": null,
    "coverImageUrl": null,
    "backgroundImageUrl": null,
    "synopsis": null
}

// API stuff
const watchStatusLabels = inject('watchStatusLabels')
const apiLinks = inject('apiLinks')
const apiQueries = inject('apiQueries')

// Main content 
const loading = ref(true);
const animeList = ref([])
const fetchAnimeListErr = ref('');

// Add Modal
const showAddModal = ref(false)
const isSearchDisabled = ref(false);
const searchResults = ref(null)
const searchAnimeNameErr = ref('');
const selectedNewAnimeToAdd = ref(null)
const newAnimeData = ref({ ...defaultNewAnimeData })

// Fetch stuff
const fetchAnimeData = async () => {
    try {
        const response = await fetch(apiLinks.API_ANIME);
        if (!response.ok) {
            throw new Error('Unable to load anime.');
        }
        animeList.value = await response.json();
    } catch (fetchError) {
        fetchAnimeListErr.value = fetchError.message;
    } finally {
        loading.value = false;
    }
}

const searchAnime = async (query) => {
    isSearchDisabled.value = true

    try {
        let response = await fetch(apiLinks.ANILIST_API, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            body: JSON.stringify({
                query: apiQueries.ANILIST_SEARCH_BY_TITLE,
                variables: {
                    "search": query
                }
            })
        })

        let result = await response.json() // Put this first so that we can read GraphQL errs.

        if (!response.ok || (result.errors && result.errors.length > 0)) {
            const errStatus = result.errors?.[0]?.status || response.status
            const errorMsg = result.errors?.[0]?.message || response.statusText

            throw new Error(`Error ${errStatus}: ${errorMsg}`);
        }

        searchResults.value = result
    } catch (fetchError) {
        searchAnimeNameErr.value = fetchError.message
    } finally {
        isSearchDisabled.value = false
    }
}

const addAnime = async () => {
    console.log("Test:", JSON.parse(JSON.stringify(newAnimeData.value)))

    showAddModal.value = false

    // please refetch
    // await fetchAnimeList()
}

// Utility functions
const resetForm = () => {
    isSearchDisabled.value = false;
    searchResults.value = null;
    selectedNewAnimeToAdd.value = null;
    newAnimeData.value = { ...defaultNewAnimeData };
};

// Event listeners
watch(() => selectedNewAnimeToAdd.value, (selected) => {
    // Skip if it came from closing the modal (which sets the thing to null)
    if (!showAddModal.value || selected === null) return; 

    // Shortcut way of assigning things instead of spamming newAnimeData.value
    Object.assign(newAnimeData.value, {
        "malId": selected.idMal,
        "title": selected.title.english || selected.title.romaji,
        "totalEpisodes": selected.episodes,
        "episodesWatched": 0,
        "watchStatus": watchStatusLabels.PLAN_TO_WATCH,
        "coverImageUrl": selected.coverImage.extraLarge || selected.coverImage.large,
        "backgroundImageUrl": selected.bannerImage,
        "synopsis": selected.description
    });

    console.log(newAnimeData.value)
})

watch(() => showAddModal.value, (isShown) => {
    if (!isShown) resetForm()
})

// Mount
onMounted(fetchAnimeData);

// animeList.value = [
//     {
//         "malId": 1,
//         "title": "Akiba Maid War",
//         "totalEpisodes": 12,
//         "episodesWatched": 12,
//         "watchStatus": "Completed",
//         "coverImageUrl": "https://cdn.myanimelist.net/images/anime/1217/129604.jpg",
//         "backgroundImageUrl": "https://s4.anilist.co/file/anilistcdn/media/anime/banner/151379-9adZHzFGBTpV.jpg",
//         "synopsis": "Nagomi's first day seems completely normal—until she has to run an \"errand\" at a rival maid cafe along with her fellow recruit, the mature Ranko Mannen. There, things quickly go south, and Nagomi soon gets her first taste of Akihabara's violent maid wars. As she watches Ranko calmly battle her way through a horde of gun- and knife-wielding maids, Nagomi realizes that maid cafes are drastically unlike what she had envisioned."
//     },
//     {
//         "malId": 2,
//         "title": "Frieren: Beyond Journey's End",
//         "totalEpisodes": 12,
//         "episodesWatched": 8,
//         "watchStatus": "Watching",
//         "coverImageUrl": "https://cdn.myanimelist.net/images/anime/1015/138006.jpg",
//         "backgroundImageUrl": "https://s4.anilist.co/file/anilistcdn/media/anime/banner/154587-ivXNJ23SM1xB.jpg",
//         "synopsis": "As the years pass, Frieren gradually realizes how her days in the hero's party truly impacted her. Witnessing the deaths of two of her former companions, Frieren begins to regret having taken their presence for granted; she vows to better understand humans and create real personal connections. Although the story of that once memorable journey has long ended, a new tale is about to begin."
//     },
//     {
//         "malId": 3,
//         "title": "Uma Musume: Cinderella Gray",
//         "totalEpisodes": 13,
//         "episodesWatched": 0,
//         "watchStatus": "Plan to Watch",
//         "coverImageUrl": "https://cdn.myanimelist.net/images/anime/1626/148097.jpg",
//         "backgroundImageUrl": "https://s4.anilist.co/file/anilistcdn/media/anime/banner/180516-qxKVBsTW6Czx.jpg",
//         "synopsis": "Tokyo is the home of national-level horse girls and the next generation of running prodigies. Jou Kitahara, a rookie trainer with big dreams and modest expectations, does not expect to find talent in the quiet town of Kasamatsu—until he meets an ash-gray-haired girl with a wild, unconventional stride."
//     }
// ]
</script>

<template>
    <header class="main-header">
        <h1>Welcome to <span class="logo-text">Anitracker</span>!</h1>
        <p>Keep your plan to watch list, currently watching list, and completed lists all in one place!</p>
    </header>

    <section class="main-list">
        <header>
            <h2>Anime in your list...</h2>

            <!-- Add Modal -->
            <button class="emphasis icon-span-container" @click="showAddModal = true"><AddIcon />Add</button>
            <ModalGeneric v-model="showAddModal">
                <form @submit.prevent="addAnime">
                    <SearchBarGeneric v-model="isSearchDisabled" @search="searchAnime" />

                    <ErrorMsg v-if="searchAnimeNameErr" :error-msg="searchAnimeNameErr" />
                    <SearchResult v-else-if="searchResults" v-model="selectedNewAnimeToAdd" :result-data="searchResults"/>

                    <EpisodesAndStatusFormSection v-model="newAnimeData" />

                    <div class="right-align-buttons">
                        <button @click="showAddModal = false">Go Back</button>
                        <button class="emphasis icon-span-container" type="submit" :disabled="isSearchDisabled || !selectedNewAnimeToAdd || !searchResults || !searchResults.data?.Page?.media"><AddIcon />Add</button>
                    </div>
                </form>
            </ModalGeneric>
        </header>

        <!-- Card List -->
        <FullBlockLoadingSpinner v-if="loading" message="Loading anime..." />
        <ErrorMsg v-else-if="fetchAnimeListErr" :error-msg="fetchAnimeListErr" />
        
        <CardShowGrid :anime-data-array="animeList"/>
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