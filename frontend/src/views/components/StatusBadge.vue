<script setup>
import { computed } from 'vue'

const props = defineProps({
    animeData: {
        type: Object,
        required: true
    }
})

const isCompleted = computed(() => {
    return props.animeData.watchStatus === 'Completed'
})

const isDropped = computed(() => {
    return props.animeData.watchStatus === 'Dropped'
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