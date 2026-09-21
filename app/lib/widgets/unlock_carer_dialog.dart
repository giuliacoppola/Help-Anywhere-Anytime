import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../patients_page.dart';

class UnlockCarerDialog extends StatefulWidget {
  const UnlockCarerDialog({super.key});

  @override
  State<UnlockCarerDialog> createState() => _UnlockCarerDialogState();
}

class _UnlockCarerDialogState extends State<UnlockCarerDialog> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  Future<void> _unlock() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response =
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = response.user;

      if (user != null && mounted) {
        // chiude il dialog
        Navigator.of(context).pop();

        // sostituisce la PatientPage come un login normale
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PatientsPage(carerId: user.id),
          ),
        );
      } else {
        setState(() {
          errorMessage = "Credenziali non valide";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Errore di accesso. Riprova.";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =========================
              // TITLE
              // =========================
              Text(
                "Esci",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.redAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Torna alla lista dei pazienti",
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // =========================
              // EMAIL
              // =========================
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "Email",
                ),
              ),

              const SizedBox(height: 16),

              // =========================
              // PASSWORD
              // =========================
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password",
                ),
              ),

              const SizedBox(height: 24),

              // =========================
              // BUTTON
              // =========================
              ElevatedButton(
                onPressed: loading ? null : _unlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: loading
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text("Torna ai pazienti"),
              ),

              // =========================
              // ERROR
              // =========================
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
