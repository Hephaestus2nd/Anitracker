<script setup>
const props = defineProps({
    progressInPercent: {
        type: Number,
        required: true
    }
})
</script>

<template>
    <div class="progress-bar-container">
        <div class="progress-bg">{{ progressInPercent + '%'}}</div>
        <div class="progress-bar"></div>
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
        width: v-bind('progressInPercent + "%"');
    }

    > div.progress-bg {
        width: 100%;
        background: var(--color-secondary);
        text-align: center;
        line-height: 1.4;
        font-size: 0.75rem;
        font-weight: bold;
        user-select: none;
    }
}


</style>