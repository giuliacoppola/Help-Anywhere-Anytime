<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useNuxtApp } from 'nuxt/app'
import patient from "./patient.vue";

const router = useRouter()
const { $supabase } = useNuxtApp()

// Form fields
const name = ref('')
const surname = ref('')
const dateOfBirth = ref('')
const imageFile = ref(null)
const imagePreview = ref(null)

// Feedback
const errorMessage = ref('')
const successMessage = ref('')

// Logged user
const user = ref(null)

const onImageSelected = (event) => {
    const file = event.target.files[0]
    if (!file) return

    imageFile.value = file
    imagePreview.value = URL.createObjectURL(file)
}

// Check auth on page load
onMounted(async () => {
    const { data } = await $supabase.auth.getUser()

    if (!data.user) {
        return router.push('/auth')   // redirect se non loggato
    }

    user.value = data.user
})

// Submit handler
const addPatient = async () => {
    errorMessage.value = ''

    // 1️⃣ Validazione
    if (!name.value || !surname.value || !dateOfBirth.value) {
        errorMessage.value = 'Tutti i campi sono obbligatori.'
        return
    }

    if (!user.value?.id) {
        errorMessage.value = 'Utente non autenticato'
        return
    }

    // 2️⃣ Inserisci paziente e OTTIENI ID
    const { data: patient, error: insertError } = await $supabase
        .from('patients')
        .insert({
            name: name.value,
            surname: surname.value,
            dateOfBirth: dateOfBirth.value,
            carer_id: user.value.id,
        })
        .select()
        .single()

    if (insertError) {
        errorMessage.value = insertError.message
        return
    }

    // 3️⃣ Upload immagine (se presente)
    if (imageFile.value) {
        const fileExt = imageFile.value.name.split('.').pop()
        const filePath = `${user.value.id}/${patient.id}.${fileExt}`

        console.log('UPLOAD PATH:', filePath)

        const { error: uploadError } = await $supabase.storage
            .from('patients')
            .upload(filePath, imageFile.value, { upsert: true })

        if (uploadError) {
            errorMessage.value = uploadError.message
            return
        }

        // 4️⃣ URL pubblico
        const { data } = $supabase.storage
            .from('patients')
            .getPublicUrl(filePath)

        // 5️⃣ Update image_url
        const { error: updateError } = await $supabase
            .from('patients')
            .update({ image_url: data.publicUrl })
            .eq('id', patient.id)

        if (updateError) {
            errorMessage.value = updateError.message
            return
        }
    }

    // 6️⃣ Redirect finale
    router.push({
        path: `/patients/${patient.id}`,
        query: { created: 'true' }
    })
}

</script>

<template>
    <div class="min-h-screen bg-gray-50 p-6">

        <!-- Titolo -->
        <h1 class="text-3xl font-bold text-gray-900 mb-8 text-center">
            Aggiungi paziente
        </h1>


        <div class="min-h-screen bg-gray-50 p-6">

        <!-- Card -->
        <div
            class="bg-white border border-gray-200 rounded-2xl p-8 max-w-xl mx-auto shadow-sm"
        >
            <form @submit.prevent="addPatient" class="space-y-6">

                <!-- Nome -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                        Nome
                    </label>
                    <input
                        v-model="name"
                        type="text"
                        placeholder="Nome"
                        class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                               focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                </div>

                <!-- Cognome -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                        Cognome
                    </label>
                    <input
                        v-model="surname"
                        type="text"
                        placeholder="Cognome"
                        class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                               focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                </div>

                <!-- Data di nascita -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                        Data di nascita
                    </label>
                    <input
                        v-model="dateOfBirth"
                        type="date"
                        class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                               focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                </div>

                <!-- Upload immagine -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                        Foto paziente (opzionale)
                    </label>

                    <label
                        class="flex items-center justify-center gap-2 px-4 py-3 rounded-xl
                               border border-dashed border-gray-300 bg-gray-50
                               cursor-pointer hover:bg-gray-100 transition"
                    >
                        <span class="text-gray-600 text-sm">
                            Seleziona immagine
                        </span>
                        <input
                            type="file"
                            accept="image/*"
                            class="hidden"
                            @change="onImageSelected"
                        />

                    </label>

                    <p v-if="imageFile" class="mt-2 text-sm text-gray-500">
                        {{ imageFile.name }}
                    </p>
                </div>

                <!-- Preview avatar -->
                <transition name="fade">
                    <div v-if="imagePreview" class="mt-4 flex justify-center">
                        <div
                            class="w-32 h-32 rounded-full overflow-hidden
               border-4 border-white shadow-lg bg-gray-100"
                        >
                            <img
                                :src="imagePreview"
                                alt="Preview avatar"
                                class="w-full h-full object-cover"
                            />
                        </div>
                    </div>
                </transition>

                <!-- CTA -->
                <button
                    type="submit"
                    class="w-full rounded-xl bg-blue-600 text-white py-3 font-medium
                           hover:bg-blue-700 transition"
                >
                    Aggiungi paziente
                </button>

                <!-- Error -->
                <p
                    v-if="errorMessage"
                    class="text-center text-sm font-medium text-red-600"
                >
                    {{ errorMessage }}
                </p>

            </form>
        </div>
    </div>
    </div>
</template>

