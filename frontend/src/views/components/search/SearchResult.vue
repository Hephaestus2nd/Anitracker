<script setup>
import { computed } from 'vue';

const selectedAnime = defineModel({ required: true });

const props = defineProps({
    resultData: {
        type: Object, // Must be of the same format as AniList GraphQL API response for a media object
        required: true
    }
})

const dataArray = computed(() => {
    // Similar to null-conditional feature in C# (?) -- doesn't throw an error if null
    // If null, return an empty array
    return props.resultData.data?.Page?.media || []
})
</script>

<template>
    <select name="search-result-box" size="6" v-model="selectedAnime">
        <option v-if="dataArray.length === 0" disabled value="">
            No results found
        </option>

        <option v-else v-for="anime in dataArray" :key="anime.idMal" :value="anime">
            {{ anime.title.english || anime.title.romaji }} ({{ anime.episodes === null ? "Ongoing" : `${anime.episodes} eps.` }})
        </option>
    </select>
</template>

<style scoped>
select {
    margin-bottom: var(--default-margin-value);
    width: 100%;
    max-width: 360px;
    overflow-x: auto;
    overflow-y: auto;

    > option:disabled {
        color: var(--light-font-color);
        text-align: center;
    }
}
</style>