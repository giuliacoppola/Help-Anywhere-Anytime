import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

import 'event_manager.dart';

class WakeWordDetector {
  final EventManager eventManager;

  PorcupineManager? _porcupineManager;
  bool _isListening = false;

  // TODO: insert your own Picovoice AccessKey (https://console.picovoice.ai) — do not commit real keys.
  static const String _accessKey = "YOUR_PICOVOICE_ACCESS_KEY";

  WakeWordDetector(this.eventManager);

  Future<void> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception("Permesso microfono negato");
    }
  }

  Future<String> _copyAssetToFile(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${assetPath.split('/').last}');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return file.path;
  }

  Future<void> startListening() async {
    if (_isListening) return;

    try {
      await _ensureMicPermission();

      final keywordPath = await _copyAssetToFile(
        "assets/ciao-assistente_it_android_v4_0_0.ppn",
      );

      final modelPath = await _copyAssetToFile(
        "assets/porcupine_params_it.pv",
      );

      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        [keywordPath],
            (int index) async {
          print("🔥 Wake word detected");
          await stopListening(); // libera il microfono
          eventManager.onWakeWord(index);
        },
        modelPath: modelPath,
      );

      await _porcupineManager!.start();
      _isListening = true;

      print("🎤 WakeWordDetector in ascolto");
    } catch (e, st) {
      print("❌ WakeWordDetector error: $e");
      print(st);
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;

    try {
      await _porcupineManager?.stop();
    } catch (_) {}

    _porcupineManager?.delete();
    _porcupineManager = null;

    print("🛑 WakeWordDetector fermato");
  }

  void dispose() {
    _porcupineManager?.delete();
    _porcupineManager = null;
  }
}