<script setup>
import { RouterLink } from 'vue-router';
</script>

<template>
    <RouterLink to="/">
        <div class="baybayin">ᜀᜈᜒᜆ᜕ᜍᜃ</div>
        <div class="logo-text">Anitracker</div>
    </RouterLink>
</template>

<style scoped>
a {
    display: grid;
    grid-template-rows: repeat(2, auto);
    justify-items: center;
    color: var(--color-text);

    &:hover {
        text-shadow: none;
    }
}

div.baybayin {
    --letter-tracking: 1.25rem;

    font-family: 'Noto Sans Tagalog', sans-serif;
    font-weight: 900;
    font-size: 0.75rem;
    letter-spacing: var(--letter-tracking);
    margin-right: calc(var(--letter-tracking) * -1);
    margin-bottom: -0.3rem;
}

.logo-text {
    font-size: 1.5rem;
}
</style>