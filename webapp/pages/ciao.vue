<template>
    <div class="min-h-screen bg-gray-50 p-6">
        <button
                @click="router.back()"
                class="mb-6 px-4 py-2 bg-gray-200 rounded-md hover:bg-gray-300 transition"
        >
            ← Torna indietro
        </button>

        <div class="bg-white shadow-md rounded-xl p-6 max-w-xl mx-auto">
            <h1 class="text-2xl font-bold mb-6">Dettagli paziente</h1>

            <!-- Avatar -->
            <div class="flex justify-center mb 6">
                <img
                        src="https://i.pravatar.cc/150?u={{ id }}"
                        alt="avatar"
                        class="w-24 h-24 rounded-full object-cover shadow"
                />
            </div>

            <!-- Form -->
            <div class="space-y-4">
                <div>
                    <label class="block text-gray-700 font-semibold mb-1">Nome</label>
                    <input
                            type="text"
                            v-model="name"
                            class="w-full border p-2 rounded-md"
                    />
                </div>

                <div>
                    <label class="block text-gray-700 font-semibold mb-1">Cognome</label>
                    <input
                            type="text"
                            v-model="surname"
                            class="w-full border p-2 rounded-md"
                    />
                </div>

                <div>
                    <label class="block text-gray-700 font-semibold mb-1">
                        Data di nascita
                    </label>
                    <input
                            type="date"
                            v-model="dateOfBirth"
                            class="w-full border p-2 rounded-md"
                    />
                </div>
            </div>

            <!-- Bottone salva -->
            <button
                    @click="savePatient"
                    class="mt-6 w-full bg-blue-600 text-white py-2 rounded-md font-semibold hover:bg-blue-700 transition"
            >
                Salva modifiche
            </button>

            <p v-if="success" class="mt-4 text-green-600 font-semibold">
                ✔ Modifiche salvate con successo!
            </p>

            <p v-if="errorMsg" class="mt-4 text-red-600 font-semibold">
                ❌ {{ errorMsg }}
            </p>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useRoute, useRouter, useNuxtApp } from "nuxt/app";

const route = useRoute();
const router = useRouter();
const { $supabase } = useNuxtApp();

const id = route.params.id;

const name = ref("");
const surname = ref("");
const dateOfBirth = ref("");

const success = ref(false);
const errorMsg = ref("");

// Fetch dati paziente
const fetchPatient = async () => {
    const {
        data: { user }
    } = await $supabase.auth.getUser();

    if (!user) {
        router.push("/auth");
        return;
    }

    const { data, error } = await $supabase
        .from("patients")
        .select("*")
        .eq("id", id)
        .eq("carer_id", user.id)
        .single();

    if (error) {
        errorMsg.value = "Errore nel recupero dei dati.";
        return;
    }

    name.value = data.name;
    surname.value = data.surname;
    dateOfBirth.value = data.dateOfBirth;
};

// Salvataggio modifiche
const savePatient = async () => {
    const { error } = await $supabase
        .from("patients")
        .update({
            name: name.value,
            surname: surname.value,
            dateOfBirth: dateOfBirth.value
        })
        .eq("id", id);

    if (error) {
        errorMsg.value = "Impossibile salvare le modifiche.";
        return;
    }

    success.value = true;
    setTimeout(() => (success.value = false), 2000);
};

onMounted(() => {
    fetchPatient();
});
</script>
