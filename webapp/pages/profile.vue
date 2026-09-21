<template>
    <div class="p-6">
        <h2>Profilo Caregiver 👤</h2>
        <p>Nome: Mario Rossi</p>
        <p>Ruolo: Caregiver</p>


        <div style="margin-top:20px;">
            <button @click="alert('Associazione paziente completata (mock)')">
                Associa Paziente
            </button>
        </div>


        <div style="margin-top:30px;">
            <NuxtLink to="/">⬅️ Torna alla Home</NuxtLink>
        </div>
    </div>
</template>


<script setup>
// Mock user profile
</script>


<style scoped>
h2 { font-size: 22px; font-weight: bold; }
</style>