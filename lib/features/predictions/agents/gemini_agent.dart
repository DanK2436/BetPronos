import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';
import 'base_agent.dart';

class GeminiAgent extends BaseAgent {
  @override
  String get name => "Gemini 1.5 Pro";

  @override
  Future<AgentPrediction> predict(MatchModel match) async {
    final prompt = buildPrompt(match);
    
    try {
      return await _callGeminiApi(prompt, ApiConstants.geminiKey1, match);
    } catch (e) {
      debugPrint('Gemini Key 1 failed: $e. Trying Key 2...');
      try {
        return await _callGeminiApi(prompt, ApiConstants.geminiKey2, match);
      } catch (err) {
        debugPrint('Gemini Key 2 failed: $err. Using mock backup...');
        return _fallbackPrediction(match);
      }
    }
  }

  Future<AgentPrediction> _callGeminiApi(String prompt, String apiKey, MatchModel match) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
        }
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String textContent = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
      final cleanJson = _cleanJsonString(textContent);
      final jsonMap = json.decode(cleanJson);
      
      return AgentPrediction(
        agentName: name,
        predictedHomeScore: parseScore(jsonMap, 'Home'),
        predictedAwayScore: parseScore(jsonMap, 'Away'),
        confidence: (jsonMap['confidence'] ?? 0.70).toDouble(),
        reasoning: jsonMap['reasoning'] ?? 'Analyse des données historiques.',
        bettingOptions: BettingOptions.fromJson(jsonMap['bettingOptions'] ?? {}),
      );
    } else {
      throw Exception('Gemini API returned status code ${response.statusCode}');
    }
  }

  String _cleanJsonString(String text) {
    var clean = text.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    return clean.trim();
  }

  AgentPrediction _fallbackPrediction(MatchModel match) {
    return getDynamicFallback(match, name);
  }
}
