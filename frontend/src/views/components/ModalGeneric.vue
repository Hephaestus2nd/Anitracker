<script setup>
const props = defineProps({
    // isModalOpen; need to name it modelValue so that we can link it in v-model for 2-way binding
    modelValue: {
        type: Boolean, 
        required: true
    }
})
</script>

<template>
    <Teleport to="#modal">
        <Transition>
            <div class="modal-bg">
                <div class="modal-content">
                    <slot />
                </div>
            </div>
        </Transition>
    </Teleport>
</template>

<style scoped></style>