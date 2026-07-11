import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';

class AiFootballFallbackService {
  final http.Client _client = http.Client();

  /// Interroge l'IA (Perplexity / Grok / Gemini) avec recherche Web pour récupérer les matchs réels du jour.
  Future<List<MatchModel>> fetchMatchesFromAI() async {
    try {
      debugPrint('🔍 Tentative de récupération des matchs réels via Perplexity Search...');
      return await _fetchFromPerplexity();
    } catch (e) {
      debugPrint('⚠️ Perplexity a échoué: $e. Tentative via Grok...');
      try {
        return await _fetchFromGrok();
      } catch (e2) {
        debugPrint('⚠️ Grok a échoué: $e2. Tentative via Gemini...');
        try {
          return await _fetchFromGemini();
        } catch (e3) {
          debugPrint('❌ Toutes les IAs ont échoué pour les matchs du jour: $e3');
          return [];
        }
      }
    }
  }

  /// 1. Récupération via Perplexity (Excellent pour la recherche web en temps réel)
  Future<List<MatchModel>> _fetchFromPerplexity() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final prompt = _buildSearchPrompt(today);

    final response = await _client.post(
      Uri.parse(ApiConstants.perplexityBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.perplexityKey}',
      },
      body: json.encode({
        'model': 'sonar', // Modèle Perplexity avec recherche Web
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.1,
      }),
    );

    if (response.statusCode == 200) {
      return _parseAiResponse(response.body);
    } else {
      throw Exception('Perplexity API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// 2. Récupération via Grok (xAI)
  Future<List<MatchModel>> _fetchFromGrok() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final prompt = _buildSearchPrompt(today);

    final response = await _client.post(
      Uri.parse(ApiConstants.grokBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.grokKey}',
      },
      body: json.encode({
        'model': 'grok-2-public', // Modèle Grok
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.1,
      }),
    );

    if (response.statusCode == 200) {
      return _parseAiResponse(response.body);
    } else {
      throw Exception('Grok API error: ${response.statusCode}');
    }
  }

  /// 3. Récupération via Gemini (Dernière étape)
  Future<List<MatchModel>> _fetchFromGemini() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final prompt = _buildSearchPrompt(today);

    final response = await _client.post(
      Uri.parse('${ApiConstants.geminiBaseUrl}?key=${ApiConstants.geminiKey1}'),
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
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String textContent = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '[]';
      return _parseRawJsonList(textContent);
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  /// Prompt d'extraction des matchs réels
  String _buildSearchPrompt(String dateStr) {
    return '''
Recherche sur le web (BetPawa, 1XBet, Flashscore, etc.) les matchs de football réels programmés ou en direct pour aujourd'hui ($dateStr).
Retourne uniquement les 8 matchs les plus importants (Premier League, La Liga, Ligue 1, Serie A, Champions League ou grands championnats).

Tu DOIS retourner un tableau JSON d'objets respectant STRICTEMENT cette structure (ne mets pas de balises markdown ```json ou d'explications textuelles, seulement le JSON brut) :
[
  {
    "id": "ai-match-1",
    "homeTeam": {
      "id": "team-home-1",
      "name": "Nom Equipe Domicile",
      "logo": "URL logo ou chaîne vide"
    },
    "awayTeam": {
      "id": "team-away-1",
      "name": "Nom Equipe Exterieur",
      "logo": "URL logo ou chaîne vide"
    },
    "league": {
      "id": "league-1",
      "name": "Nom du Championnat (ex: Premier League)",
      "logo": "URL logo ou chaîne vide",
      "country": "Pays (ex: England)"
    },
    "dateTime": "Date au format ISO8601 UTC (ex: 2026-07-11T20:00:00Z)",
    "status": "scheduled", 
    "homeScore": null,
    "awayScore": null,
    "timeElapsed": null,
    "round": "Matchday X"
  }
]

Remarques pour les logos : Si tu ne connais pas le logo exact d'une équipe ou d'un championnat, laisse la clé "logo" vide ("").
Le status doit être : "live", "scheduled", ou "finished".
''';
  }

  /// Extraction et nettoyage du JSON des réponses standard IA (de type chat completion)
  List<MatchModel> _parseAiResponse(String responseBody) {
    final data = json.decode(responseBody);
    String content = data['choices']?[0]?['message']?['content'] ?? '[]';
    return _parseRawJsonList(content);
  }

  List<MatchModel> _parseRawJsonList(String rawJson) {
    var clean = rawJson.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    }
    if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    clean = clean.trim();

    final List<dynamic> list = json.decode(clean);
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      
      // Injecter des logos par défaut si vides
      final homeName = map['homeTeam']?['name'] ?? 'Équipe A';
      final awayName = map['awayTeam']?['name'] ?? 'Équipe B';
      
      if (map['homeTeam']?['logo'] == null || map['homeTeam']?['logo'].toString().isEmpty) {
        map['homeTeam']['logo'] = 'https://api.dicebear.com/7.x/identicon/png?seed=${Uri.encodeComponent(homeName)}';
      }
      if (map['awayTeam']?['logo'] == null || map['awayTeam']?['logo'].toString().isEmpty) {
        map['awayTeam']['logo'] = 'https://api.dicebear.com/7.x/identicon/png?seed=${Uri.encodeComponent(awayName)}';
      }
      if (map['league']?['logo'] == null || map['league']?['logo'].toString().isEmpty) {
        map['league']['logo'] = 'https://api.dicebear.com/7.x/initials/png?seed=${Uri.encodeComponent(map['league']?['name'] ?? 'L')}';
      }

      return MatchModel.fromJson(map);
    }).toList();
  }
}
