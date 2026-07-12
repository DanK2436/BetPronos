import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';

abstract class BaseAgent {
  String get name;
  
  Future<AgentPrediction> predict(MatchModel match);

  String buildPrompt(MatchModel match) {
    return '''
Tu es un agent IA expert en analyse de football pour l'application betPronos.
Analyse le match suivant en profondeur. Effectue une recherche web si nécessaire sur les sites de paris sportifs comme BetPawa et 1XBet pour obtenir les côtes réelles actuelles (1, X, 2) et les statistiques des deux équipes.

Détails du match :
- Championnat : ${match.league.name} (${match.league.country})
- Équipe à domicile : ${match.homeTeam.name}
- Équipe à l'extérieur : ${match.awayTeam.name}
- Date/Heure : ${match.dateTime.toLocal().toString()}

Instructions - Tu DOIS générer les prédictions et analyses suivantes :
1. Prédis le score exact de fin de match (Home Score et Away Score).
2. Estime un indice de confiance global entre 0.0 et 1.0 (ex: 0.78 pour 78%).
3. Fournis une explication logique courte en français (maximum 3 phrases) sur la dynamique et les blessures clés.
4. Analyse les possibilités de paris sportifs suivantes :
   - Les deux équipes marquent (BTTS) Match Complet : "Oui" ou "Non"
   - Les deux équipes marquent (BTTS) 1ère mi-temps : "Oui" ou "Non"
   - Les deux équipes marquent (BTTS) 2ème mi-temps : "Oui" ou "Non"
   - Moins de / Plus de 1.5 buts : "Plus de 1.5" ou "Moins de 1.5"
   - Moins de / Plus de 2.5 buts : "Plus de 2.5" ou "Moins de 2.5"
   - Total de buts pair ou impair : "Pair" ou "Impair"
   - Cotes réelles estimées : Les cotes pour Victoire Domicile, Match Nul, Victoire Extérieur (format ex: "1: 1.80 | X: 3.40 | 2: 4.20 (BetPawa/1XBet)")

Tu DOIS répondre EXCLUSIVEMENT au format JSON brut ci-dessous, sans texte d'introduction ni de conclusion, sans bloc de code markdown. Réponds uniquement par le JSON respectant cette structure exacte :
{
  "predictedHomeScore": 2,
  "predictedAwayScore": 1,
  "confidence": 0.78,
  "reasoning": "Le Real Madrid est impérial à domicile et dispose de son effectif complet. Barcelone montre des lacunes défensives à l'extérieur lors des derniers matchs.",
  "bettingOptions": {
    "bttsFullTime": "Oui",
    "bttsFirstHalf": "Non",
    "bttsSecondHalf": "Oui",
    "overUnder15": "Plus de 1.5",
    "overUnder25": "Plus de 2.5",
    "oddEven": "Impair",
    "estimatedOdds": "1: 1.85 | X: 3.40 | 2: 4.10"
  }
}
''';
  }
}
