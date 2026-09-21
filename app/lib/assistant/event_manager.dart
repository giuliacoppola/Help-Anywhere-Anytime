import 'dart:typed_data';
import 'session_manager.dart';

class EventManager {
  final SessionManager session;

  EventManager(this.session);

  // =========================
  // WAKE WORD
  // =========================
  void onWakeWord(int index) {
    session.processWakeWord();
  }

  // =========================
  // REMINDER
  // =========================
  void onReminder(String reminderText) {
    session.processReminder(reminderText);
  }

  // =========================
  // AUDIO → STT
  // =========================
  void onSttFinal(String transcription) {
    session.handleSttResult(transcription);
  }

  // =========================
  // STT → LLM
  // =========================
  String? get aiResponse => session.aiResponse;

  // =========================
  // TEST MANUALE
  // =========================
  void onManualText(String text) {
    session.processManualText(text);
  }

  // =========================
  // VISION
  // =========================
  void onVisualDetection(String objectName) {
    // Passiamo il rilevamento al SessionManager
    session.processVisualDetection(objectName);
  }

  // =========================
  // CHIUSURA SESSIONE
  // =========================
  void onCloseSession(){
    session.finished=true;
    session.closeSession();
  }
}
