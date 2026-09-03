<script setup>
import Logo from '@/assets/Logo.vue';

</script>

<template>
    <header>
        <Logo />
    </header>
</template>

<style scoped>
header {
    display: grid;
    grid-template-columns: auto 1fr auto;
    position: sticky;
    top: 0;
    background: var(--color-primary);
    z-index: 100;
    padding: 1rem;
    border-radius: 0 0 var(--default-border-radius) var(--default-border-radius); 
    box-shadow: 0 4px 6px var(--color-secondary); /* Bottom border shadow */
}
</style>