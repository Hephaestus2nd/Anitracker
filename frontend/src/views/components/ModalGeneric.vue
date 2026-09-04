<script setup>
// Cleaner two-way binding (both prop and emit)
const isModalOpen = defineModel({ required: true });

// @click.self so that when the bg is clicked, it autocloses
const close = () => { isModalOpen.value = false; }
</script>

<template>
    <Teleport to="#modal">
        <Transition>
            <div v-if="isModalOpen" class="modal-bg" @click.self="close">
                <div class="modal-content">
                    <slot />
                </div>
            </div>
        </Transition>
    </Teleport>
</template>

<style scoped>
/* Based on https://www.youtube.com/watch?v=n8py4b2VWj4 */
div.modal-bg {
    position: fixed;
    top: 0; 
    left: 0;
    width: 100vw;
    height: 100vh;
    background: rgba(0, 0, 0, 0.5);
    z-index: 999; /* Make sure that it is on top of the navbar */

    /* Centering */
    display: flex;
    justify-content: center;
    align-items: center;
}
</style>