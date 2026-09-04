<script setup>
import { ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import MiniProgressBar from './components/MiniProgressBar.vue'
import StatusBadge from './components/StatusBadge.vue'
import ModalGeneric from './components/ModalGeneric.vue'
import EpisodesAndStatusFormSection from './components/EpisodesAndStatusFormSection.vue'

const currRoute = useRoute()
const router = useRouter()
const animeData = ref(null)

const loading = ref(false)
const error = ref('')

// Modals
const showDeleteModal = ref(false)
const showUpdateModal = ref(false)


const test = [
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

function fetchAnimeData(malId) {
    animeData.value = test.find(anime => anime.malId === Number(malId))
}

function deleteHandler() {
    console.log("Deleted")

    router.push('/')
}

function updateHandler() {
    console.log("Test:", JSON.parse(JSON.stringify(animeData.value)))

    showUpdateModal.value = false;
}

fetchAnimeData(currRoute.params.id)

// Keep it reactive for any link changes
// () => var_to_track, Event e => { what to do with Event e }
watch(() => currRoute.params.id, (newId) => {
    fetchAnimeData(newId)
})





// */

// async function fetchAnimeData(malId) {
//     loading.value = true
//     error.value = ''
//     try {
//         const response = await fetch(`/api/anime/${malId}`)
//         if (!response.ok) {
//             throw new Error('Anime not found')
//         }
//         animeData.value = await response.json()
//     } catch (fetchError) {
//         animeData.value = null
//         error.value = fetchError.message
//     } finally {
//         loading.value = false
//     }
// }

// watch(() => currRoute.params.id, (newId) => {
//     fetchAnimeData(newId)
// }, { immediate: true })

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
            
            <!-- Update Modal -->
            <button class="emphasis" @click="showUpdateModal = true">Update</button>
            <ModalGeneric v-model="showUpdateModal">
                <form @submit.prevent="updateHandler">
                    <EpisodesAndStatusFormSection v-model="animeData" />

                    <div class="right-align-buttons">
                        <button @click="showUpdateModal = false">Go Back</button>
                        <button class="emphasis" type="submit">Update</button>
                    </div>
                </form>
            </ModalGeneric>

            <!-- Delete Modal -->
            <button @click="showDeleteModal = true">Delete</button>
            <ModalGeneric v-model="showDeleteModal">
                <p>Are you sure to delete this entry?</p>

                <div class="right-align-buttons">
                    <button class="emphasis" @click="showDeleteModal = false">Go Back</button>
                    <button @click="deleteHandler">Delete</button>
                </div>
            </ModalGeneric>
        </div>

        <section class="user-data">
            <header>
                <h1>{{ animeData.title }}</h1>
                <div class="status-section">
                    <MiniProgressBar :anime-data="animeData" />
                    <StatusBadge :anime-data="animeData" />
                </div>
            </header>

            <section>
                <h2>Synopsis</h2>
                <p>{{ animeData.synopsis }}</p>
            </section>
        </section>
    </section>
</template>

<style scoped>
h1 {
    font-size: 3rem;
}

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
        display: inline-flex;
        flex-direction: column;
        gap: var(--default-margin-value);
        min-width: 128px;
        
        > * {
            flex-shrink: 0;
        }
    }

    > img {
        border-radius: var(--default-border-radius);
    }

    > img.banner {
        position: relative; /* Need for the z-index to work */
        opacity: 0.5;
        z-index: -1; /* So as to not overlap */
    }

    &.status-section {
        display: grid;
        grid-template-columns: 1fr auto;
        align-items: center;
        gap: var(--default-margin-value);
    }
}


</style>