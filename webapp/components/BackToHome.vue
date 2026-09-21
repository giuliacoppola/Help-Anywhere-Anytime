<template>
    <button
        @click="goHome"
        class="fixed top-6 left-6 z-50
               w-10 h-10
               grid place-items-center
               bg-white border border-gray-200
               rounded-full
               text-gray-600 hover:text-gray-900
               shadow-sm hover:shadow transition"
        aria-label="Torna alla home"
    >
        <span class="text-xl leading-none">←</span>
    </button>
</template>

<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()

const goHome = () => {
    router.push('/homepage')
}
</script>
