<script setup>
const props = defineProps({
    animeData: {
        type: Object,
        required: true
    }
})
</script>

<template>
    <div class="card">
        <RouterLink to="/anime/akiba-maid-war">
            <img src="https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx151379-JxxgTgSViXZL.png"
                alt="Akiba Maid War" />
            <div class="anime-title">Akiba Maid War</div>
        </RouterLink>
    </div>
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
            text-align: center;
        }

        > img {
            aspect-ratio: 2 / 3;
            width: 100%;
        }
    }
}
</style>