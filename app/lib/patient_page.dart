import 'package:flutter/material.dart';
import 'package:prova_occhiali/patients_page.dart';
import 'package:prova_occhiali/widgets/unlock_carer_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:prova_occhiali/services/conversation_controller.dart';

import 'assistant/session_manager.dart';
import 'assistant/event_manager.dart';
import 'assistant/wakeword_detector.dart';
import 'assistant/reminder_listener.dart';

import 'assistant/vision_service.dart';
import 'dart:async';                   
import 'dart:io';                      
import 'package:camera/camera.dart';


class PatientPage extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientPage({super.key, required this.patient});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  late final SessionManager session;
  late final EventManager eventManager;
  late final WakeWordDetector wakeDetector;
  late final ReminderListener reminderListener;
  late final ConversationController conversation;
  
  // --- VISION VARIABLES ---
  CameraController? _cameraController;
  final VisionService _visionService = VisionService();
  Timer? _visionTimer;
  bool _isVisionProcessing = false;
  String _visionLog = ""; // La stringa che mostrerà SOLO "oven" o il medicinale
  
  // Inizializza la camera
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final firstCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium, 
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});

    // Avvia il loop di scansione ogni 1 secondo
    _visionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _scanFrame());
  }

  Future<void> _scanFrame() async {
    // 1. PAUSA LOGICA: Se la sessione è attiva (l'assistente parla o ascolta), FERMA VISIONE
    if (session.state == SessionState.active) {
       // Pulisci il log quando in pausa per non confondere
       if (_visionLog.isNotEmpty) setState(() => _visionLog = ""); 
       return; 
    }

    // Controlli tecnici
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isVisionProcessing) {
      return;
    }

    _isVisionProcessing = true;

    try {
      final image = await _cameraController!.takePicture();
      final objects = await _visionService.analyzeImage(File(image.path));
      if (session.state == SessionState.active) {
         return; 
      }
      String detectedName = "";
      if (objects.contains('oven')) {
        detectedName = "OVEN";
        eventManager.onVisualDetection("oven"); 
        
      } else {
        try {
          // Cerca MEDICINE
          String found = objects.firstWhere((obj) => obj.startsWith("MEDICINE:"));
          detectedName = found.split(":")[1].trim().toUpperCase();
          
          // ✅ CORRETTO: Passiamo 'found' (la stringa intera "MEDICINE:Oki")
          eventManager.onVisualDetection(found); 
          
        } catch (e) {
          try {
            // Cerca UNKNOWN
            String found = objects.firstWhere((obj) => obj.startsWith("UNKNOWN:"));
            detectedName = found.split(":")[1].trim().toUpperCase();
            
            // ✅ CORRETTO: Passiamo 'found' (la stringa intera "UNKNOWN:Farmaco")
            eventManager.onVisualDetection(found);
            
          } catch (e) {
            // Nessun farmaco trovato, non fare nulla
          }
        }
      }

      if (mounted) {
        setState(() {
          _visionLog = detectedName; // Sarà vuota se non trova nulla, o "OVEN"/"MEDICINE"
        });
      }

    } catch (e) {
      debugPrint("Vision Error: $e");
    } finally {
      _isVisionProcessing = false;
    }
  }
  

  @override
  void initState() {
    super.initState();

    // ================= SESSION =================
    session = SessionManager(
      patientId: widget.patient['id'].toString(),
    );

    session.onLog = (m) => debugPrint("🧠 SESSION → $m");
    session.onStateChanged = _onSessionStateChanged;
    session.onWakeWordShouldResume = () {
      wakeDetector.startListening();
    };

    // ================= EVENT MANAGER =================
    eventManager = EventManager(session);

    // ================= WAKE WORD =================
    wakeDetector = WakeWordDetector(eventManager);
    wakeDetector.startListening();

    // ================= REMINDER =================
    reminderListener = ReminderListener(eventManager);
    reminderListener.startListening(widget.patient['id'].toString());

    // ================= STT / TTS =================
    conversation = ConversationController(
      eventManager: eventManager,
      onLog: (m) => debugPrint("🎙 STT → $m"),
    );

    _initializeCamera();
  }

  void _onSessionStateChanged() {
    setState(() {});

    if (session.state == SessionState.active) {
      conversation.startConversation();
    }
  }

  @override
  void dispose() {
    _visionTimer?.cancel();      
    _cameraController?.dispose(); 
    wakeDetector.stopListening();
    conversation.dispose();
    super.dispose();
  }

  // =====================================================
  // 🔓 UNLOCK FLOW
  // =====================================================

  void _showUnlockDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UnlockCarerDialog(),
    );
  }


  void _unlockDevice() {
    wakeDetector.stopListening();
    conversation.dispose();

    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PatientsPage(
          carerId: Supabase.instance.client.auth.currentUser!.id,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final isActive = session.state == SessionState.active;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            '${widget.patient['name']} ${widget.patient['surname']}',
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.lock_open,
                color: Colors.redAccent,
              ),
              tooltip: "Sblocca dispositivo",
              onPressed: _showUnlockDialog, // 🔐 NON fa pop
              //onPressed: _unlockDevice,
            ),
          ],
        ),

        body: Column(
          children: [
            // --- META' SUPERIORE: INTERFACCIA VOCALE (Esistente) ---
            Expanded(
              flex: 1,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? Icons.mic : Icons.mic_none,
                      size: 80,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isActive
                          ? "Assistente attivo..."
                          : "In ascolto…\nDì \"ciao assistente\"",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22),
                    ),
                    // Reminder Visivo (codice esistente)
                    if (session.hasActiveReminder && session.reminderText != null)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Card(
                          color: Colors.amber.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(session.reminderText!),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // --- META' INFERIORE: VISIONE (Nuova) ---
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Anteprima Camera
                    if (_cameraController != null && _cameraController!.value.isInitialized)
                      SizedBox.expand(
                        child: CameraPreview(_cameraController!),
                      )
                    else
                      const Center(child: CircularProgressIndicator()),

                    // 2. Overlay SOLO se attivo (Pausa visiva se assistente parla)
                    if (session.state == SessionState.active)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            "Visione in Pausa\n(Assistente Attivo)",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),

                    // 3. LOG RICHIESTO (Solo "OVEN" o Nome Medicinale)
                    if (_visionLog.isNotEmpty)
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _visionLog, // "OVEN" o nome med
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// 🔐 DIALOG RE-AUTH CARER
// =====================================================

class _UnlockDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const _UnlockDialog({required this.onSuccess});

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _authenticate() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );

      Navigator.of(context).pop(); // chiudi dialog PRIMA
      widget.onSuccess();          // poi naviga
    } catch (e) {
      setState(() {
        error = "Credenziali non valide";
        loading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Sblocco dispositivo"),
      content: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email carer",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : _authenticate,
          child: loading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Sblocca"),
        ),
      ],
    );
  }
}

