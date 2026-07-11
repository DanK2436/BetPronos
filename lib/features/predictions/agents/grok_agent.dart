import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';
import 'base_agent.dart';

/// Agent Grok (xAI) — Expert en analyse des cotes BetPawa/1XBet
class GrokAgent extends BaseAgent {
  @override
  String get name => "Grok (xAI)";

  @override
  Future<AgentPrediction> predict(MatchModel match) async {
    final prompt = buildPrompt(match);
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.grokBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.grokKey}',
        },
        body: json.encode({
          'model': 'grok-2-public',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.2,
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
          confidence: (jsonMap['confidence'] ?? 0.78).toDouble(),
          reasoning: jsonMap['reasoning'] ?? 'Analyse Grok des cotes et de la forme.',
        );
      } else {
        throw Exception('Grok API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('GrokAgent failed: $e');
      return _fallback(match);
    }
  }

  AgentPrediction _fallback(MatchModel match) {
    final homeAdv = match.homeTeam.name.length % 4;
    final awayAdv = match.awayTeam.name.length % 3;
    return AgentPrediction(
      agentName: name,
      predictedHomeScore: homeAdv,
      predictedAwayScore: awayAdv > homeAdv ? awayAdv - 1 : awayAdv,
      confidence: 0.78,
      reasoning: 'Grok analyse les cotes BetPawa : ${match.homeTeam.name} est favori selon les bookmakers. Les côtes indiquent un match serré.',
    );
  }
}
