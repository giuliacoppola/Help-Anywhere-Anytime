<template>

    <div class="min-h-screen bg-gray-50 p-6">

        <!-- Titolo -->
        <h1 class="text-3xl font-bold text-gray-900 mb-8 text-center">
            Aggiungi medicinale
        </h1>

        <!-- Card -->
        <div
            class="bg-white border border-gray-200 rounded-2xl p-8 max-w-xl mx-auto shadow-sm"
        >
            <div class="space-y-6">

                <!-- Paziente -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                        Paziente
                    </label>
                    <select
                        v-model="selectedPatient"
                        class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                               focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                        <option disabled value="">Seleziona un paziente</option>
                        <option v-for="p in patients" :key="p.id" :value="p.id">
                            {{ p.name }} {{ p.surname }}
                        </option>
                    </select>
                </div>

                <!-- Nome -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                        Nome medicinale
                    </label>
                    <input
                        v-model="name"
                        type="text"
                        placeholder="Es. Tachipirina"
                        class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                               focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                </div>

                <!-- Quantità -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                        Quantità
                    </label>
                    <input
                        v-model="quantity"
                        type="number"
                        placeholder="Es. 1"
                        class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                               focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                </div>

                <!-- Immagine -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                        Immagine (opzionale)
                    </label>
                    <input
                        v-model="image"
                        type="text"
                        placeholder="https://..."
                        class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                               focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                </div>

                <!-- Orario -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                        Ora di assunzione
                    </label>
                    <input
                        v-model="hour"
                        type="time"
                        class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                               focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                </div>

                <!-- CTA -->
                <button
                    @click="addMedication"
                    class="w-full rounded-xl bg-blue-600 text-white py-3 font-medium
                           hover:bg-blue-700 transition"
                >
                    Aggiungi medicinale
                </button>

                <!-- Success -->
                <p
                    v-if="success"
                    class="text-center text-sm font-medium text-green-600"
                >
                    ✔ Medicinale aggiunto correttamente
                </p>

                <!-- Error -->
                <p
                    v-if="errorMsg"
                    class="text-center text-sm font-medium text-red-600"
                >
                    {{ errorMsg }}
                </p>

            </div>
        </div>
    </div>
</template>


<script setup>
import { ref, onMounted } from "vue";
import { useNuxtApp, useRouter } from "nuxt/app";

const { $supabase } = useNuxtApp();
const router = useRouter();

// Form fields
const selectedPatient = ref("");
const name = ref("");
const quantity = ref(null);
const image = ref("");
const hour = ref("");

const patients = ref([]);

const success = ref(false);
const errorMsg = ref("");

// 1️⃣ Recupera pazienti del carer loggato
const fetchPatients = async () => {
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
        .eq("carer_id", user.id);

    if (error) {
        errorMsg.value = "Errore nel recupero dei pazienti";
        return;
    }

    patients.value = data;
};

// 2️⃣ Inserimento nuovo medicinale
const addMedication = async () => {
    success.value = false;
    errorMsg.value = "";

    if (!selectedPatient.value) {
        errorMsg.value = "Seleziona un paziente";
        return;
    }

    if (!name.value || !quantity.value || !hour.value) {
        errorMsg.value = "Compila tutti i campi obbligatori";
        return;
    }

    const { error } = await $supabase.from("medications").insert({
        name: name.value,
        quantity: quantity.value,
        image: image.value || null,
        hour: hour.value,
        patient_id: selectedPatient.value
    });

    if (error) {
        errorMsg.value = "Errore durante l'inserimento del medicinale";
        return;
    }

    success.value = true;

    // Reset fields
    name.value = "";
    quantity.value = null;
    image.value = "";
    hour.value = "";
    selectedPatient.value = "";
};

onMounted(() => {
    fetchPatients();
});
</script>
