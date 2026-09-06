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
    gap: 8px;
    height: 50vh;

    /* 
    Center placement w/o rows
    place-items = justify-items + align-items
    place-content = justify-content + align-content
    */
    place-items: center;
    place-content: center;
}
</style>