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

        <div class="card-grid-container">
            <div class="card">
                <RouterLink to="/api/akiba-maid-war">
                    <img src="https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx151379-JxxgTgSViXZL.png" alt="Akiba Maid War" />
                    <div class="anime-title">Akiba Maid War</div>
                </RouterLink>
            </div>
        </div>
    </section>
</template>

<style scoped>
div.card {
    padding: 0;

    > a {
        display: inline-grid;
        grid-template-rows: auto 1fr;
        justify-items: center;
        color: var(--color-text);

        > div.anime-title {
            padding: 8px;
            font-weight: bold;
        }
    }
}


section.main-list {
    width: 100%;

    > header {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        align-items: baseline;
        width: 100%;

        > h2 {
            margin: 0;
        }

        > button {
            justify-self: end;
        }
    }
}

header.main-header {
    display: grid;
    grid-template-rows: repeat(2, auto);
    text-align: center;
    justify-items: center;
    align-items: center;
    gap: 0.75rem;
    padding: 40px;
    border-radius: var(--default-border-radius);
    background: linear-gradient(to right, var(--color-secondary), var(--color-secondary-light));

    > * {
        margin: 0;
        line-height: 1.2; /* So that the text heights are even */
    }
}
</style>