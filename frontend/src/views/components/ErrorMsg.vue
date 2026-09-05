<script setup>
import WarningIcon from '@/assets/WarningIcon.vue';

defineProps({
    errorMsg: {
        type: String,
        required: false
    }
})
</script>

<template>
    <div class="error-message" role="alert">
        <WarningIcon class="icon" />
        <p>{{ errorMsg || 'An error occurred.' }}</p>
    </div>
</template>

<style scoped>
.error-message {
    padding: 0.75em 1em;
    background-color: var(--color-primary);
    border-left: 4px solid var(--color-secondary);
    color: var(--light-font-color);
    border-radius: var(--default-border-radius);
    text-align: left;
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: center;
    gap: 0.5rem;
}
</style>