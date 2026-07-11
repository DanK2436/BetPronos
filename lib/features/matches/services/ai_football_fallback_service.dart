import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';

class AiFootballFallbackService {
  final http.Client _client = http.Client();

  /// Interroge l'IA (Perplexity / Grok / Gemini) avec recherche Web pour récupérer les matchs réels de toutes les compétitions du jour.
  Future<List<MatchModel>> fetchMatchesFromAI() async {
    try {
      debugPrint('🔍 Récupération de tous les matchs via Perplexity...');
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

  /// 1. Récupération via Perplexity
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
        'model': 'sonar',
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
        'model': 'grok-2-public',
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

  /// 3. Récupération via Gemini
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

  /// Prompt de recherche globale des matchs réels de toutes les compétitions du jour
  String _buildSearchPrompt(String dateStr) {
    return '''
Recherche sur le web (BetPawa, 1XBet, Flashscore, etc.) les matchs de football réels programmés ou en direct pour aujourd'hui et les prochaines 48 heures ($dateStr).
Inclus des matchs de TOUTES les compétitions de football possibles (Europe, Afrique, Amérique du Sud, etc., ex: Ligue des Champions, Premier League, La Liga, Ligue 1, CAF, Ligue 1 Congolaise, etc.).
Retourne les 20 matchs les plus importants et intéressants pour les parieurs.

Tu DOIS retourner un tableau JSON d'objets respectant STRICTEMENT cette structure (ne mets pas de balises markdown ```json ou d'explications, seulement le JSON brut) :
[
  {
    "id": "ai-match-1",
    "homeTeam": {
      "id": "team-home-1",
      "name": "Nom Equipe Domicile",
      "logo": ""
    },
    "awayTeam": {
      "id": "team-away-1",
      "name": "Nom Equipe Exterieur",
      "logo": ""
    },
    "league": {
      "id": "league-1",
      "name": "Nom du Championnat",
      "logo": "",
      "country": "Pays"
    },
    "dateTime": "Date au format ISO8601 UTC (ex: 2026-07-11T20:00:00Z)",
    "status": "scheduled", 
    "homeScore": null,
    "awayScore": null,
    "timeElapsed": null,
    "round": "Matchday X"
  }
]
''';
  }

  /// Vérifie et met à jour en temps réel les scores de la liste de matchs fournie en interrogeant l'IA
  Future<List<MatchModel>> verifyLiveScoresWithAI(List<MatchModel> currentMatches) async {
    if (currentMatches.isEmpty) return currentMatches;

    final List<Map<String, dynamic>> matchesData = currentMatches.map((m) => {
      'id': m.id,
      'home': m.homeTeam.name,
      'away': m.awayTeam.name,
      'league': m.league.name,
      'status': m.status.name,
    }).toList();

    final prompt = '''
Fais une recherche web immédiate pour obtenir les scores en temps réel de ces matchs de football qui se jouent aujourd'hui.
Trouve leur score actuel (ou score final si terminé), leur statut actuel ('live', 'finished', 'scheduled') et le temps écoulé si en direct.

Liste des matchs à vérifier :
${json.encode(matchesData)}

Retourne UNIQUEMENT un tableau JSON structuré comme suit (sans balise markdown, seulement le JSON brut) :
[
  {
    "id": "match-id-ici",
    "status": "live", 
    "homeScore": 2,
    "awayScore": 1,
    "timeElapsed": "75'"
  }
]
''';

    try {
      debugPrint('🔍 IA Score Check: Vérification en temps réel des scores via Perplexity...');
      final response = await _client.post(
        Uri.parse(ApiConstants.perplexityBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.perplexityKey}',
        },
        body: json.encode({
          'model': 'sonar',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String content = data['choices']?[0]?['message']?['content'] ?? '[]';
        return _updateMatchesWithAiScores(currentMatches, content);
      }
    } catch (e) {
      debugPrint('⚠️ Échec de la vérification des scores par Perplexity: $e. Utilisation de Grok...');
      try {
        final response = await _client.post(
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
            'temperature': 0.1,
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String content = data['choices']?[0]?['message']?['content'] ?? '[]';
          return _updateMatchesWithAiScores(currentMatches, content);
        }
      } catch (e2) {
        debugPrint('⚠️ Grok score check failed: $e2');
      }
    }

    return currentMatches; // Retourner les scores d'origine si l'IA échoue
  }

  /// Applique les scores mis à jour par l'IA sur la liste d'origine
  List<MatchModel> _updateMatchesWithAiScores(List<MatchModel> originalMatches, String jsonScores) {
    try {
      var clean = jsonScores.trim();
      if (clean.startsWith('```json')) clean = clean.substring(7);
      if (clean.startsWith('```')) clean = clean.substring(3);
      if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
      clean = clean.trim();

      final List<dynamic> updatesList = json.decode(clean);
      final Map<String, dynamic> updatesMap = {
        for (var item in updatesList) item['id'].toString(): item
      };

      return originalMatches.map((match) {
        final update = updatesMap[match.id];
        if (update != null) {
          String statusStr = (update['status'] ?? 'scheduled').toString().toLowerCase();
          MatchStatus status;
          if (statusStr.contains('live') || statusStr.contains('in_play') || statusStr.contains('1h') || statusStr.contains('2h') || statusStr.contains('ht')) {
            status = MatchStatus.live;
          } else if (statusStr.contains('ft') || statusStr.contains('finished') || statusStr.contains('ended')) {
            status = MatchStatus.finished;
          } else {
            status = match.status; // garder le statut d'origine si non identifié
          }

          int? homeScore = update['homeScore'] != null ? int.tryParse(update['homeScore'].toString()) : match.homeScore;
          int? awayScore = update['awayScore'] != null ? int.tryParse(update['awayScore'].toString()) : match.awayScore;
          String? timeElapsed = update['timeElapsed']?.toString() ?? match.timeElapsed;

          return MatchModel(
            id: match.id,
            homeTeam: match.homeTeam,
            awayTeam: match.awayTeam,
            league: match.league,
            dateTime: match.dateTime,
            status: status,
            homeScore: homeScore,
            awayScore: awayScore,
            timeElapsed: timeElapsed,
            round: match.round,
          );
        }
        return match;
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors du parsing des scores mis à jour par l\'IA: $e');
      return originalMatches;
    }
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
      
      final homeName = map['homeTeam']?['name'] ?? 'Équipe A';
      final awayName = map['awayTeam']?['name'] ?? 'Équipe B';
      
      final homeLogo = map['homeTeam']?['logo'];
      if (homeLogo == null || homeLogo.toString().isEmpty) {
        map['homeTeam']['logo'] = 'https://api.dicebear.com/7.x/identicon/png?seed=${Uri.encodeComponent(homeName)}';
      }
      final awayLogo = map['awayTeam']?['logo'];
      if (awayLogo == null || awayLogo.toString().isEmpty) {
        map['awayTeam']['logo'] = 'https://api.dicebear.com/7.x/identicon/png?seed=${Uri.encodeComponent(awayName)}';
      }
      final leagueLogo = map['league']?['logo'];
      if (leagueLogo == null || leagueLogo.toString().isEmpty) {
        map['league']['logo'] = 'https://api.dicebear.com/7.x/initials/png?seed=${Uri.encodeComponent(map['league']?['name'] ?? 'L')}';
      }

      return MatchModel.fromJson(map);
    }).toList();
  }
}
