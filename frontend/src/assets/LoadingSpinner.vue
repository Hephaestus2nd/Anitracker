<script setup>
const props = defineProps({
    size: {
        type: String, // Any valid CSS sizing units
        required: false,
        default: "16px"
    }
})
</script>

<template>
    <svg class="spinner" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
        <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
    </svg>
</template>

<style scoped>
svg.spinner {
    width: v-bind(size);
    height: v-bind(size);
    animation: spin 1.3s linear infinite;
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}
</style>