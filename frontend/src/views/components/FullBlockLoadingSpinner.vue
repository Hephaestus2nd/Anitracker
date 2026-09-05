<script setup>
import LoadingSpinner from '@/assets/LoadingSpinner.vue';

const props = defineProps({
    message: {
        type: String, // Any valid CSS sizing units
        required: false,
        default: "Loading..."
    }
})
</script>

<template>
    <div class="loading-full-block">
        <LoadingSpinner size="32px" />
        {{ message }}
    </div>
</template>

<style scoped>
div.loading-full-block {
    display: grid;
    grid-template-rows: 1fr auto;
    justify-items: center;
    align-items: center;
    gap: 8px;
}
</style>