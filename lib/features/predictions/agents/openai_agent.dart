import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';
import 'base_agent.dart';

class OpenAiAgent extends BaseAgent {
  @override
  String get name => "GPT-4o";

  @override
  Future<AgentPrediction> predict(MatchModel match) async {
    final prompt = buildPrompt(match);
    
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.openAiKey}',
        },
        body: json.encode({
          'model': 'gpt-4o',
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
          confidence: (jsonMap['confidence'] ?? 0.75).toDouble(),
          reasoning: jsonMap['reasoning'] ?? 'Analyse tactique approfondie.',
          bettingOptions: BettingOptions.fromJson(jsonMap['bettingOptions'] ?? {}),
        );
      } else {
        throw Exception('OpenAI API status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenAI Agent failed: $e. Using fallback...');
      return _fallbackPrediction(match);
    }
  }

  AgentPrediction _fallbackPrediction(MatchModel match) {
    return getDynamicFallback(match, name);
  }
}
