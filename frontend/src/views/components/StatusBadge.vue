<script setup>
const props = defineProps({
    animeData: {
        type: Object,
        required: true
    }
})
</script>

<template>
    <div class="status-badge">{{ animeData.watchStatus }}</div>
</template>

<style scoped>
div.status-badge {
    font-size: var(--small-font-size);
    font-weight: bold;
    text-transform: uppercase;
    border: 1px solid var(--color-secondary-light);
    border-radius: var(--default-border-radius);
    padding: 2px 6px;
}
</style>