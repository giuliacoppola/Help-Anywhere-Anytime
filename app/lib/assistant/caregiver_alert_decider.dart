class CaregiverAlertDecider {
  static bool shouldNotify({
    required String text,
    required String intent,
  }) {
    final t = text.toLowerCase();

    // 🔴 INTENTI SEMPRE CRITICI
    if (intent == "HELP") return true;
    if (intent == "THERAPY") return true;

    // 🟠 CONFUSION → va analizzato
    if (intent == "CONFUSION") {
      return _isPersonalConfusion(t);
    }

    return false;
  }

  // ------------------------------------------------------

  static bool _isPersonalConfusion(String text) {
    // Deve parlare DI SÉ
    final selfMarkers = [
      "io",
      "mi",
      "me",
      "sono",
      "sto",
      "ricordo",
      "non ricordo",
      "non so chi sono",
      "non so dove sono",
    ];

    final hasSelfReference =
    selfMarkers.any((w) => text.contains(w));

    if (!hasSelfReference) return false;

    // Deve indicare smarrimento reale
    final confusionMarkers = [
      "non so",
      "non ricordo",
      "sono perso",
      "mi sono perso",
      "dove sono",
      "non capisco",
    ];

    final hasConfusion =
    confusionMarkers.any((w) => text.contains(w));

    if (!hasConfusion) return false;

    // 🟢 Filtri per domande INFORMATIVE (sport, geografia, ecc.)
    final safeTopics = [
      "concert",
      "evento",
      "partita",
      "stadio",
      "meteo",
      "tempo",
      "oggi",
      "domani",
      "città",
      "capitale",
    ];

    final isInformational =
    safeTopics.any((w) => text.contains(w));

    if (isInformational) return false;

    return true;
  }
}
