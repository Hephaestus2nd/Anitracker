<script setup>
import { computed } from 'vue'

const props = defineProps({
    animeData: {
        type: Object,
        required: true
    }
})

const progressPercentage = computed(() => {
    if (!props.animeData.totalEpisodes || props.animeData.totalEpisodes === 0) return 0
    return Math.ceil((props.animeData.episodesWatched / props.animeData.totalEpisodes) * 100)
})
</script>

<template>
    <div class="progress-bar-container">
        <div class="progress-bg"></div>
        <div class="progress-bar"></div>
        <div class="progress-text">{{ progressPercentage + '%'}} ({{ animeData.episodesWatched }} out of {{ animeData.totalEpisodes }})</div>
    </div>
</template>

<style scoped>
div.progress-bar-container {
    width: 100%;
    display: grid;

    > * {
        width: 100%;
        grid-area: 1 / 1; /* Overlay trick -- force all descendants on row 1, col 1 */
        height: 1rem;
        border-radius: var(--default-border-radius);
        padding: 0 3px;
    }

    > div.progress-bar {
        background: var(--color-secondary-light);
        width: v-bind('progressPercentage + "%"');
    }

    > div.progress-bg {
        width: 100%;
        background: var(--color-secondary);
    }

    > div.progress-text {
        text-align: center;
        line-height: 1.4;
        font-size: var(--small-font-size);
        font-weight: bold;
        user-select: none;
    }
}
</style>