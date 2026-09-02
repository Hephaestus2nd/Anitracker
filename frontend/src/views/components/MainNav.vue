<script setup></script>

<template>
    <header>My Header</header>
</template>

<style scoped>
header {
    position: sticky;
    top: 0;
    background: var(--color-primary);
    z-index: 100;
    padding: 1rem;
    border-radius: 0 0 var(--default-border-radius) var(--default-border-radius); 
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05); /* Bottom border shadow */
}
</style>