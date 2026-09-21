<template>
    <div class="p-6 max-w-3xl mx-auto">
        <h1 class="text-2xl font-bold mb-6">Patients</h1>

        <!-- FORM DI INSERIMENTO -->
        <form @submit.prevent="addPatient" class="mb-8 p-4 border rounded-lg bg-gray-50 shadow-sm space-y-4">
            <div>
                <label class="block text-sm font-medium text-gray-700">Name</label>
                <input
                    v-model="form.name"
                    type="text"
                    required
                    class="mt-1 w-full border rounded-md px-3 py-2"
                    placeholder="Enter name"
                />
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700">Surname</label>
                <input
                    v-model="form.surname"
                    type="text"
                    required
                    class="mt-1 w-full border rounded-md px-3 py-2"
                    placeholder="Enter surname"
                />
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700">Date of Birth</label>
                <input
                    v-model="form.dateOfBirth"
                    type="date"
                    required
                    class="mt-1 w-full border rounded-md px-3 py-2"
                />
            </div>

            <button
                type="submit"
                class="w-full bg-blue-600 text-white py-2 rounded-md hover:bg-blue-700 transition"
            >
                Add Patient
            </button>

            <p v-if="formMessage" class="text-green-600 text-sm mt-2">{{ formMessage }}</p>
        </form>

        <!-- LISTA PAZIENTI -->
        <div v-if="loading" class="text-gray-500">Loading patients...</div>

        <div v-else>
            <table class="min-w-full border border-gray-300 rounded-md overflow-hidden">
                <thead class="bg-gray-100">
                <tr>
                    <th class="p-2 border">Name</th>
                    <th class="p-2 border">Surname</th>
                    <th class="p-2 border">Date of Birth</th>
                </tr>
                </thead>
                <tbody>
                <tr v-for="patient in patients" :key="patient.id" class="border-t hover:bg-gray-50">
                    <td class="p-2 border">{{ patient.name }}</td>
                    <td class="p-2 border">{{ patient.surname }}</td>
                    <td class="p-2 border">{{ formatDate(patient.dateOfBirth) }}</td>
                </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<script setup lang="ts">
import {useNuxtApp} from "nuxt/app";
import {onMounted, reactive, ref} from "vue";

const { $supabase } = useNuxtApp()
const patients = ref([])
const loading = ref(true)
const formMessage = ref('')
const form = reactive({
    name: '',
    surname: '',
    dateOfBirth: ''
})

// Funzione per formattare la data
const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString()
}

// Recupera i pazienti da Supabase
const loadPatients = async () => {
    loading.value = true
    const { data, error } = await $supabase.from('patients').select('*').order('id', { ascending: true })
    if (error) {
        console.error('Errore nel recupero dei pazienti:', error)
    } else {
        patients.value = data
    }
    loading.value = false
}


// Aggiungi un nuovo paziente
const addPatient = async () => {
    if (!form.name || !form.surname || !form.dateOfBirth) return

    const { error } = await $supabase.from('patients').insert([
        {
            name: form.name,
            surname: form.surname,
            dateOfBirth: form.dateOfBirth
        }
    ])

    if (error) {
        console.error('Errore durante l’inserimento:', error)
        formMessage.value = `❌ Errore: ${error.message}`
    } else {
        formMessage.value = '✅ Paziente aggiunto con successo!'
        await loadPatients() // aggiorna la tabella
        form.name = ''
        form.surname = ''
        form.dateOfBirth = ''
    }
}

onMounted(() => {
    loadPatients()
})

</script>
