import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AzureTtsService {
  // TODO: insert your own Azure Speech key/region (https://portal.azure.com) — do not commit real keys.
  static const String _apiKey = 'YOUR_AZURE_SPEECH_KEY';
  static const String _region = 'YOUR_AZURE_REGION';

  static final AudioPlayer _player = AudioPlayer();

  // 🔥 CALLBACK quando la TTS è finita
  static Function()? onCompleted;

  static int _playbackId = 0;
  static bool _isSpeaking = false;

  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    final int myPlayback = ++_playbackId;
    _isSpeaking = true;

    await _player.stop();

    final uri = Uri.parse(
      'https://$_region.tts.speech.microsoft.com/cognitiveservices/v1',
    );

    final ssml = '''
<speak version="1.0" xml:lang="it-IT">
  <voice name="it-IT-ElsaNeural">
    ${_escapeXml(text)}
  </voice>
</speak>
''';

    final response = await http.post(
      uri,
      headers: {
        'Ocp-Apim-Subscription-Key': _apiKey,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': 'riff-24khz-16bit-mono-pcm',
      },
      body: ssml,
    );

    final file = await _writeTempFile(response.bodyBytes);

    await _player.setFilePath(file.path);
    await _player.play();

    // 🔥 UNICO punto di completion valido
    await _player.processingStateStream
        .where((s) => s == ProcessingState.completed)
        .first;

    // ⚠️ ignora completion vecchie
    if (myPlayback != _playbackId) return;

    _isSpeaking = false;
    onCompleted?.call();
  }

  static Future<File> _writeTempFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tts.wav');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String _escapeXml(String text) =>
      const HtmlEscape(HtmlEscapeMode.element).convert(text);

  static Future<void> stopSafely() async {
    try {
      await _player.stop();
    } catch (e) {
      print("⚠️ stopSafely ignored error: $e");
    }
  }

}