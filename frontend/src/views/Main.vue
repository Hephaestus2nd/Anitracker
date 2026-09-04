<script setup>
import { onMounted, ref, watch, inject } from 'vue';
import AddIcon from '@/assets/AddIcon.vue';
import CardShowGrid from './components/card_templates/CardShowGrid.vue';
import ModalGeneric from './components/ModalGeneric.vue';
import EpisodesAndStatusFormSection from './components/EpisodesAndStatusFormSection.vue';
import SearchBarGeneric from './components/search/SearchBarGeneric.vue';
import SearchResult from './components/search/SearchResult.vue';

const watchStatusLabels = inject('watchStatusLabels')
const animeList = ref([])
const newAnimeData = ref({
    "malId": null,
    "title": null,
    "totalEpisodes": null,
    "episodesWatched": null,
    "watchStatus": null,
    "coverImageUrl": null,
    "backgroundImageUrl": null,
    "synopsis": null
})

const searchResults = ref(null)
const selectedNewAnimeToAdd = ref(null)

const loading = ref(false);
const isSearchDisabled = ref(false);
const error = ref('');

const showAddModal = ref(false)

async function fetchAnimeData() {
    try {
        const response = await fetch('/api/anime');
        if (!response.ok) {
            throw new Error('Unable to load anime');
        }
        animeList.value = await response.json();
    } catch (fetchError) {
        error.value = fetchError.message;
    } finally {
        loading.value = false;
    }
}

function addAnime() {
    console.log("Test:", JSON.parse(JSON.stringify(newAnimeData.value)))

    showAddModal.value = false

    // please refetch
    // await fetchAnimeList()
}

function searchAnime(query) {
    console.log("Searching for:", query)
    isSearchDisabled.value = true

    setTimeout(function () {
        searchResults.value = {
            "data": {
                "Page": {
                    "media": [
                        {
                            "idMal": 59636,
                            "title": {
                                "english": "Umamusume: Cinderella Gray"
                            },
                            "episodes": 13,
                            "coverImage": {
                                "extraLarge": "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx180516-lebpoKLkw6E3.jpg"
                            },
                            "bannerImage": "https://s4.anilist.co/file/anilistcdn/media/anime/banner/180516-qxKVBsTW6Czx.jpg",
                            "description": "Unbeknownst to those around her in the destitute countryside of Kasamatsu, the staggering potential of this ashen-haired \"Beast” will soon rock Japan with her feet and catapult her to the national stage—down the path of a legend. <br><br>\nFollow Oguri Cap and her insatiable appetite as the starting gates open on this Umamusume's hot-blooded Cinderella story! <br><br>\n\n(Source: It's Anime powered by REMOW, edited)"
                        },
                        {
                            "idMal": 61930,
                            "title": {
                                "english": "Umamusume: Cinderella Gray 2nd Cour"
                            },
                            "episodes": 10,
                            "coverImage": {
                                "extraLarge": "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx195240-hKcmllV6YHQT.jpg"
                            },
                            "bannerImage": "https://s4.anilist.co/file/anilistcdn/media/anime/banner/195240-HcuZvXcdT5aX.jpg",
                            "description": "The second half of <i>Umamusume: Cinderella Gray</i>. <br><br>\n\nHailing from the humble countryside, Oguri Cap has turned the racing world on its head. Her rampage through the national race scene seemed unstoppable... until it wasn't. Tamamo Cross, the current peak of racing, has bested the Beast and declared Oguri Cap her rival. <br><br>\n\nBut Oguri Cap can't afford to keep her attention on Tamamo Cross alone. One by one, racers from all over the world arrive in Japan, ready to demonstrate their own prowess. Up against the best the world has to offer, our ashen racer will need to reach beyond her limits if she wants to stand a chance… Keep those eyes peeled—a Cinderella story full of twists and turns lies ahead!<br><br>\n\n(Source: It's Anime powered by REMOW)\n"
                        }
                    ]
                }
            }
        }

        isSearchDisabled.value = false
    }, 1000);


    console.log("Executed after 1 second");
}

animeList.value = [
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

watch(() => selectedNewAnimeToAdd.value, (selected) => {
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
            <button class="emphasis icon-span-container" @click="showAddModal = true"><AddIcon />Add</button>

            <ModalGeneric v-model="showAddModal">
                <form @submit.prevent="addAnime">
                    <SearchBarGeneric v-model="isSearchDisabled" @search="searchAnime" />

                    <SearchResult v-if="searchResults" v-model="selectedNewAnimeToAdd" :result-data="searchResults"/>

                    <EpisodesAndStatusFormSection v-model="newAnimeData" />

                    <div class="right-align-buttons">
                        <button @click="showUpdateModal = false">Go Back</button>
                        <button class="emphasis icon-span-container" type="submit"><AddIcon />Add</button>
                    </div>
                </form>
            </ModalGeneric>
        </header>

    <!-- <p v-if="loading">Loading anime...</p>
    <p v-else-if="error">{{ error }}</p> -->
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