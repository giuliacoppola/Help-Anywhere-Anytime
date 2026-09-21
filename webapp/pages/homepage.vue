<template>
    <div class="relative min-h-screen bg-gray-50 p-6">

        <!-- TITOLO -->
        <h1 class="text-2xl font-bold text-gray-800 mb-6">
            Aggiungi paziente o cura
        </h1>
        <div class="max-w-6xl mx-auto px-4 mt-10">
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">

                <!-- Aggiungi paziente -->
                <div
                    @click="navigateToAddPatient"
                    class="group cursor-pointer bg-white border border-gray-200 rounded-3xl p-6
             flex items-center justify-between
             min-h-[140px]
             hover:shadow-lg hover:border-gray-300
             transition-all duration-300"
                >
                    <div class="pr-4">
                        <h2 class="text-lg font-semibold text-gray-900 tracking-tight">
                            Aggiungi paziente
                        </h2>
                        <p class="text-sm text-gray-500 mt-2 leading-relaxed">
                            Registra un nuovo paziente e inizia la gestione.
                        </p>
                    </div>

                    <div
                        class="w-12 h-12 flex items-center justify-center rounded-full
               bg-violet-100 text-violet-600
               flex-shrink-0
               group-hover:bg-violet-200
               transition duration-300"
                    >
                        <svg
                            class="w-5 h-5"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            viewBox="0 0 24 24"
                        >
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M12 5v14m7-7H5" />
                        </svg>
                    </div>
                </div>

                <!-- Aggiungi farmaco -->
                <div
                    @click="navigateToAddMedications"
                    class="group cursor-pointer bg-white border border-gray-200 rounded-3xl p-6
             flex items-center justify-between
             min-h-[140px]
             hover:shadow-lg hover:border-gray-300
             transition-all duration-300"
                >
                    <div class="pr-4">
                        <h2 class="text-lg font-semibold text-gray-900 tracking-tight">
                            Aggiungi farmaco
                        </h2>
                        <p class="text-sm text-gray-500 mt-2 leading-relaxed">
                            Associa un nuovo farmaco a un paziente.
                        </p>
                    </div>

                    <div
                        class="w-12 h-12 flex items-center justify-center rounded-full
               bg-violet-100 text-violet-600
               flex-shrink-0
               group-hover:bg-violet-200
               transition duration-300"
                    >
                        <svg
                            class="w-5 h-5"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            viewBox="0 0 24 24"
                        >
                            <path stroke-linecap="round" stroke-linejoin="round"
                                  d="M12 5v14m7-7H5" />
                        </svg>
                    </div>
                </div>

            </div>
        </div>


        <!-- LISTA PAZIENTI -->
        <div class="flex items-center justify-between mt-16 mb-6">
            <h2 class="text-2xl font-semibold text-gray-800">
                Lista pazienti
            </h2>

            <button
                @click="toggleEditPatients"
                class="text-sm font-medium px-4 py-2 rounded-full transition"
                :class="editPatients
            ? 'bg-violet-600 text-white hover:bg-violet-700'
            : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
            >
                {{ editPatients ? 'Fine' : 'Modifica' }}
            </button>
        </div>

        <transition name="fade">
            <div v-if="showDeletedMessage" class="success-banner">
                <span class="check">✔</span>
                Paziente eliminato correttamente
            </div>
        </transition>

        <div v-if="loading" class="text-gray-500">Caricamento...</div>

        <div class="space-y-6">
            <div
                v-for="patient in patients"
                :key="patient.id"
                class="relative bg-white shadow-md p-4 rounded-xl
           flex flex-col sm:flex-row sm:items-center gap-4
           hover:shadow-lg transition"
            >

                <!-- 🔔 Badge -->
                <div
                    v-if="!editPatients && unreadByPatient[patient.id] > 0"
                    class="absolute top-3 right-3
               bg-red-600 text-white text-xs font-bold
               px-2 py-1 rounded-full"
                >
                    🔔 {{ unreadByPatient[patient.id] }}
                </div>

                <!-- Click area -->
                <div
                    class="flex items-center gap-4 flex-1 cursor-pointer"
                    @click="!editPatients && openPatient(patient.id)"
                >
                    <img
                        :src="getPatientAvatar(patient)"
                        alt="avatar"
                        class="w-14 h-14 rounded-full object-cover border-2 border-white shadow"
                    />

                    <div>
                        <p class="text-lg font-semibold text-gray-800">
                            {{ patient.name }} {{ patient.surname }}
                        </p>
                        <p class="text-gray-500 text-sm">
                            Clicca per visualizzare la cura del paziente
                        </p>
                    </div>
                </div>

                <!-- ELIMINA DESKTOP -->
                <button
                    v-if="editPatients"
                    @click="deletePatient(patient.id)"
                    class="hidden sm:block self-start mt-2
           text-sm text-red-600
           px-3 py-2 rounded-lg
           border border-red-200
           hover:bg-red-50
           transition"
                >
                    Elimina
                </button>

                <!-- ELIMINA MOBILE -->
                <button
                    v-if="editPatients"
                    @click="deletePatient(patient.id)"
                    class="sm:hidden w-full mt-2 text-sm text-red-600
               px-3 py-2 rounded-lg border border-red-200
               hover:bg-red-50 transition"
                >
                    Elimina
                </button>
            </div>

        </div>

    </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useNuxtApp, useRouter } from "nuxt/app";

const router = useRouter();
const { $supabase } = useNuxtApp();

const patients = ref([]);
const loading = ref(true);
const unreadByPatient = ref({})
const editPatients = ref(false)
const showDeletedMessage = ref(false)

const toggleEditPatients = () => {
    editPatients.value = !editPatients.value
}

const deletePatient = async (id) => {

    const confirmDelete = confirm("Sei sicuro di voler eliminare definitivamente questo paziente?")

    if (!confirmDelete) return

    // 1️⃣ elimina medications
    await $supabase.from('medications').delete().eq('patient_id', id)

    // 2️⃣ elimina alerts
    await $supabase.from('alerts').delete().eq('patient_id', id)

    // 3️⃣ elimina paziente
    const { error } = await $supabase.from('patients').delete().eq('id', id)

    if (error) {
        alert("Errore durante l'eliminazione")
        return
    }

    // aggiorna UI
    patients.value = patients.value.filter(p => p.id !== id)

    showDeletedMessage.value = true
    setTimeout(() => {
        showDeletedMessage.value = false
    }, 2000)
}

const fetchPatients = async () => {
    loading.value = true;

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

    if (!error) patients.value = data;
    loading.value = false;
};

const navigateToAddPatient = () => {
    router.push("/addPatient");
};

const navigateToAddMedications = () => {
    router.push("/addMedications");
};

const openPatient = (id) => {
    // pagina che creerai tu, es: /patients/[id].vue
    router.push(`/patients/${id}`);
};

const getPatientAvatar = (patient) => {
    if (patient.image_url) {
        return patient.image_url
    }

    const name = `${patient.name || ''} ${patient.surname || ''}`.trim()

    const colors = [
        'F87171', // red
        '60A5FA', // blue
        '34D399', // green
        'FBBF24', // yellow
        'A78BFA', // purple
        'FB923C', // orange
    ]

    const color = colors[patient.id % colors.length]

    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=${color}&color=FFFFFF&size=128&rounded=true`
}

const subscribeToUnreadAlerts = () => {
    $supabase
        .channel('alerts-per-patient')
        .on(
            'postgres_changes',
            {
                event: '*',
                schema: 'public',
                table: 'alerts',
            },
            () => {
                fetchUnreadAlertsByPatient()
            }
        )
        .subscribe()
}

const fetchUnreadAlertsByPatient = async () => {
    const {
        data: { user }
    } = await $supabase.auth.getUser()

    if (!user) return

    // 1️⃣ prendi gli id dei pazienti del carer
    const { data: patientsData, error: patientsError } = await $supabase
        .from('patients')
        .select('id')
        .eq('carer_id', user.id)

    if (patientsError || !patientsData?.length) {
        unreadByPatient.value = {}
        return
    }

    const patientIds = patientsData.map(p => p.id)

    // 2️⃣ prendi SOLO gli alert non letti di quei pazienti
    const { data: alerts, error } = await $supabase
        .from('alerts')
        .select('patient_id')
        .in('patient_id', patientIds)
        .or('is_read.is.null,is_read.is.false')

    if (error) return

    // 3️⃣ raggruppa per patient_id
    const map = {}
    for (const alert of alerts) {
        map[alert.patient_id] = (map[alert.patient_id] || 0) + 1
    }

    unreadByPatient.value = map
}

onMounted(() => {
    fetchPatients();
    fetchUnreadAlertsByPatient()
    subscribeToUnreadAlerts();
});
</script>
