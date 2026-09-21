<template>
    <BackToHome />

    <div class="relative mb-8">
        <!-- Spazio sinistro (back icon area) -->
        <div class="absolute inset-y-0 left-0 w-16"></div>
        <!-- Titolo centrato -->
        <h1 class="text-3xl font-bold mb-6 text-center">
            Aggiungi un nuovo medicinale
        </h1>
        <!-- Spazio destro (simmetria) -->
        <div class="absolute inset-y-0 right-0 w-16"></div>
    </div>

    <div class="min-h-screen bg-gray-50 p-6">
        <div class="bg-white shadow-md rounded-xl p-6 max-w-xl mx-auto">

            <!-- SELECT paziente -->
            <!-- PAZIENTE (bloccato) -->
            <div class="mb-4">
                <label class="block font-semibold text-gray-700 mb-1">
                    Paziente
                </label>

                <div
                    class="w-full border border-gray-200 rounded-lg px-4 py-3
           bg-gray-100 text-gray-700"
                >
    <span v-if="selectedPatientObj">
      {{ selectedPatientObj.name }} {{ selectedPatientObj.surname }}
    </span>
                    <span v-else class="text-gray-500">
      Caricamento paziente...
    </span>
                </div>
            </div>


            <!-- Name -->
            <div class="mb-4">
                <label class="block font-semibold text-gray-700 mb-1">Nome medicinale</label>
                <input type="text" v-model="name" class="w-full border p-2 rounded-md" />
            </div>

            <!-- Quantity -->
            <div class="mb-4">
                <label class="block font-semibold text-gray-700 mb-1">Quantità</label>
                <input type="number" v-model="quantity" class="w-full border p-2 rounded-md" />
            </div>

            <!-- Image URL -->
            <div class="mb-4">
                <label class="block font-semibold text-gray-700 mb-1">URL immagine</label>
                <input type="text" v-model="image" class="w-full border p-2 rounded-md" placeholder="https://..." />
            </div>

            <!-- Hour -->
            <div class="mb-4">
                <label class="block font-semibold text-gray-700 mb-1">Ora di assunzione</label>
                <input type="time" v-model="hour" class="w-full border p-2 rounded-md" />
            </div>

            <!-- Submit -->
            <button
                @click="addMedication"
                class="w-full bg-blue-600 text-white py-2 rounded-md font-semibold hover:bg-blue-700 transition"
            >
                Aggiungi medicinale
            </button>

            <p v-if="success" class="mt-4 text-green-600 font-semibold text-center">
                ✔ Medicinale aggiunto correttamente!
            </p>

            <p v-if="errorMsg" class="mt-4 text-red-600 font-semibold text-center">
                ❌ {{ errorMsg }}
            </p>

        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, computed} from "vue";
import { useNuxtApp, useRouter, useRoute } from "nuxt/app";

const { $supabase } = useNuxtApp();
const router = useRouter();
const route = useRoute();

// Form fields
const name = ref("");
const quantity = ref(null);
const image = ref("");
const hour = ref("");

const patients = ref([]);
const lockedPatientId = ref(null);
const patientId =
    (route.query.id ? String(route.query.id) : null) ||
    (route.params.id ? String(route.params.id) : null);

const selectedPatient = ref(patientId || "");
const success = ref(false);
const errorMsg = ref("");

const selectedPatientObj = computed(() => {
    return patients.value.find(p => String(p.id) === String(selectedPatient.value));
});

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
    selectedPatient.value = patientId;
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