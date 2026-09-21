<template>
    <div class="p-6">
        <h2>Piano Medicinale Giornaliero 💊</h2>
        <ul style="margin-top:20px;">
            <li>Aspirina - 09:00 ✅</li>
            <li>Metformina - 13:00 ⏳</li>
            <li>Vitamina D - 20:00 ⏳</li>
        </ul>


        <button @click="alert('Reminder attivato (mock)')" style="margin-top:20px;">
            Attiva Reminder Vocale
        </button>


        <div style="margin-top:30px;">
            <NuxtLink to="/">⬅️ Torna alla Home</NuxtLink>
        </div>
    </div>
</template>


<script setup>
// Mock interface
</script>


<style scoped>
h2 { font-size: 22px; font-weight: bold; }
li { margin-bottom: 8px; }
</style>