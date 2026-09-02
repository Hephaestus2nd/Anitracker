<script setup>
import AddIcon from '@/assets/AddIcon.vue';

</script>

<template>
    <header class="main-header">
        <h1>Welcome to <span class="logo-text">Anitracker</span>!</h1>
        <p>Keep your plan to watch list, currently watching list, and completed lists all in one place!</p>
    </header>

    <section class="main-list">
        <header>
            <h2>Anime in your list...</h2>
            <button class="emphasis icon-span-container"><AddIcon />Add</button>
        </header>
        <div class="card-grid-container"></div>
    </section>
</template>

<style scoped>
* {
    justify-self: center;
    align-self: center;
}

section.main-list {
    width: 100%;

    > header {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        align-items: baseline;
        width: 100%;

        > h2 {
            justify-self: start;
            margin: 0;
        }

        > button {
            align-self: center;
            justify-self: end;
        }
    }
}

header.main-header {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    width: inherit;
    height: clamp(176px, 25vh, 240px);
    padding: 0 20px;
    border-radius: var(--default-border-radius);
    background: linear-gradient(to right, var(--color-secondary), var(--color-secondary-light));
}
</style>