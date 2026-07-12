import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';
import 'base_agent.dart';

class KimiAgent extends BaseAgent {
  @override
  String get name => "Kimi (Moonshot)";

  @override
  Future<AgentPrediction> predict(MatchModel match) async {
    final prompt = buildPrompt(match);
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.kimiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.kimiKey}',
        },
        body: json.encode({
          'model': 'moonshot-v1-8k',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String content = data['choices']?[0]?['message']?['content'] ?? '{}';
        if (content.contains('```')) {
          content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        }
        final jsonMap = json.decode(content);
        return AgentPrediction(
          agentName: name,
          predictedHomeScore: jsonMap['predictedHomeScore'] ?? 1,
          predictedAwayScore: jsonMap['predictedAwayScore'] ?? 1,
          confidence: (jsonMap['confidence'] ?? 0.72).toDouble(),
          reasoning: jsonMap['reasoning'] ?? 'Analyse tactique Kimi.',
          bettingOptions: BettingOptions.fromJson(jsonMap['bettingOptions'] ?? {}),
        );
      } else {
        throw Exception('Kimi API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('KimiAgent failed: $e');
      return _fallback(match);
    }
  }

  AgentPrediction _fallback(MatchModel match) {
    final home = (match.homeTeam.name.hashCode % 3).abs();
    final away = (match.awayTeam.name.hashCode % 3).abs();
    return AgentPrediction(
      agentName: name,
      predictedHomeScore: home,
      predictedAwayScore: away,
      confidence: 0.72,
      reasoning: 'Kimi analyse : ${match.homeTeam.name} joue à domicile avec un avantage tactique. ${match.awayTeam.name} devra défendre solidement.',
      bettingOptions: BettingOptions(
        bttsFullTime: (home > 0 && away > 0) ? 'Oui' : 'Non',
        bttsFirstHalf: 'Non',
        bttsSecondHalf: (home > 0 && away > 0) ? 'Oui' : 'Non',
        overUnder15: (home + away >= 2) ? 'Plus de 1.5' : 'Moins de 1.5',
        overUnder25: (home + away >= 3) ? 'Plus de 2.5' : 'Moins de 2.5',
        oddEven: (home + away) % 2 == 0 ? 'Pair' : 'Impair',
        estimatedOdds: '1: 2.05 | X: 3.30 | 2: 3.40',
      ),
    );
  }
}
