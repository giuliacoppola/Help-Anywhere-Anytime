import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:sound_stream/sound_stream.dart';

import '../assistant/event_manager.dart';
import '../stt/stt_socket_client.dart';
import '../services/tts_service.dart';

enum ConversationState {
  idle,
  listening,
  processing,
}

class ConversationController {
  // ================= CONFIG =================
  final Uri wsUri =
  Uri.parse('ws://192.168.0.191:8000/ws/stt?sample_rate=16000');

  // ================= CORE =================
  final RecorderStream _recorder = RecorderStream();
  final EventManager eventManager;
  final void Function(String) onLog;

  SttSocketClient? _client;
  StreamSubscription? _audioSub;
  StreamSubscription? _eventSub;

  ConversationState _state = ConversationState.idle;

  bool _ttsSpeaking = false;
  bool _shouldStop = true;

  String _currentTranscript = "";

  ConversationController({
    required this.eventManager,
    required this.onLog,
  }) {
    AzureTtsService.onCompleted = _onTtsCompleted;
  }

  // =========================
  // START STT
  // =========================
  Future<void> startConversation() async {
    onLog("🚀 startConversation() CHIAMATO");

    if (_state != ConversationState.idle) {
      onLog("⚠️ STT già attivo");
      return;
    }

    _reset();

    //onLog("🎙️ Richiesta permesso microfono");
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      onLog("❌ Microfono non autorizzato");
      return;
    }

    onLog("🎤 Avvio STT");

    await _recorder.initialize(sampleRate: 48000);

    _client = SttSocketClient(wsUri);
    await _client!.connect();
    onLog("🔗 WebSocket STT connesso");

    _eventSub = _client!.events.listen(_onSttEvent);

    _audioSub = _recorder.audioStream.listen((pcm) {
      if (_state == ConversationState.listening) {
        _client!.sendPcmBytes(Uint8List.fromList(pcm));
      }
    });

    await _recorder.start();
    _state = ConversationState.listening;

    onLog("🎙️ MICROFONO APERTO — STT IN ASCOLTO");
  }

  // =========================
  // STT EVENTS
  // =========================
  void _onSttEvent(Map<String, dynamic> event) {
    if (_ttsSpeaking) return;
    if (_state != ConversationState.listening) return;

    final type = event["type"];

    if (type == "final") {
      final text = event["text"]?.toString().trim();
      if (text != null && text.isNotEmpty) {
        _currentTranscript = text;
        onLog("📝 STT FINAL → $text");
        _shouldStop=false;
        _handleUtterance();
      }
    }

    if (type == "idle_timeout") {
      onLog("⏹ STT idle_timeout");
      if(_shouldStop){
        _closeAll();
        return;
      }
      _closeTemporal();
    }
  }

  // =========================
  // HANDLE UTTERANCE
  // =========================
  Future<void> _handleUtterance() async {
    onLog("⏹ arriva handleutterance");
    if (_state == ConversationState.processing || _ttsSpeaking) return;

    final text = _currentTranscript.trim();
    if (text.isEmpty) return;

    _currentTranscript = "";
    _state = ConversationState.processing;
    await _recorder.stop();

    _ttsSpeaking = true;

    _client?.pauseListening();

    // 🔥 ORA PASSIAMO SOLO IL TESTO
    //await session.handleSttResult(text);

    eventManager.onSttFinal(text);

    _ttsSpeaking = false;

    //final String? responseToSpeak = session.aiResponse;
    final String? responseToSpeak = eventManager.aiResponse;
    if (responseToSpeak != null && responseToSpeak.isNotEmpty) {
      await AzureTtsService.speak(responseToSpeak);
    }
    //_restartListening();
  }

  // =========================
  // TTS COMPLETED
  // =========================
  void _onTtsCompleted() {
    if (_state != ConversationState.processing) return;

    onLog("🔊 TTS COMPLETATA");

    _ttsSpeaking = false;
    _currentTranscript = "";


    if (_shouldStop) {
      _closeAll();
      return;
    }

    _closeTemporal();
  }

  /*Future<void> _restartListening() async {
    await _closeTemporal();
    await startConversation();
  }*/

  // =========================
  // CLEANUP
  // =========================
  Future<void> _closeTemporal() async {
    await AzureTtsService.stopSafely();

    try {
      await _recorder.stop();
    } catch (_) {}

    await _audioSub?.cancel();
    await _eventSub?.cancel();
    await _client?.dispose();

    _audioSub = null;
    _eventSub = null;
    _client = null;

    _state = ConversationState.idle;
    startConversation();
  }

  Future<void> _closeAll() async {
    await AzureTtsService.stopSafely();

    try {
      await _recorder.stop();
    } catch (_) {}

    await _audioSub?.cancel();
    await _eventSub?.cancel();
    await _client?.dispose();

    _audioSub = null;
    _eventSub = null;
    _client = null;

    eventManager.onCloseSession();
    _state = ConversationState.idle;
    onLog("🛑 Conversazione terminata");
  }

  void _reset() {
    _state = ConversationState.idle;
    _ttsSpeaking = false;
    _shouldStop = true;
    _currentTranscript = "";
  }

  // =========================
  // DISPOSE (per Widget)
  // =========================
  Future<void> dispose() async {
    await _closeAll();
  }
}