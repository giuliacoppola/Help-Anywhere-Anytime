import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  // TODO: insert your own Groq API key (https://console.groq.com) — do not commit real keys.
  static const String _apiKey = "YOUR_GROQ_API_KEY";
  static const String _endpoint =
      "https://api.groq.com/openai/v1/chat/completions";

  /// Chiamata base alla LLM
  static Future<String> generateResponse({
    required String prompt,
    String systemPrompt =
        "Sei un assistente vocale per anziani."
    "Rispondi in modo semplice, calmo e diretto."
    "Non fare domande se non richieste."
    "Per domande brevi o fattuali usa una sola frase secca."
    "Per domande di aiuto o confusione usa un tono rassicurante."
    "Non aggiungere frasi finali automatiche.",
  }) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "llama-3.1-8b-instant",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": prompt},
        ],
        "temperature": 0.4,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Groq error ${response.statusCode}: ${response.body}",
      );
    }

    final decoded = jsonDecode(response.body);
    final text = decoded["choices"][0]["message"]["content"];

    // LOG DI DEBUG
    print("🤖 Risposta LLM (Groq): $text");

    return text;
  }
}
