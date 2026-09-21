import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'patient_page.dart';
import 'theme/app_theme.dart';

class PatientsPage extends StatefulWidget {
  final String carerId;
  const PatientsPage({super.key, required this.carerId});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> patients = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getPatients();
  }

  Future<void> getPatients() async {
    try {
      final data = await supabase
          .from('patients')
          .select('*')
          .eq('carer_id', widget.carerId);

      setState(() {
        patients = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint('❌ Errore nel caricamento pazienti: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text(
            "Sei sicuro di voler effettuare il logout?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _logout(context);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
            (route) => false,
      );
    } catch (e) {
      debugPrint("❌ Errore logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        appBar: AppBar(
          title: const Text("Pazienti"),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.redAccent,
              ),
              tooltip: "Logout",
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),

      // =========================
      // FAB – TEST VISIONE
      // =========================
      /*floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const VisionTestLivePage(),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text("Visione"),
      ),*/

      // =========================
      // BODY
      // =========================
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : patients.isEmpty
          ? const Center(
        child: Text(
          "Nessun paziente trovato",
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: patients.length,
        separatorBuilder: (_, __) =>
        const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final p = patients[index];
          return _PatientCard(
            patient: p,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientPage(patient: p),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String name = patient['name'] ?? '';
    final String surname = patient['surname'] ?? '';
    final String initials = _getInitials(name, surname);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // =========================
              // AVATAR (iniziali / foto)
              // =========================
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: ClipOval(
                  child: _hasImage(patient)
                      ? Image.network(
                    patient['image_url'],
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initialsAvatar(initials),
                  )
                      : _initialsAvatar(initials),
                ),
              ),

              const SizedBox(width: 16),

              // =========================
              // INFO
              // =========================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$name $surname",
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Data di nascita: ${patient['dateOfBirth'] ?? '-'}",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // =========================
              // CHEVRON (iOS)
              // =========================
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsAvatar(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  String _getInitials(String name, String surname) {
    final n = name.isNotEmpty ? name[0] : '';
    final s = surname.isNotEmpty ? surname[0] : '';
    return (n + s).toUpperCase();
  }

  bool _hasImage(Map<String, dynamic> patient) {
    final url = patient['image_url'];
    return url != null && url.toString().trim().isNotEmpty;
  }
}


