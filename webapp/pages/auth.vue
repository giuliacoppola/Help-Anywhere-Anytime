<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useNuxtApp } from 'nuxt/app'

const router = useRouter()
const { $supabase } = useNuxtApp()

const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const errorMessage = ref('')
const isLogin = ref(true)

// ---------------------------------------
// LOGIN
// ---------------------------------------
const login = async () => {
    errorMessage.value = ''

    const { error } = await $supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value
    })

    if (error) {
        errorMessage.value = error.message
        return
    }

    router.push('/homepage')
}

// ---------------------------------------
// REGISTRAZIONE
// ---------------------------------------
const register = async () => {
    errorMessage.value = ''

    if (password.value !== confirmPassword.value) {
        errorMessage.value = 'Le password non coincidono'
        return
    }

    const { error } = await $supabase.auth.signUp({
        email: email.value,
        password: password.value
    })

    if (error) {
        errorMessage.value = error.message
        return
    }

    router.push('/homepage')
}

const submit = async () => {
    if (isLogin.value) return login()
    return register()
}
</script>

<template>
    <div class="min-h-screen bg-gray-50 flex items-center justify-center p-6">
        <div
            class="w-full max-w-5xl bg-white border border-gray-200 rounded-3xl
                   shadow-sm overflow-hidden grid md:grid-cols-2"
        >

            <!-- LEFT: Content -->
            <div class="p-8 md:p-10 flex flex-col justify-center">
                <h1 class="text-3xl font-bold text-gray-900 mb-3">
                    Help Anywhere Anytime
                </h1>

                <p class="text-gray-600 mb-8">
                    {{ isLogin
                    ? 'Accedi per gestire pazienti, terapie e notifiche.'
                    : 'Crea un account per iniziare a usare la piattaforma.' }}
                </p>

                <!-- Card Auth -->
                <div class="space-y-6">
                    <h2 class="text-xl font-semibold text-gray-900">
                        {{ isLogin ? 'Login' : 'Registrazione' }}
                    </h2>

                    <form @submit.prevent="submit" class="space-y-5">

                        <!-- Email -->
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                                Email
                            </label>
                            <input
                                v-model="email"
                                type="email"
                                placeholder="email@example.com"
                                autocomplete="email"
                                required
                                class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                                       focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                        </div>

                        <!-- Password -->
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                                Password
                            </label>
                            <input
                                v-model="password"
                                type="password"
                                placeholder="Password"
                                autocomplete="current-password"
                                required
                                class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                                       focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                        </div>

                        <!-- Conferma password -->
                        <div v-if="!isLogin">
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                                Conferma password
                            </label>
                            <input
                                v-model="confirmPassword"
                                type="password"
                                placeholder="Conferma password"
                                autocomplete="new-password"
                                required
                                class="w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2
                                       focus:outline-none focus:ring-2 focus:ring-blue-500"
                            />
                        </div>

                        <!-- Error -->
                        <p
                            v-if="errorMessage"
                            class="text-sm text-red-600 bg-red-50 border border-red-200
                                   rounded-xl px-4 py-2"
                        >
                            {{ errorMessage }}
                        </p>

                        <!-- CTA -->
                        <button
                            type="submit"
                            class="w-full rounded-xl bg-blue-600 text-white py-3 font-medium
                                   hover:bg-blue-700 transition"
                        >
                            {{ isLogin ? 'Login' : 'Registrati' }}
                        </button>

                        <!-- Toggle -->
                        <p
                            class="text-sm text-blue-600 font-medium cursor-pointer text-center
                                   hover:underline"
                            @click="isLogin = !isLogin"
                        >
                            {{ isLogin
                            ? 'Non hai un account? Registrati'
                            : 'Hai già un account? Login' }}
                        </p>

                    </form>
                </div>
            </div>

            <!-- RIGHT: Image -->
            <div class="hidden md:flex items-center justify-center bg-gray-100">
                <img
                    src="/images/immagineAnziano.png"
                    alt="Elderly assistance"
                    class="max-w-[85%] rounded-2xl shadow"
                />
            </div>

        </div>
    </div>
</template>

