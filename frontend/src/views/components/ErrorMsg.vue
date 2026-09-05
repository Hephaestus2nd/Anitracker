<script setup>
import WarningIcon from '../assets/icons/WarningIcon.vue'

defineProps({
    errorMsg: {
        type: String,
        required: false
    }
})
</script>

<template>
    <div class="error-message" role="alert">
        <WarningIcon class="error-icon" />
        <p>{{ errorMsg || 'An error occurred.' }}</p>
    </div>
</template>

<style scoped>
.error-message {
    padding: 0.75em 1em;
    background-color: #fee2e2;
    border-left: 4px solid #dc2626;
    color: #991b1b;
    border-radius: 4px;
    font-size: 0.9rem;
    text-align: left;
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
}

.error-icon {
    width: 20px;
    height: 20px;
    flex-shrink: 0;
    color: #dc2626;
    margin: 0;
}
</style>