import 'dart:async';
import 'dart:ui';
import 'dart:collection';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/groq_service.dart';
import '../services/tts_service.dart';
import '../services/caregiver_notification_service.dart';
import '../services/local_notification_service.dart';
import 'caregiver_alert_decider.dart';
import 'intent_classifier.dart';

enum SessionState { idle, active, waitingResponse, closed }

const Set<String> caregiverAlertIntents = {
  "HELP",
  "CONFUSION",
  "THERAPY",
};

class SessionManager {
  bool finished=true;
  final String patientId;
  String? _patientName;
  Future<void>? _patientNameFuture;

  SessionManager({required this.patientId});

  final IntentClassifier _classifier = IntentClassifier();
  final LocalNotificationService _notificationService =
  LocalNotificationService();

  SessionState state = SessionState.idle;

  final Queue<Future<void> Function()> _pendingQueue = Queue();
  bool _processingQueue = false;

  String? lastText;
  String? lastIntent;
  String? aiResponse;
  String? _activeVisionContext;
  String? _currentDrugName;

  // =========================
  // UI STATE
  // =========================
  bool hasActiveReminder = false;
  String? reminderText;

  Function(String)? onLog;
  Function()? onStateChanged;
  VoidCallback? onWakeWord;

  Timer? _autoCloseTimer;
  VoidCallback? onWakeWordShouldResume;


  // =========================
  // 🔒 AUDIO LOCK (FONDAMENTALE)
  // =========================
  bool _isSpeaking = false;
  DateTime? _lastReminderTime;
  static const Duration _reminderCooldown = Duration(seconds: 10);

  void log(String msg) {
    onLog?.call(msg);
  }

  Future<void> _ensurePatientNameLoaded() {
    // Se è già caricato → esci
    if (_patientName != null) {
      return Future.value();
    }

    // Se è già in caricamento → riusa la stessa Future
    if (_patientNameFuture != null) {
      return _patientNameFuture!;
    }

    _patientNameFuture = () async {
      try {
        final response = await Supabase.instance.client
            .from('patients')
            .select('name')
            .eq('id', patientId)
            .single();

        _patientName = response['name'] as String?;
        log("👤 Paziente caricato: $_patientName");
      } catch (e) {
        log("❌ Errore caricamento nome paziente: $e");
      }
    }();

    return _patientNameFuture!;
  }



  // =========================
  // SESSION CONTROL
  // =========================

  void _openSession() {
    if (state == SessionState.active) return;
    finished=false;

    state = SessionState.active;

    onStateChanged?.call();

    log("✅ SESSIONE APERTA");
  }

  void closeSession() {
    log("⏹ SESSIONE CHIUSA");
    lastText = null;
    lastIntent = null;
    aiResponse = null;

    hasActiveReminder = false;
    reminderText = null;

    state = SessionState.idle;
    onStateChanged?.call();

    if(finished){
      if (_pendingQueue.isNotEmpty) {
        log("✅ VAI ALLA PROSSIMA SESSIONE");
        final next = _pendingQueue.removeFirst();
        _runAction(next);
        return;
      }
    }
    log("🎧 Riattivo wake word");
    onWakeWordShouldResume?.call();
  }

  //accoda sessioni
  Future<void> _runOrQueue(Future<void> Function() action) async {
    if (finished && !_processingQueue) {
      await _runAction(action);
    } else {
      log("⏳ Azione accodata (sessione non finita)");
      _pendingQueue.add(action);
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    _processingQueue = true;
    finished = false; // 🔒 stiamo entrando in una nuova sessione

    await action();

    _processingQueue = false;
  }


  // =========================
  // 🟣 WAKE WORD
  // =========================
  Future<void> processWakeWord() async {
    log("🟣 WAKE WORD → apro sessione");
    await _ensurePatientNameLoaded();
    final name = _patientName?.trim();

    //RISPOSTA STANDARD
    aiResponse = name != null && name.isNotEmpty
        ? "Ciao $name, come posso aiutarti?"
        : "Come posso aiutarti?";
    lastIntent = "WAKE_ONLY";

    log("🤖 AI (TEST) → $aiResponse");

    try {
      _isSpeaking = true;
      await AzureTtsService.speak(aiResponse!);
    } catch (e) {
      log("❌ Errore TTS wake: $e");
    } finally {
      _isSpeaking = false;
    }
    _openSession();
  }
  // =========================
  // VAD → STT → INTENT
  // =========================

  // =========================
  // 🎤 STT → TEST (dal backend)
  // =========================
  Future<void> processSttText(String text) async {
    if (text.trim().isEmpty) {
      log("⚠️ STT vuoto");
      return;
    }

    lastText = text;
    log("📝 STT → $text");

    lastIntent = _classifier.classify(text);
    log("➡️ INTENT = $lastIntent");

    _aiResponse();
  }

  Future<void> processAudio(String trascrizione) async {
    log("🎤 Trascrizione ricevuta -> Risposta");
    if(trascrizione.trim().isEmpty){
      log("X trascrizione nulla");
      return;
    }
    lastText = trascrizione;
    log("📝 STT STREAM → $trascrizione");

    lastIntent = _classifier.classify(trascrizione);
    log("➡️ INTENT = $lastIntent");

    _aiResponse();
  }

  // =========================
  // MANUAL TEXT (DEBUG)
  // =========================

  void processManualText(String text) {
    _openSession();

    lastText = text;
    lastIntent = _classifier.classify(text);

    log("📝 MANUAL TEXT → $text");
    log("➡️ INTENT = $lastIntent");

    _aiResponse();
  }

  Future<void> processReminder(String text) async {
    _runOrQueue(() async {
      hasActiveReminder = true;
      reminderText = text;

      await _ensurePatientNameLoaded();
      final name = _patientName?.trim();

      aiResponse = (name != null && name.isNotEmpty)
          ? "Ciao $name, $text, ti ripeto, $text"
          : "$text, ti ripeto, $text";

      lastIntent = "WAKE_ONLY";

      log("⏰ REMINDER → $aiResponse");

      try {
        _isSpeaking = true;
        await AzureTtsService.speak(aiResponse!);
      } catch (e) {
        log("❌ Errore TTS reminder: $e");
      } finally {
        _isSpeaking = false;
      }
      finished=true;

      //_openSession();
    });
  }

  // =========================
  // AI RESPONSE
  // =========================

  Future<void> _aiResponse() async {
    if (_isSpeaking) return;

    state = SessionState.waitingResponse;
    onStateChanged?.call();

    try {
      final response = await _buildLLMResponse(
        intent: lastIntent ?? "UNKNOWN",
        transcription: lastText ?? "",
      );

      aiResponse = response;
      log("🤖 AI → $aiResponse");

      _isSpeaking = true;
      await AzureTtsService.speak(aiResponse!);
      _isSpeaking = false;

      final shouldNotify = CaregiverAlertDecider.shouldNotify(
        text: lastText ?? "",
        intent: lastIntent ?? "",
      );

      if (shouldNotify) {
        await CaregiverNotificationService.sendAlert(
          patientId: patientId,
          intent: lastIntent!,
          transcription: lastText ?? "",
          aiResponse: aiResponse!,
        );
        log("🚨 Caregiver notificato (valutazione semantica)");
      } else {
        log("ℹ️ Nessun alert necessario");
      }

    } catch (e) {
      log("❌ Errore AI: $e");
      _isSpeaking = false;
    }

    state = SessionState.active;
    onStateChanged?.call();
  }

  Future<String> _buildLLMResponse({
    required String intent,
    required String transcription,
  }) async {
    late String prompt;

    // ============================================================
    // 1. NUOVA PARTE: GESTIONE CONTESTO VISIVO (Priorità Alta)
    // ============================================================
    if (_activeVisionContext != null && _currentDrugName != null) {
      prompt =
          "RUOLO: Assistente medico preciso. "
          "CONTESTO: $_activeVisionContext. "
          "OGGETTO: Stiamo parlando del farmaco '$_currentDrugName'. "
          "UTENTE DICE: \"$transcription\". "
          "Rispondi riferendoti esplicitamente a '$_currentDrugName'. Sii breve.";

      // Pulizia memoria dopo l'uso
      _activeVisionContext = null;
      _currentDrugName = null;
    }
    // ============================================================
    // 2. TUA PARTE ESISTENTE (Conversazione Standard)
    // ============================================================
    else {
      switch (intent) {
        case "HELP":
          prompt =
              "L'utente chiede aiuto dicendo: \"$transcription\". "
              "Rispondi rassicurandolo.";
          break;

        case "CONFUSION":
          prompt =
          "L'utente è confuso e dice: \"$transcription\". "
              "Rispondi cercando di rassicurarlo e chiedi perchè.";
          break;

          case "THERAPY":
            prompt =
                "L'utente parla di terapia: \"$transcription\". "
                "Rispondi in modo semplice.";
            break;

          default:
            prompt =
                "Conversazione normale. L'utente ha detto: \"$transcription\".";
        }
      }

    return GroqService.generateResponse(prompt: prompt);
  }

  Future<void> provaSTT (String trascrizione) async{
    _openSession();
    if(trascrizione.trim().isEmpty){
      log("X trascrizione nulla");
      return;
    }
    lastText = trascrizione;
    log("📝 STT STREAM → $trascrizione");

    lastIntent = _classifier.classify(trascrizione);
    log("➡️ INTENT = $lastIntent");

    _aiResponse();
  }

  // =========================
// 🎤 STT RESULT (COMPATIBILITÀ)
// =========================
  Future<void> handleSttResult(String text) async {
    log("🎧 handleSttResult chiamato");

    await processSttText(text);
  }

  // =========================
  // 👁️ VISION TRIGGER
  // =========================
  Future<void> processVisualDetection(String objectName) async {
    // 🛑 BLOCCO SICUREZZA: Se sta già parlando o la sessione è attiva, ignora.
    if (state != SessionState.idle || _isSpeaking) {
      return;
    }

    String textToCheck = objectName.toLowerCase();

    // --- CASO 1: FORNO (PERICOLO) ---
    if (textToCheck.contains("oven") || 
        textToCheck.contains("stove") ||
        textToCheck.contains("forno")) {
        
      log("🔥 VISION TRIGGER: Forno rilevato ($objectName)");

      // 1. Prepariamo il messaggio e la UI
      String safetyMessage = "Ho notato che sei ai fornelli. Ricordati di spegnere tutto quando hai finito. Serve aiuto?";

      aiResponse = safetyMessage;
      lastText = "Visto: $objectName"; 
      lastIntent = "VISION_SAFETY"; 
      onStateChanged?.call(); 

      // 2. PARLIAMO (Attendiamo che finisca)
      try {
        _isSpeaking = true;
        await AzureTtsService.speak(safetyMessage); 
      } catch (e) {
        log("❌ Errore TTS Vision: $e");
      } finally {
        _isSpeaking = false;

        // 3. SOLO ORA APRIAMO LA SESSIONE (Microfono ON)
        _openSession();
      }
      return;
    }

    // --- CASO 2: FARMACI (MEDICINE vs UNKNOWN) ---
    
    // CASO A: Farmaco Sicuro (MEDICINE:)
    if (objectName.startsWith("MEDICINE:")) {
       String rawName = objectName.split(":")[1].trim();
       String drugName = rawName.isNotEmpty
          ? '${rawName[0].toUpperCase()}${rawName.substring(1)}'
          : rawName;

       log("💊 VISION TRIGGER: Farmaco Corretto ($drugName)");
       
       // ✅ SALVIAMO IL CONTESTO ESPLICITO
       _currentDrugName = drugName;
       _activeVisionContext = "L'assistente ha riconosciuto il farmaco $drugName e ha chiesto se servono istruzioni.";

       String message = "Ho riconosciuto $drugName. È nella tua lista. Vuoi sapere come prenderlo?";
       
       aiResponse = message;
       lastText = "Visto Farmaco: $drugName";
       lastIntent = "THERAPY"; // Intent coerente
       onStateChanged?.call();

       try {
        _isSpeaking = true;
        await AzureTtsService.speak(message);
       } catch (e) { log("❌ Errore TTS: $e"); } 
       finally {
         _isSpeaking = false;
         // 3. START SESSIONE
         _openSession();
       }
       return;
    }
    
    // CASO B: Farmaco Sconosciuto (UNKNOWN:)
    else if (objectName.startsWith("UNKNOWN:")) {
       String rawName = objectName.split(":")[1].trim();
       String drugName = rawName.isNotEmpty
          ? '${rawName[0].toUpperCase()}${rawName.substring(1)}'
          : rawName;

       log("⚠️ VISION TRIGGER: Farmaco Sconosciuto ($drugName)");
       
       // ✅ SALVIAMO IL CONTESTO ESPLICITO
       _currentDrugName = drugName;
       _activeVisionContext = "L'assistente ha visto un farmaco sconosciuto ($drugName).";

       String message = "Attenzione. $drugName non risulta nella tua terapia. Non prenderlo senza chiedere al dottore.";
       
       aiResponse = message;
       lastText = "Visto Farmaco Sconosciuto: $drugName";
       lastIntent = "THERAPY";
       onStateChanged?.call();

       try {
        _isSpeaking = true;
        await AzureTtsService.speak(message);
       } catch (e) { log("❌ Errore TTS: $e"); } 
       finally {
         _isSpeaking = false;
         // 3. START SESSIONE
         _openSession();
       }
       return;
    }
  }
}
