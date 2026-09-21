import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverNotificationService {
  static final _supabase = Supabase.instance.client;

  static Future<void> sendAlert({
    required String patientId,
    required String intent,
    required String transcription,
    required String aiResponse,
  }) async {
    await _supabase.from('alerts').insert({
      'patient_id': patientId,
      'intent': intent,
      'transcription': transcription,
      'ai_response': aiResponse,
    });
    print("🚨 NOTIFICA CAREGIVER");
    print("➡️ Intent: $intent");
    print("🗣 Trascrizione: $transcription");
    print("🤖 Risposta AI: $aiResponse");
  }
}
