<script setup>
import { watch, inject } from 'vue'

const animeData = defineModel({ required: true });
const watchStatusLabels = inject('watchStatusLabels')


watch(() => animeData.value.watchStatus, (newStatus) => {
    switch (newStatus) {
        case watchStatusLabels.COMPLETED:
            animeData.value.episodesWatched = animeData.value.totalEpisodes
            break;
        case watchStatusLabels.PLAN_TO_WATCH:
            animeData.value.episodesWatched = 0;
            break;
    }
})

watch(() => animeData.value.episodesWatched, (updatedWatchedEp) => {
    // Need v-model.number="animeData.episodesWatched" instead of :value so that it reacts accordingly 

    if (updatedWatchedEp === animeData.value.totalEpisodes) {
        animeData.value.watchStatus = watchStatusLabels.COMPLETED
    }
})
</script>

<template>
    <label for="watchStatus">Status</label>
    <select name="watchStatus" id="watchStatus" v-model="animeData.watchStatus">
        <option :value="watchStatusLabels.PLAN_TO_WATCH">{{ watchStatusLabels.PLAN_TO_WATCH }}</option>
        <option :value="watchStatusLabels.WATCHING">{{ watchStatusLabels.WATCHING }}</option>
        <option :value="watchStatusLabels.ON_HOLD">{{ watchStatusLabels.ON_HOLD }}</option>
        <option :value="watchStatusLabels.DROPPED">{{ watchStatusLabels.DROPPED }}</option>
        <option :value="watchStatusLabels.COMPLETED">{{ watchStatusLabels.COMPLETED }}</option>
    </select>

    <label for="episodesWatched">Episodes Watched</label>
    <input type="number" name="episodesWatched" id="episodesWatched" min="0" 
        v-model.number="animeData.episodesWatched"
        :max="animeData.totalEpisodes"
        :disabled="animeData.watchStatus === watchStatusLabels.COMPLETED || animeData.watchStatus === watchStatusLabels.PLAN_TO_WATCH">
</template>

<style scoped></style>