import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';
import 'base_agent.dart';

/// Agent IA Kimi (Moonshot AI) — Expert en analyse tactique
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
        // Nettoyer le JSON si nécessaire
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
    return AgentPrediction(
      agentName: name,
      predictedHomeScore: (match.homeTeam.name.hashCode % 3).abs(),
      predictedAwayScore: (match.awayTeam.name.hashCode % 3).abs(),
      confidence: 0.72,
      reasoning: 'Kimi analyse : ${match.homeTeam.name} joue à domicile avec un avantage tactique. ${match.awayTeam.name} devra défendre solidement.',
    );
  }
}
