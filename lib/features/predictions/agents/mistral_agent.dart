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
          predictedHomeScore: parseScore(jsonMap, 'Home'),
          predictedAwayScore: parseScore(jsonMap, 'Away'),
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
    return getDynamicFallback(match, name);
  }
}
