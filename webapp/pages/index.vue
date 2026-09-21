<script setup>
</script>

<template>
    <section
        class="relative min-h-screen flex items-center justify-center bg-cover bg-center"
        style="background-image: url('/images/app_icon.png');"
    >
        <!-- Overlay -->
        <div class="absolute inset-0 bg-gradient-to-b from-black/70 via-black/60 to-black/80"></div>

        <!-- Content -->
        <div class="relative z-10 max-w-4xl mx-auto px-6 text-center text-white">

            <!-- Title -->
            <h1 class="text-4xl md:text-6xl font-extrabold mb-6 leading-tight">
                Help AnyWhere AnyTime
            </h1>

            <!-- Subtitle -->
            <p class="text-lg md:text-xl text-white-200 mb-8 max-w-2xl mx-auto">
                L’app innovativa che assiste anziani e caregiver nel riconoscimento dei farmaci,
                nel monitoraggio delle terapie e nella gestione quotidiana del paziente.
            </p>

            <!-- CTA -->
            <NuxtLink
                to="/auth"
                class="inline-block bg-blue-600 hover:bg-blue-700 transition px-8 py-4 rounded-full font-semibold text-lg shadow-xl mb-12"
            >
                Accedi o Registrati
            </NuxtLink>

            <!-- Features -->
            <div class="grid md:grid-cols-2 gap-4 max-w-3xl mx-auto">
                <div class="bg-white/10 backdrop-blur-md rounded-xl p-4">
                    ✔ Riconoscimento vocale dei medicinali
                </div>
                <div class="bg-white/10 backdrop-blur-md rounded-xl p-4">
                    ✔ Reminder intelligenti
                </div>
                <div class="bg-white/10 backdrop-blur-md rounded-xl p-4">
                    ✔ Interfaccia semplice per persone fragili
                </div>
                <div class="bg-white/10 backdrop-blur-md rounded-xl p-4">
                    ✔ Accessibile da web e app mobile
                </div>
            </div>

        </div>
    </section>
</template>



<style scoped>
</style>
