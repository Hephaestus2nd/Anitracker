<script setup>
const props = defineProps({
    progressInPercent: {
        type: Number,
        required: true
    }
})
</script>

<template>
    <div class="progress-bar">{{ progressInPercent + '%'}}</div>
</template>

<style scoped>
div.progress-bar {
    width: 100%;
    height: 1rem;
    border-radius: var(--default-border-radius);
    background: var(--color-secondary-light);
    text-align: center;
    line-height: 1.4;
    font-size: 0.75rem;
    font-weight: bold;
    width: max(v-bind('progressInPercent + "%"'), 14%);
    user-select: none;
}
</style>