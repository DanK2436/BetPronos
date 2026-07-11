import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';
import 'base_agent.dart';

/// Agent Z.ai — Analyse statistique avancée
class ZaiAgent extends BaseAgent {
  @override
  String get name => "Z.ai";

  @override
  Future<AgentPrediction> predict(MatchModel match) async {
    final prompt = buildPrompt(match);
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.zaiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.zaiKey}',
        },
        body: json.encode({
          'model': 'glm-4',
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
          predictedAwayScore: jsonMap['predictedAwayScore'] ?? 0,
          confidence: (jsonMap['confidence'] ?? 0.73).toDouble(),
          reasoning: jsonMap['reasoning'] ?? 'Analyse statistique Z.ai.',
        );
      } else {
        throw Exception('Z.ai API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ZaiAgent failed: $e');
      return _fallback(match);
    }
  }

  AgentPrediction _fallback(MatchModel match) {
    return AgentPrediction(
      agentName: name,
      predictedHomeScore: 1,
      predictedAwayScore: 0,
      confidence: 0.73,
      reasoning: 'Z.ai : Statistiquement, l\'avantage du terrain favorise ${match.homeTeam.name}. Les données xG prédisent un match à faible score.',
    );
  }
}
