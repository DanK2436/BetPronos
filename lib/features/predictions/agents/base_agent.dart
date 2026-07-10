import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';

abstract class BaseAgent {
  String get name;
  
  Future<AgentPrediction> predict(MatchModel match);

  String buildPrompt(MatchModel match) {
    return '''
Tu es un agent IA expert en analyse de football pour l'application betPronos.
Analyse le match suivant et prédis le score exact de fin de match.

Détails du match :
- Championnat : ${match.league.name} (${match.league.country})
- Équipe à domicile : ${match.homeTeam.name}
- Équipe à l'extérieur : ${match.awayTeam.name}
- Date/Heure : ${match.dateTime.toLocal().toString()}

Instructions :
1. Prédis le score exact (Home Score et Away Score).
2. Fournis un pourcentage de confiance entre 0.0 et 1.0 (ex: 0.75 pour 75%).
3. Fournis une explication logique en français (maximum 3 phrases).
4. Tu DOIS répondre EXCLUSIVEMENT au format JSON comme suit, sans texte explicatif en dehors du bloc JSON :
{
  "predictedHomeScore": 2,
  "predictedAwayScore": 1,
  "confidence": 0.75,
  "reasoning": "Real Madrid est en grande forme à domicile et Barcelone a des blessés en défense. Historiquement, le Real domine à domicile."
}
''';
  }
}
