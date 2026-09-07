<script setup>
import { ref, watch, inject } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import MiniProgressBar from './components/MiniProgressBar.vue'
import StatusBadge from './components/StatusBadge.vue'
import ModalGeneric from './components/ModalGeneric.vue'
import EpisodesAndStatusFormSection from './components/EpisodesAndStatusFormSection.vue'
import FullBlockLoadingSpinner from './components/FullBlockLoadingSpinner.vue'
import ErrorMsg from './components/ErrorMsg.vue'

// Routing and Links
const apiLinks = inject('apiLinks')
const apiAnimeIdLink = ref('')
const linkAnimeId = useRoute() // ID extraction from links
const redirect = useRouter() // Redirect to homepage if entry deleted

// Anime data state
const loading = ref(false)
const fetchAnimeListErr = ref('')
const animeData = ref(null)
const origAnimeData = ref(null) // For backup

// Modals
const showDeleteModal = ref(false)
const showUpdateModal = ref(false)
const isUpdating = ref(false)
const deleteErr = ref('')
const updateErr = ref('')

const fetchAnimeData = async () => {
    loading.value = true
    fetchAnimeListErr.value = ''

    try {
        const response = await fetch(apiAnimeIdLink.value)

        if (!response.ok) {
            throw new Error('Anime not found')
        }

        animeData.value = await response.json()
        // animeData.value.backgroundImageUrl = animeData.value.backgroundImageUrl.replace(/\\/g, '')

        origAnimeData.value = { ...animeData.value }
    } catch (fetchError) {
        animeData.value = null
        fetchAnimeListErr.value = fetchError.message
    } finally {
        loading.value = false
    }
}

const deleteHandler = async () => {
    try {
        let response = await fetch(apiAnimeIdLink.value, {
            method: "DELETE",
        })

        if (!response.ok) {
            throw new Error(`Error ${response.status}: ${response.statusText}`);
        }

        redirect.push('/')
    } catch (deleteError) {
        deleteErr.value = deleteError.message
    }
}

const updateHandler = async () => {
    isUpdating.value = true

    try {
        let response = await fetch(apiAnimeIdLink.value, {
            method: "PUT",
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            body: JSON.stringify(animeData.value)
        })

        if (!response.ok) {
            throw new Error(`Error ${response.status}: ${response.statusText}`);
        }

        origAnimeData.value = { ...animeData.value }
        showUpdateModal.value = false
    } catch (updateError) {
        updateErr.value = updateError.message
    } 
}

// Helper Functions
const resetChanges = () => {
    animeData.value = { ...origAnimeData.value }
};

// Event Listeners
// Keep it reactive for any link changes and refresh automatically
// This also doubles as onMounted
watch(() => linkAnimeId.params.id, (newId) => {
    apiAnimeIdLink.value = `${apiLinks.API_ANIME}/${newId}`
    fetchAnimeData()
}, { immediate: true })

watch(() => showUpdateModal.value, (isShown) => {
    if (isShown) return;

    if (isUpdating.value) isUpdating.value = false; // Need because once it is updated, don't reset back to old state
    else resetChanges();
})

watch(() => showDeleteModal.value, (isShown) => {
    if (isShown) return;

    if (deleteErr) deleteErr.value = '';
})
</script>

<template>
    <FullBlockLoadingSpinner v-if="loading" message="Loading entry..." />
    <ErrorMsg v-else-if="fetchAnimeListErr" :error-msg="fetchAnimeListErr" />
    
    <section v-else class="data-container">
        <div class="banner-section">
            <img class="banner" :src="animeData.backgroundImageUrl" :alt="`${animeData.title} Banner`">
        </div>

        <!-- Left side -->
        <div class="cover-section">
            <img class="cover-pic" :src="animeData.coverImageUrl" :alt="animeData.title">
            
            <!-- Update Modal -->
            <button class="emphasis" @click="showUpdateModal = true">Update</button>
            <ModalGeneric v-model="showUpdateModal">
                <ErrorMsg v-if="updateErr" :error-msg="updateErr" />

                <form @submit.prevent="updateHandler">
                    <EpisodesAndStatusFormSection v-model="animeData" />

                    <div class="right-align-buttons">
                        <button type="button" @click="showUpdateModal = false">Go Back</button>
                        <button class="emphasis" type="submit">Update</button>
                    </div>
                </form>
            </ModalGeneric>

            <!-- Delete Modal -->
            <button @click="showDeleteModal = true">Delete</button>
            <ModalGeneric v-model="showDeleteModal">
                <p v-if="!deleteErr">Are you sure to delete this entry?</p>
                <ErrorMsg v-else :error-msg="deleteErr" />

                <div class="right-align-buttons">
                    <button type="button" class="emphasis" @click="showDeleteModal = false">Go Back</button>
                    <button v-if="!deleteErr"  @click="deleteHandler">Delete</button>
                </div>
            </ModalGeneric>
        </div>

        <!-- Right side -->
        <section>
            <header>
                <h1>{{ animeData.title }}</h1>
                <div class="status-section">
                    <MiniProgressBar :anime-data="animeData" />
                    <StatusBadge :anime-data="animeData" />
                </div>
            </header>

            <section>
                <h2>Synopsis</h2>
                <p v-html="animeData.synopsis"></p>
            </section>
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
        display: inline-flex;
        flex-direction: column;
        gap: var(--default-margin-value);
        min-width: 128px;
        
        > * {
            flex-shrink: 0;
        }
    }

    &.status-section {
        display: grid;
        grid-template-columns: 1fr auto;
        align-items: center;
        gap: var(--default-margin-value);
    }

    > img {
        border-radius: var(--default-border-radius);

        &.banner {
            position: relative; /* Need for the z-index to work */
            opacity: 0.5;
            z-index: -1; /* So as to not overlap */
            width: 100%;
            height: auto;
            display: block;
        }
    }
}
</style>