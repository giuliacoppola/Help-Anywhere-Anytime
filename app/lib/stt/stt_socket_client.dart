import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

/// Client WebSocket che manda audio PCM16 e riceve eventi JSON:
/// - {type: ready, ...}
/// - {type: final, text: "..."}
/// - {type: idle, ...} => server chiude
class SttSocketClient {
  final Uri uri;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _eventsController.stream;

  bool get isConnected => _channel != null;

  SttSocketClient(this.uri);

  Future<void> connect() async {
    if (_channel != null) return;

    _channel = WebSocketChannel.connect(uri);

    _sub = _channel!.stream.listen(
          (msg) {
        try {
          final map = jsonDecode(msg as String) as Map<String, dynamic>;
          _eventsController.add(map);
        } catch (_) {}
      },
      onError: (e) {
        _eventsController.add({"type": "error", "message": e.toString()});
      },
      onDone: () {
        _eventsController.add({"type": "disconnected"});
        _cleanup();
      },
    );
  }

  void sendPcmBytes(Uint8List pcmBytes) {
    final ch = _channel;
    if (ch == null) return;
    ch.sink.add(pcmBytes);
  }

  Future<void> disconnect() async {
    final ch = _channel;
    if (ch == null) return;
    ch.sink.close(ws_status.normalClosure);
    _cleanup();
  }

  void _cleanup() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
  }

  /// Segnala al backend l'inizio di una nuova finestra di ascolto
  void startListening() {
    final ch = _channel;
    if (ch == null) return;

    ch.sink.add(jsonEncode({
      "type": "start_listening",
    }));
  }
  void pauseListening() {
    final ch = _channel;
    if (ch == null) return;
    ch.sink.add(jsonEncode({"type": "pause_listening"}));
  }

  void resumeListening() {
    final ch = _channel;
    if (ch == null) return;
    ch.sink.add(jsonEncode({"type": "resume_listening"}));
  }


  Future<void> dispose() async {
    await disconnect();
    await _eventsController.close();
  }
}
