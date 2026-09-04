<script setup>
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
    return props.resultData?.data?.Page?.media || []
})
</script>

<template>
    <select name="search-result-box" size="5" v-model="selectedAnime">
        <option v-if="dataArray.value.length === 0" disabled value="">
            No results found
        </option>

        <option v-else v-for="anime in dataArray.value" :key="anime.idMal" :value="anime.title.english">
            {{ anime.title.english || anime.title.romaji }} ({{ anime.episodes }} eps.)
        </option>
    </select>
</template>

<style scoped></style>