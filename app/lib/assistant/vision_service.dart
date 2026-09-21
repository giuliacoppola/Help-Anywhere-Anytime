import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VisionService {
  // ⚠️ SOSTITUISCI CON IL TUO IP LOCALE
  // Se usi Emulatore Android: 'http://10.0.2.2:8000'
  // Se usi Dispositivo Fisico: 'http://192.168.1.X:8000' (es. il tuo IP LAN)
  final String baseUrl = 'http://192.168.1.111:8000';

  /// Invia l'immagine al backend Python e restituisce la lista degli oggetti trovati.
  Future<List<String>> analyzeImage(File imageFile) async {
    final uri = Uri.parse('$baseUrl/detect-objects');

    try {
      // Creiamo la richiesta Multipart per inviare il file
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Questo deve corrispondere al parametro del backend (file: UploadFile)
          imageFile.path,
        ),
      );

      // Inviamo la richiesta
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Il backend restituisce: { "objects_detected": n, "objects": [...] }
        List<dynamic> objects = data['objects'];
        
        // Estraiamo solo i nomi delle classi (es. "oven", "person")
        List<String> detectedClasses = objects
            .map((obj) => obj['class_name'].toString())
            .toList();

        print("👁️ VisionService: Oggetti rilevati -> $detectedClasses");
        return detectedClasses;
      } else {
        print("❌ VisionService Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ VisionService Exception: $e");
      return [];
    }
  }

  /// Metodo helper specifico per cercare un forno
  Future<bool> containsOven(File imageFile) async {
    final objects = await analyzeImage(imageFile);
    return objects.contains('oven');
  }
}