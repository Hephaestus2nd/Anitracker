<script setup>
import { watch } from 'vue'

const animeData = defineModel({ required: true });

watch(() => animeData.value.watchStatus, (newStatus) => {
    switch (newStatus) {
        case 'Completed':
            animeData.value.episodesWatched = animeData.value.totalEpisodes
            break;
        case 'Plan to Watch':
            animeData.value.episodesWatched = 0;
            break;
    }
})

watch(() => animeData.value.episodesWatched, (updatedWatchedEp) => {
    // Need v-model.number="animeData.episodesWatched" instead of :value so that it reacts accordingly 
    
    if (updatedWatchedEp === animeData.value.totalEpisodes) {
        animeData.value.watchStatus = 'Completed'
    }
})
</script>

<template>
    <label for="watchStatus">Status</label>
    <select name="watchStatus" id="watchStatus" v-model="animeData.watchStatus">
        <option value="Plan to Watch">Plan to Watch</option>
        <option value="Watching">Watching</option>
        <option value="On-Hold">On Hold</option>
        <option value="Dropped">Dropped</option>
        <option value="Completed">Completed</option>
    </select>

    <label for="episodesWatched">Episodes Watched</label>
    <input type="number" name="episodesWatched" id="episodesWatched" min="0" 
        v-model.number="animeData.episodesWatched"
        :max="animeData.totalEpisodes"
        :disabled="animeData.watchStatus === 'Completed' || animeData.watchStatus === 'Plan to Watch'">
</template>

<style scoped></style>