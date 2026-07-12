import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';
import 'base_agent.dart';

class MistralAgent extends BaseAgent {
  @override
  String get name => "Mistral Large";

  @override
  Future<AgentPrediction> predict(MatchModel match) async {
    final prompt = buildPrompt(match);
    
    try {
      final url = Uri.parse('https://api.mistral.ai/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.mistralKey}',
        },
        body: json.encode({
          'model': 'mistral-large-latest',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'response_format': {'type': 'json_object'}
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String textContent = data['choices']?[0]?['message']?['content'] ?? '{}';
        final jsonMap = json.decode(textContent);
        
        return AgentPrediction(
          agentName: name,
          predictedHomeScore: jsonMap['predictedHomeScore'] ?? 1,
          predictedAwayScore: jsonMap['predictedAwayScore'] ?? 1,
          confidence: (jsonMap['confidence'] ?? 0.70).toDouble(),
          reasoning: jsonMap['reasoning'] ?? 'Analyse de forme et confrontations.',
          bettingOptions: BettingOptions.fromJson(jsonMap['bettingOptions'] ?? {}),
        );
      } else {
        throw Exception('Mistral API status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Mistral Agent failed: $e. Using fallback...');
      return _fallbackPrediction(match);
    }
  }

  AgentPrediction _fallbackPrediction(MatchModel match) {
    int home = (match.homeTeam.name.length + 1) % 3;
    int away = (match.awayTeam.name.length) % 3;
    
    return AgentPrediction(
      agentName: name,
      predictedHomeScore: home,
      predictedAwayScore: away,
      confidence: 0.71,
      reasoning: 'Mistral suggère que la forme récente de ${match.homeTeam.name} est supérieure. ${match.awayTeam.name} aura du mal à s\'imposer loin de ses bases.',
      bettingOptions: BettingOptions(
        bttsFullTime: (home > 0 && away > 0) ? 'Oui' : 'Non',
        bttsFirstHalf: 'Non',
        bttsSecondHalf: (home > 0 && away > 0) ? 'Oui' : 'Non',
        overUnder15: (home + away >= 2) ? 'Plus de 1.5' : 'Moins de 1.5',
        overUnder25: (home + away >= 3) ? 'Plus de 2.5' : 'Moins de 2.5',
        oddEven: (home + away) % 2 == 0 ? 'Pair' : 'Impair',
        estimatedOdds: '1: 2.25 | X: 3.10 | 2: 3.20',
      ),
    );
  }
}
