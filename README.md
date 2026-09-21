# Help Anywhere Anytime (HAA)

An assistive system for elderly and dependent people, combining a **voice + vision assistant mobile app** with a **caregiver web dashboard**. Developed as a **university group project**, in collaboration with other students.

The assistant runs on the user's phone, is activated by a custom wake word, listens and answers with a natural voice, can recognize objects/scenes through the camera, sends reminders (e.g. medications), and can alert a caregiver when needed. Caregivers manage patients and medication schedules from a separate web app.

> ⚠️ **Security note:** this repository does **not** include real API keys. The original project code had several secrets (Azure Speech, Supabase, Groq, Picovoice) hardcoded or committed in a `.env` file — those have been replaced with placeholders here (see [Configuration](#configuration) below). If you have access to the original project repositories, those keys should be rotated, since they were exposed there.

## Repository structure

```
app/        Flutter mobile app (the voice/vision assistant) + its Python backend
webapp/     Nuxt web app (caregiver dashboard)
```

## `app/` — Mobile assistant (Flutter) + backend (Python)

### What it does

- **Wake-word activation** (`lib/assistant/wakeword_detector.dart`, Picovoice Porcupine, custom Italian wake words in `assets/*.ppn`)
- **Speech-to-text** streamed to a Python backend over WebSocket (`lib/stt/stt_socket_client.dart` ↔ `backend/stt/ws_stt.py`, Azure Speech + faster-whisper/silero-vad)
- **Conversational assistant** powered by Groq's LLM API (`lib/services/groq_service.dart`, `backend/vision/yolo_routes.py` for vision-grounded responses)
- **Text-to-speech** replies via Azure Speech (`lib/services/tts_service.dart`)
- **Vision**: YOLOv8 object/scene detection on the backend (`backend/vision/yolo_routes.py`, `backend/yolov8n.pt`) to ground the assistant's answers in what the camera sees
- **Medication reminders** (`lib/assistant/reminder_listener.dart`, `backend/reminder_service.py`, `backend/reminder_worker.py`), synced with the data entered by caregivers in the web app (Supabase)
- **Caregiver alerts** (`lib/alert_carer_page.dart`, `lib/assistant/caregiver_alert_decider.dart`, `lib/services/caregiver_notification_service.dart`) for when the assistant detects the user may need help
- **Patient/login screens** (`lib/login_page.dart`, `lib/patient_page.dart`, `lib/patients_page.dart`)

### Tech stack

- **Flutter** (Dart), Supabase client, Picovoice Porcupine, `speech_to_text`/`flutter_tts`, `camera`
- **Backend:** Python, FastAPI + WebSockets, Ultralytics YOLOv8, faster-whisper, silero-vad, Groq SDK, Supabase Python client

> Ultralytics YOLOv8 (`ultralytics` package) is licensed under **AGPL-3.0**; if this backend is ever deployed as a public network service, that license's copyleft terms apply (or a commercial Ultralytics license is required).

### Configuration

**Mobile app** — before building, set your own keys (marked `TODO` in the code):
- `lib/main.dart` — Supabase URL + anon key
- `lib/services/tts_service.dart` — Azure Speech key + region
- `lib/services/groq_service.dart` — Groq API key
- `lib/assistant/wakeword_detector.dart` — Picovoice AccessKey

**Backend** — copy `app/backend/.env.example` to `app/backend/.env` and fill in:
```
AZURE_SPEECH_KEY=...
AZURE_SPEECH_REGION=...
AZURE_SPEECH_LANGUAGE=it-IT
SUPABASE_URL=...
SUPABASE_KEY=...          # service_role key — keep this secret, never expose it client-side
SUPABASE_ANON_KEY=...
GROQ_API_KEY=...
```

### Running it

```
# Backend
cd app/backend
pip install -r requirements.txt
cp .env.example .env   # then fill in your keys
uvicorn main:app --reload

# App
cd app
flutter pub get
flutter run
```

## `webapp/` — Caregiver dashboard (Nuxt)

A web app for caregivers to manage patients and medication schedules, backed by Supabase (auth + database): `pages/auth.vue`, `pages/homepage.vue`, `pages/patients/`, `pages/addPatient.vue`, `pages/medications.vue`, `pages/addMedications.vue`, `pages/edit-medications/`, `pages/profile.vue`.

### Tech stack

Nuxt 4, Vue 3, Tailwind CSS, `@nuxtjs/supabase` / `@supabase/supabase-js`.

### Configuration

Create a `.env` in `webapp/` (not committed) with:
```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

### Running it

```
cd webapp
npm install
npm run dev
```

## System requirements

- **Flutter SDK** (Dart ^3.9.2) + Android/iOS toolchains for the mobile app
- **Python 3.10+** for the backend (`app/backend/requirements.txt`)
- **Node.js** (18+) for the web app
- Accounts/keys for: **Supabase**, **Azure Speech**, **Groq**, **Picovoice**

## Team & credits

Developed as a group project for university coursework, in collaboration with other students, combining mobile development, backend/ML engineering, and web development.

## License

No open-source license has been chosen for this project — all rights are reserved by the authors. Note that the backend's use of Ultralytics YOLOv8 (AGPL-3.0) has its own licensing implications if this software is deployed as a network service (see above).
