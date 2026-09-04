<script setup>
// Cleaner two-way binding (both prop and emit)
const isModalOpen = defineModel({ required: true });

// @click.self so that when the bg is clicked, it autocloses
const close = () => { isModalOpen.value = false; }
</script>

<template>
    <Teleport to="#modal">
        <Transition name="modal">
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
div {
    &.modal-bg {
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

    &.modal-content {
        background: var(--bg);
        border-radius: var(--default-border-radius);
        padding: var(--default-margin-value);
        box-shadow: var(--drop-shadow);
    }
}

.modal-enter-active, .modal-leave-active {
    transition: all 0.25s ease;
}

.modal-enter-from, .modal-leave-to {
    opacity: 0;
}
</style>