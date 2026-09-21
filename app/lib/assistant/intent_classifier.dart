class IntentClassifier {
  String classify(String text) {
    text = text.toLowerCase();

    // Intento: RICHIESTA DI AIUTO
    if (text.contains("aiuto") ||
        text.contains("male") ||
        text.contains("sto male") ||
        text.contains("paura") ||
        text.contains("non sto bene")) {
      return "HELP";
    }

    // Intento: CONFUSIONE / SMARRIMENTO
    if (text.contains("dove") ||
        text.contains("dove sono") ||
        text.contains("chi sono") ||
        text.contains("non ricordo") ||
        text.contains("non so")) {
      return "CONFUSION";
    }

    // Intento: TERAPIA / MEDICINE
    if (text.contains("medicina") ||
        text.contains("pillola") ||
        text.contains("farmaco") ||
        text.contains("terapia") ||
        text.contains("ora della medicina") ||
        text.contains("devo prendere")) {
      return "THERAPY";
    }

    // Intento generico
    return "GENERAL_QUESTION";
  }
}
