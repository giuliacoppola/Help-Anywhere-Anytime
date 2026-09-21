import 'package:supabase_flutter/supabase_flutter.dart';
import 'event_manager.dart';

class ReminderListener {
  final EventManager eventManager;
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _channel;

  ReminderListener(this.eventManager);

  void startListening(String patientId) {
    _channel = _supabase
        .channel('public:alerts')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'alerts',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'patient_id',
        value: patientId,
      ),
      callback: (payload) async {
        final alert = payload.newRecord;

        if (alert['intent'] == 'REMINDER' &&
            alert['is_read'] == false) {

          final text = alert['ai_response'];

          // 1️⃣ parla
          eventManager.onReminder(text);

          // 2️⃣ marca come letto
          await _supabase
              .from('alerts')
              .update({'is_read': true})
              .eq('id', alert['id']);
        }
      },
    )
        .subscribe();
  }

  void dispose() {
    _supabase.removeChannel(_channel!);
  }
}
