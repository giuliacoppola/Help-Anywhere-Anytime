<template>
    <BackToHome />

    <transition name="fade">
        <div v-if="showCreatedMessage" class="success-banner">
            <span class="check">✔</span>
            Paziente inserito correttamente
        </div>
    </transition>

    <div class="min-h-screen bg-gray-50 p-6">
        <!-- Header + Avatar -->
        <div class="flex flex-col items-center text-center mb-8">

            <h1 class="text-3xl font-bold text-gray-800 mb-4">
                {{ patient.name }} {{ patient.surname }}
            </h1>

            <div class="avatar-wrapper">
                <img
                    :src="getAvatarUrl(patient)"
                    alt="Patient avatar"
                    class="avatar-img"
                />
            </div>

        </div>



        <!-- Info paziente -->
        <div class="bg-white p-4 rounded-xl shadow mb-8">
            <h2 class="text-xl font-semibold mb-2">Informazioni</h2>
            <p><b>Data di nascita:</b> {{ patient.dateOfBirth }}</p>
        </div>

        <!-- Piano farmaci -->
        <div class="bg-white p-4 rounded-xl shadow">
            <div class="flex items-center justify-between mb-4">
                <h2 class="text-xl font-semibold">
                    Piano farmaci
                </h2>

                <button
                    @click="toggleEditMedications"
                    class="text-sm font-medium px-4 py-2 rounded-full transition"
                    :class="editMedications
        ? 'bg-blue-600 text-white hover:bg-blue-700'
        : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
                >
                    {{ editMedications ? 'Salva' : 'Modifica' }}
                </button>

            </div>

            <transition name="fade">
                <div v-if="showSavedMessage" class="success-banner">
                    <span class="check">✔</span>
                    Modifiche salvate
                </div>
            </transition>

            <div v-if="loadingMeds" class="text-gray-500">Caricamento...</div>

            <!-- Nessun medicinale -->
            <div v-else-if="medications.length === 0" class="text-gray-500">
                Nessun medicinale assegnato a questo paziente.
            </div>

            <!-- Lista medicinali -->
            <div v-else class="space-y-4">
                <div
                    v-for="med in medications"
                    :key="med.id"
                    class="flex flex-col sm:flex-row sm:items-center gap-4 bg-gray-100 p-4 rounded-lg shadow-sm"
                >
                    <!-- Immagine -->
                    <img
                        :src="med.image || 'https://via.placeholder.com/80?text=Med'"
                        alt="medicine"
                        class="w-16 h-16 rounded-lg object-cover"
                    />

                    <!-- Info -->
                    <div class="flex-1 space-y-2">
                        <p class="text-lg font-semibold">
                            {{ med.name }}
                        </p>

                        <!-- ORARIO -->
                        <div class="flex items-center gap-2 text-gray-600">
                            <b>Orario:</b>

                            <span v-if="!editMedications">
        {{ med.hour.slice(0, 5) }}
      </span>

                            <input
                                v-else
                                type="time"
                                v-model="med.hour"
                                @change="markAsEdited(med.id)"
                                class="rounded-lg border border-gray-300 px-2 py-1 text-sm"
                            />
                        </div>

                        <!-- QUANTITÀ -->
                        <div class="flex items-center gap-2 text-gray-600">
                            <b>Quantità:</b>

                            <span v-if="!editMedications">
        {{ med.quantity }}
      </span>

                            <input
                                v-else
                                type="number"
                                min="1"
                                v-model.number="med.quantity"
                                @change="markAsEdited(med.id)"
                                class="w-20 rounded-lg border border-gray-300 px-2 py-1 text-sm"
                            />
                        </div>

                        <!-- 🔴 ELIMINA SOLO MOBILE -->
                        <button
                            v-if="editMedications"
                            @click="deleteMedication(med.id)"
                            class="sm:hidden mt-2 w-full text-sm text-red-600
             px-3 py-2 rounded-lg border border-red-200
             hover:bg-red-50 transition"
                        >
                            Elimina
                        </button>
                    </div>

                    <!-- 🔴 ELIMINA SOLO DESKTOP -->
                    <button
                        v-if="editMedications"
                        @click="deleteMedication(med.id)"
                        class="hidden sm:block ml-4 text-sm text-red-600
           px-3 py-2 rounded-lg hover:bg-red-50 transition"
                    >
                        Elimina
                    </button>
                </div>

            </div>
        </div>

        <!-- Pulsante modifica cura -->
        <button
            @click="goToEditMedications"
            class="w-full bg-blue-600 text-white py-3 rounded-xl hover:bg-blue-700"
        >
            Aggiungi medicinale alla cura del paziente
        </button>

        <!-- ========================= -->
        <!--  SEZIONE NOTIFICHE -->
        <!-- ========================= -->

        <div class="mt-12">
            <div class="flex items-center justify-between mb-6">
                <h2 class="text-2xl font-bold text-gray-900">
                    Notifiche
                </h2>

                <!-- Toggle -->
                <div class="flex bg-gray-100 rounded-full p-1">
                    <button
                        @click="switchTab('unread')"
                        class="px-4 py-1.5 text-sm rounded-full transition"
                        :class="alertTab === 'unread'
                    ? 'bg-white shadow text-gray-900 font-medium'
                    : 'text-gray-500'"
                    >
                        Da leggere
                    </button>
                    <button
                        @click="switchTab('read')"
                        class="px-4 py-1.5 text-sm rounded-full transition"
                        :class="alertTab === 'read'
                    ? 'bg-white shadow text-gray-900 font-medium'
                    : 'text-gray-500'"
                    >
                        Lette
                    </button>
                </div>
            </div>

            <div v-if="loadingAlerts" class="text-gray-500">
                Caricamento notifiche...
            </div>

            <!-- ===== DA LEGGERE ===== -->
            <div v-if="alertTab === 'unread'">
                <div v-if="unreadAlerts.length === 0" class="text-gray-500">
                    Nessuna notifica da leggere.
                </div>

                <div v-else class="space-y-4">
                    <div
                        v-for="alert in unreadAlerts"
                        :key="alert.id"
                        class="flex justify-between items-start gap-4
                   bg-white border border-red-300
                   rounded-2xl p-4 shadow-sm"
                    >
                        <!-- Contenuto -->
                        <div class="flex-1">
                            <div class="flex items-center gap-2 mb-1">
                    <span class="text-sm font-semibold text-red-600">
                        🚨 {{ alert.intent }}
                    </span>
                                <span class="text-xs text-gray-400">
                        {{ formatDate(alert.created_at) }}
                    </span>
                            </div>

                            <p class="text-sm text-gray-700 mb-1">
                                <b>Transcript:</b> {{ alert.transcription }}
                            </p>

                            <p class="text-sm text-gray-600">
                                <b>Risposta AI:</b> {{ alert.ai_response }}
                            </p>
                        </div>

                        <!-- Azione -->
                        <button
                            @click="confirmAlert(alert.id)"
                            class="px-4 py-2 rounded-xl text-sm font-medium
                       bg-green-600 text-white
                       hover:bg-green-700 transition"
                        >
                            Conferma
                        </button>
                    </div>
                </div>
            </div>

            <!-- ===== LETTE ===== -->
            <div v-if="alertTab === 'read'">
                <div v-if="readAlertsAll.length === 0" class="text-gray-500">
                    Nessuna notifica letta.
                </div>

                <div v-else class="space-y-4">
                    <div
                        v-for="alert in readAlertsVisible"
                        :key="alert.id"
                        class="flex justify-between items-start gap-4
                   bg-gray-50 border border-gray-200
                   rounded-2xl p-4"
                    >
                        <div class="flex-1">
                            <div class="flex items-center gap-2 mb-1">
                    <span class="text-sm font-semibold text-gray-600">
                        {{ alert.intent }}
                    </span>
                                <span class="text-xs text-gray-400">
                        {{ formatDate(alert.created_at) }}
                    </span>
                            </div>

                            <p class="text-sm text-gray-600">
                                {{ alert.transcription }}
                            </p>
                        </div>

                        <span class="text-sm font-medium text-green-600">
                ✔ Confermata
            </span>
                    </div>

                    <!-- Vedi di più -->
                    <div v-if="readAlertsVisible.length < readAlertsAll.length" class="pt-2">
                        <button
                            @click="loadMoreReadAlerts"
                            class="w-full text-sm font-medium text-blue-600
                       hover:underline"
                        >
                            Vedi di più
                        </button>
                    </div>
                </div>
            </div>

        </div>

    </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useNuxtApp, useRouter, useRoute } from "nuxt/app";
import { computed } from 'vue'

const router = useRouter();
const route = useRoute();
const { $supabase } = useNuxtApp();

const patient = ref({});
const medications = ref([]);
const alerts = ref([]);
const loadingAlerts = ref(true);
const loading = ref(true);
const loadingMeds = ref(true);
const showCreatedMessage = ref(false)
const defaultAvatar =
    'https://ui-avatars.com/api/?background=E5E7EB&color=374151&size=256&name=Patient'
const alertTab = ref('unread') // 'unread' | 'read'
const readPageSize = 5
const readVisibleCount = ref(readPageSize)
const editMedications = ref(false)
const editedMedications = ref(new Set())
const showSavedMessage = ref(false)

const markAsEdited = (id) => {
    editedMedications.value.add(id)
}

const unreadAlerts = computed(() =>
    alerts.value.filter(a => a.is_read !== true)
)

const readAlertsAll = computed(() =>
    alerts.value.filter(a => a.is_read === true)
)

const switchTab = (tab) => {
    alertTab.value = tab
    if (tab === 'read') {
        readVisibleCount.value = readPageSize
    }
}

const loadMoreReadAlerts = () => {
    readVisibleCount.value += readPageSize
}

const readAlertsVisible = computed(() =>
    readAlertsAll.value.slice(0, readVisibleCount.value)
)
const getAvatarUrl = (patient) => {
    if (patient.image_url) return patient.image_url

    const name = `${patient.name} ${patient.surname}`
    const colors = ['F87171', '60A5FA', '34D399', 'FBBF24', 'A78BFA']
    const color = colors[patient.id % colors.length]

    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=${color}&color=FFFFFF&size=256&rounded=true`
}


const formatDate = (dateString) => {
    if (!dateString) return '';

    const date = new Date(dateString);

    return date.toLocaleString('it-IT', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    });
};


// 1. Fetch paziente
const fetchPatient = async () => {
    const { data, error } = await $supabase
        .from("patients")
        .select("*")
        .eq("id", route.params.id)
        .single();

    if (!error) patient.value = data;
    loading.value = false;
};

// 2. Fetch farmaci del paziente
const fetchMedications = async () => {
    loadingMeds.value = true;

    const { data, error } = await $supabase
        .from("medications")
        .select("*")
        .eq("patient_id", route.params.id);

    if (!error) medications.value = data;
    loadingMeds.value = false;
};

const loadAlerts = async () => {
    console.log("➡️ loadAlerts START");
    loadingAlerts.value = true;

    try {
        const patientId = Number(route.params.id);
        console.log("🆔 patientId =", patientId);

        const res = await $supabase
            .from("alerts")
            .select("*")
            .eq("patient_id", route.params.id)
            .order("created_at", { ascending: false })

        console.log("📦 Supabase response:", res);

        if (res.error) {
            console.error("❌ Supabase error:", res.error);
        } else {
            alerts.value = res.data || [];
            console.log("✅ Alerts set:", alerts.value);
        }
    } catch (err) {
        console.error("🔥 JS EXCEPTION in loadAlerts:", err);
    } finally {
        loadingAlerts.value = false;
        console.log("⬅️ loadAlerts END (loadingAlerts=false)");
    }
};

const subscribeToAlerts = () => {
    $supabase
        .channel(`alerts-${route.params.id}`)
        .on(
            'postgres_changes',
            {
                event: 'INSERT',
                schema: 'public',
                table: 'alerts',
                filter: `patient_id=eq.${route.params.id}`,
            },
            payload => {
                alerts.value.unshift(payload.new)
            }
        )
        .subscribe()
}

// Elimina farmaco
const deleteMedication = async (id) => {
    const { error } = await $supabase.from("medications").delete().eq("id", id);
    if (!error) {
        medications.value = medications.value.filter((med) => med.id !== id);
    }
};

// Vai alla pagina di modifica farmaci
const goToEditMedications = () => {
    router.push(`/edit-medications/${route.params.id}`);
};

//leggi notifica
const confirmAlert = async (alertId) => {
    const { error } = await $supabase
        .from("alerts")
        .update({ is_read: true })
        .eq("id", alertId)

    if (error) {
        console.error("Errore conferma notifica:", error)
        return
    }

    // aggiorna UI localmente (UX immediata)
    const alert = alerts.value.find(a => a.id === alertId)
    if (alert) alert.is_read = true
}

const toggleEditMedications = async () => {
    if (!editMedications.value) {
        // entra in modalità modifica
        editMedications.value = true
        return
    }

    // 🔽 QUI SI SALVA DAVVERO
    const updates = medications.value.filter(m =>
        editedMedications.value.has(m.id)
    )

    for (const med of updates) {
        const { error } = await $supabase
            .from('medications')
            .update({
                hour: med.hour,
                quantity: med.quantity,
            })
            .eq('id', med.id)

        if (error) {
            alert('Errore nel salvataggio dei farmaci')
            return
        }
    }

    // reset stato
    editedMedications.value.clear()
    editMedications.value = false

    showSavedMessage.value = true

    setTimeout(() => {
        showSavedMessage.value = false
    }, 2000)
}

onMounted(() => {
    fetchPatient();
    fetchMedications();
    loadAlerts();
    subscribeToAlerts();
    if (route.query.created === 'true') {
        showCreatedMessage.value = true

        setTimeout(() => {
            showCreatedMessage.value = false
        }, 2000)
    }
});
</script>

<style scoped>
.success-banner {
    display: flex;
    align-items: center;
    gap: 8px;
    background: #dcfce7;
    color: #166534;
    padding: 12px 16px;
    border-radius: 8px;
    margin-bottom: 16px;
    font-weight: 500;
}

.check {
    color: #22c55e;
    font-size: 18px;
}

.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.5s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
.avatar-wrapper {
    width: 140px;
    height: 140px;
    border-radius: 50%;
    overflow: hidden;
    background: #f3f4f6;
    box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
    border: 4px solid white;
}

.avatar-img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}
</style>
