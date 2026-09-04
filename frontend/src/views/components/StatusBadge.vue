<script setup>
import { computed, inject } from 'vue'

const watchStatusLabels = inject('watchStatusLabels')
const props = defineProps({
    animeData: {
        type: Object,
        required: true
    }
})

const isCompleted = computed(() => {
    return props.animeData.watchStatus === watchStatusLabels.COMPLETED
})

const isDropped = computed(() => {
    return props.animeData.watchStatus === watchStatusLabels.DROPPED
})
</script>

<template>
    <div class="status-badge" :class="{ 'completed': isCompleted, 'dropped': isDropped }">{{ animeData.watchStatus }}</div>
</template>

<style scoped>
div.status-badge {
    font-size: var(--small-font-size);
    font-weight: bold;
    text-transform: uppercase;
    border: 1px solid var(--color-secondary-light);
    border-radius: var(--default-border-radius);
    padding: 2px 6px;
    user-select: none;

    &.completed {
        background: var(--color-secondary-light);
    }

    &.dropped {
        background: var(--color-secondary);
        border-color: var(--color-secondary);
    }
}

</style>