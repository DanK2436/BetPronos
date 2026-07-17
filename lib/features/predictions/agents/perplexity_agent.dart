import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';
import 'base_agent.dart';

class PerplexityAgent extends BaseAgent {
  @override
  String get name => "Perplexity (Web)";

  @override
  String buildPrompt(MatchModel match) {
    return '''
Tu es un expert en football doté de la capacité de recherche web en temps réel.
Recherche sur internet les informations les plus récentes sur le match suivant :

**Match :** ${match.homeTeam.name} vs ${match.awayTeam.name}
**Championnat :** ${match.league.name} (${match.league.country})
**Date :** ${match.dateTime.toLocal().toString()}

**Recherche obligatoire avant de répondre :**
1. Forme récente des 5 derniers matchs des deux équipes (résultats W/D/L)
2. Blessures et suspensions actuelles dans les deux équipes
3. Confrontations directes récentes (H2H) entre ces deux équipes
4. Cotes actuelles sur BetPawa, 1XBet ou Betway pour ce match (1/X/2)
5. Position au classement dans leur championnat respectif

Sur la base de TOUTES ces informations récentes, génère ta prédiction au format JSON STRICT ci-dessous.
Réponds UNIQUEMENT avec le JSON brut, sans markdown, sans explications :

{
  "predictedHomeScore": 1,
  "predictedAwayScore": 1,
  "confidence": 0.75,
  "reasoning": "Explication basée sur les données récentes récupérées en ligne.",
  "bettingOptions": {
    "bttsFullTime": "Oui",
    "bttsFirstHalf": "Non",
    "bttsSecondHalf": "Oui",
    "overUnder15": "Plus de 1.5",
    "overUnder25": "Moins de 2.5",
    "oddEven": "Pair",
    "estimatedOdds": "1: 2.10 | X: 3.20 | 2: 3.60"
  }
}
''';
  }

  @override
  Future<AgentPrediction> predict(MatchModel match) async {
    final prompt = buildPrompt(match);
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.perplexityBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.perplexityKey}',
        },
        body: json.encode({
          'model': 'sonar-pro',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Tu es un expert en analyse de football. Tu dois effectuer des recherches web pour obtenir des données récentes et précises. Réponds toujours en JSON brut uniquement, sans markdown.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.2,
          'max_tokens': 1024,
          'search_recency_filter': 'week',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String content =
            data['choices']?[0]?['message']?['content'] ?? '{}';
        if (content.contains('```')) {
          content = content
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
        }
        // Extract JSON if surrounded by text
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          content = content.substring(jsonStart, jsonEnd + 1);
        }
        final jsonMap = json.decode(content);
        return AgentPrediction(
          agentName: name,
          predictedHomeScore: parseScore(jsonMap, 'Home'),
          predictedAwayScore: parseScore(jsonMap, 'Away'),
          confidence: (jsonMap['confidence'] ?? 0.75).toDouble(),
          reasoning: jsonMap['reasoning'] ?? 'Analyse basée sur données web récentes.',
          bettingOptions: BettingOptions.fromJson(
            jsonMap['bettingOptions'] ?? {},
          ),
        );
      } else {
        throw Exception('Perplexity API: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      debugPrint('PerplexityAgent failed: $e');
      return getDynamicFallback(match, name);
    }
  }
}
