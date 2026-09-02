<script setup></script>

<template>
    <header>
        <h1>Welcome to Anitracker!</h1>
        <p>Keep your plan to watch list, currently watching list, and completed lists all in one place!</p>
    </header>
</template>

<style scoped>
* {
    justify-self: center;
    align-self: center;
}

header {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    width: 85vw;
    height: 25vh;
    padding: 0 20px;
    border-radius: var(--default-border-radius);
    background: linear-gradient(to right, var(--color-secondary), var(--color-secondary-light));
}
</style>