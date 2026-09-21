import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AlertCarerPage extends StatefulWidget {
  const AlertCarerPage({super.key});

  @override
  State<AlertCarerPage> createState() => _AlertCarerPageState();
}

class _AlertCarerPageState extends State<AlertCarerPage> {
  bool isSending = false;

  Future<void> _sendAlert() async {
    setState(() => isSending = true);

    try {
      // 1️⃣ Recupera l'utente loggato
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utente non autenticato")),
        );
        setState(() => isSending = false);
        return;
      }

      final userEmail = user.email;
      if (userEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email utente non disponibile")),
        );
        setState(() => isSending = false);
        return;
      }

      // 2️⃣ Invia richiesta al backend / funzione serverless per mandare la mail
      // Sostituisci con il tuo endpoint reale
      final url = Uri.parse('https://tuo-backend.com/send-alert');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_email': userEmail,
          'message': 'Attenzione! Evento pericoloso rilevato.',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alert inviato al carer!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore nell'invio: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e")),
      );
    } finally {
      setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invia alert al carer")),
      body: Center(
        child: ElevatedButton(
          onPressed: isSending ? null : _sendAlert,
          child: isSending
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Invia alert al carer"),
        ),
      ),
    );
  }
}
