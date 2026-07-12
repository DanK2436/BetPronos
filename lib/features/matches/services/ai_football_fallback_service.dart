import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';

/// Service d'agrégation de matchs de football via recherche web IA.
/// Utilise TOUTES les clés disponibles en cascade :
/// Perplexity → Grok → Gemini-Key1 → Gemini-Key2 → Kimi → Mistral → DeepSeek → Z.ai
class AiFootballFallbackService {
  final http.Client _client = http.Client();

  // ─── RECHERCHE DE MATCHS (72h) ────────────────────────────────────────────

  Future<List<MatchModel>> fetchMatchesFromAI() async {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final prompt = _buildSearchPrompt(dateStr);

    // Cascade de toutes les IAs disponibles
    final List<_AiSource> sources = [
      _AiSource('Perplexity sonar',       () => _callPerplexity(prompt)),
      _AiSource('Grok-2',                 () => _callGrok(prompt)),
      _AiSource('Gemini-Key1',            () => _callGemini(prompt, ApiConstants.geminiKey1)),
      _AiSource('Gemini-Key2',            () => _callGemini(prompt, ApiConstants.geminiKey2)),
      _AiSource('Kimi (Moonshot)',         () => _callKimi(prompt)),
      _AiSource('Mistral Large',          () => _callMistral(prompt)),
      _AiSource('DeepSeek Chat',          () => _callDeepSeek(prompt)),
      _AiSource('Z.ai GLM-4',             () => _callZai(prompt)),
    ];

    for (final source in sources) {
      try {
        debugPrint('🤖 Matchs via ${source.name}...');
        final matches = await source.fetch();
        if (matches.isNotEmpty) {
          debugPrint('✅ ${source.name} → ${matches.length} matchs');
          return matches;
        }
      } catch (e) {
        debugPrint('⚠️ ${source.name} a échoué: $e. Essai suivant...');
      }
    }

    debugPrint('❌ Toutes les IAs ont échoué pour les matchs.');
    return [];
  }

  // ─── VÉRIFICATION SCORES EN TEMPS RÉEL ───────────────────────────────────

  Future<List<MatchModel>> verifyLiveScoresWithAI(List<MatchModel> currentMatches) async {
    if (currentMatches.isEmpty) return currentMatches;

    final matchesData = currentMatches.map((m) => {
      'id': m.id,
      'home': m.homeTeam.name,
      'away': m.awayTeam.name,
      'league': m.league.name,
      'status': m.status.name,
    }).toList();

    final scorePrompt = '''
Fais une recherche web immédiate sur Flashscore, Sofascore ou LiveScore pour les scores en temps réel de ces matchs de football :
${json.encode(matchesData)}

Retourne UNIQUEMENT un tableau JSON brut (sans markdown) :
[{"id":"match-id","status":"live","homeScore":2,"awayScore":1,"timeElapsed":"75'"}]
statuts possibles: live, finished, scheduled
''';

    // Cascade pour les scores
    final List<_AiSource> scoreSources = [
      _AiSource('Perplexity (scores)',  () => _callScoresPerplexity(scorePrompt, currentMatches)),
      _AiSource('Grok (scores)',         () => _callScoresGrok(scorePrompt, currentMatches)),
      _AiSource('Gemini (scores)',       () => _callScoresGemini(scorePrompt, currentMatches, ApiConstants.geminiKey1)),
    ];

    for (final source in scoreSources) {
      try {
        debugPrint('🔍 Scores via ${source.name}...');
        final updated = await source.fetch() as List<MatchModel>;
        debugPrint('✅ ${source.name} → scores mis à jour');
        return updated;
      } catch (e) {
        debugPrint('⚠️ ${source.name} scores failed: $e');
      }
    }

    return currentMatches;
  }

  // ─── IMPLÉMENTATIONS PAR IA ───────────────────────────────────────────────

  Future<List<MatchModel>> _callPerplexity(String prompt) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.perplexityBaseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${ApiConstants.perplexityKey}'},
      body: json.encode({'model': 'sonar', 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.1}),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Perplexity ${res.statusCode}');
    return _parseAiResponse(res.body);
  }

  Future<List<MatchModel>> _callGrok(String prompt) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.grokBaseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${ApiConstants.grokKey}'},
      body: json.encode({'model': 'grok-2-public', 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.1}),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Grok ${res.statusCode}');
    return _parseAiResponse(res.body);
  }

  Future<List<MatchModel>> _callGemini(String prompt, String key) async {
    final res = await _client.post(
      Uri.parse('${ApiConstants.geminiBaseUrl}?key=$key'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Gemini ${res.statusCode}');
    final data = json.decode(res.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '[]';
    return _parseRawJsonList(text);
  }

  Future<List<MatchModel>> _callKimi(String prompt) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.kimiBaseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${ApiConstants.kimiKey}'},
      body: json.encode({'model': 'moonshot-v1-8k', 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.1}),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Kimi ${res.statusCode}');
    return _parseAiResponse(res.body);
  }

  Future<List<MatchModel>> _callMistral(String prompt) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.mistralBaseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${ApiConstants.mistralKey}'},
      body: json.encode({'model': 'mistral-large-latest', 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.1}),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Mistral ${res.statusCode}');
    return _parseAiResponse(res.body);
  }

  Future<List<MatchModel>> _callDeepSeek(String prompt) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.deepseekBaseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${ApiConstants.deepseekKey}'},
      body: json.encode({'model': 'deepseek-chat', 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.1}),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('DeepSeek ${res.statusCode}');
    return _parseAiResponse(res.body);
  }

  Future<List<MatchModel>> _callZai(String prompt) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.zaiBaseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${ApiConstants.zaiKey}'},
      body: json.encode({'model': 'glm-4', 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.1}),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Z.ai ${res.statusCode}');
    return _parseAiResponse(res.body);
  }

  // ─── SCORES CALLS ─────────────────────────────────────────────────────────

  Future<List<MatchModel>> _callScoresPerplexity(String prompt, List<MatchModel> orig) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.perplexityBaseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${ApiConstants.perplexityKey}'},
      body: json.encode({'model': 'sonar', 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.1}),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Perplexity scores ${res.statusCode}');
    final data = json.decode(res.body);
    final content = data['choices']?[0]?['message']?['content'] ?? '[]';
    return _updateMatchesWithAiScores(orig, content);
  }

  Future<List<MatchModel>> _callScoresGrok(String prompt, List<MatchModel> orig) async {
    final res = await _client.post(
      Uri.parse(ApiConstants.grokBaseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${ApiConstants.grokKey}'},
      body: json.encode({'model': 'grok-2-public', 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.1}),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Grok scores ${res.statusCode}');
    final data = json.decode(res.body);
    final content = data['choices']?[0]?['message']?['content'] ?? '[]';
    return _updateMatchesWithAiScores(orig, content);
  }

  Future<List<MatchModel>> _callScoresGemini(String prompt, List<MatchModel> orig, String key) async {
    final res = await _client.post(
      Uri.parse('${ApiConstants.geminiBaseUrl}?key=$key'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Gemini scores ${res.statusCode}');
    final data = json.decode(res.body);
    final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '[]';
    return _updateMatchesWithAiScores(orig, content);
  }

  // ─── PROMPT ───────────────────────────────────────────────────────────────

  String _buildSearchPrompt(String dateStr) {
    return '''
Recherche sur le web (Flashscore, Sofascore, BetPawa, 1XBet) les vrais matchs de football réels en direct ET programmés pour aujourd'hui et les 72 prochaines heures (à partir du $dateStr).
Inclus absolument les matchs SCHEDULED (à venir) dans les 72h, pas seulement les matchs live.
IMPORTANT : Ne te concentre pas uniquement sur la Coupe du Monde ou les compétitions internationales. Cible activement les ligues et championnats domestiques en cours (Ligue des Champions, Premier League, La Liga, Ligue 1, Serie A, Bundesliga, CAF Champions League, CHAN, Ligue 1 Congolaise (RDC), Copa Libertadores, MLS, etc.).
Retourne les 20 matchs réels les plus intéressants pour les parieurs à cette date ($dateStr) (inclure des matchs futurs dans les 72h obligatoirement).

Tu DOIS retourner un tableau JSON brut (sans balises markdown, sans texte explicatif) :
[
  {
    "id": "ai-match-1",
    "homeTeam": {"id": "team-home-1", "name": "Nom Equipe Domicile", "logo": ""},
    "awayTeam": {"id": "team-away-1", "name": "Nom Equipe Exterieur", "logo": ""},
    "league": {"id": "league-1", "name": "Nom du Championnat", "logo": "", "country": "Pays"},
    "dateTime": "2026-07-12T20:00:00Z",
    "status": "scheduled",
    "homeScore": null,
    "awayScore": null,
    "timeElapsed": null,
    "round": "Matchday X"
  }
]
''';
  }

  // ─── PARSING ──────────────────────────────────────────────────────────────

  List<MatchModel> _parseAiResponse(String responseBody) {
    final data = json.decode(responseBody);
    final String content = data['choices']?[0]?['message']?['content'] ?? '[]';
    return _parseRawJsonList(content);
  }

  List<MatchModel> _parseRawJsonList(String rawJson) {
    var clean = rawJson.trim();
    if (clean.startsWith('```json')) clean = clean.substring(7);
    if (clean.startsWith('```')) clean = clean.substring(3);
    if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
    clean = clean.trim();

    final List<dynamic> list = json.decode(clean);
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      final homeName = map['homeTeam']?['name'] ?? 'Équipe A';
      final awayName = map['awayTeam']?['name'] ?? 'Équipe B';
      if ((map['homeTeam']?['logo'] ?? '').toString().isEmpty) {
        map['homeTeam']['logo'] = 'https://api.dicebear.com/7.x/identicon/png?seed=${Uri.encodeComponent(homeName)}';
      }
      if ((map['awayTeam']?['logo'] ?? '').toString().isEmpty) {
        map['awayTeam']['logo'] = 'https://api.dicebear.com/7.x/identicon/png?seed=${Uri.encodeComponent(awayName)}';
      }
      if ((map['league']?['logo'] ?? '').toString().isEmpty) {
        map['league']['logo'] = 'https://api.dicebear.com/7.x/initials/png?seed=${Uri.encodeComponent(map['league']?['name'] ?? 'L')}';
      }
      return MatchModel.fromJson(map);
    }).toList();
  }

  List<MatchModel> _updateMatchesWithAiScores(List<MatchModel> originals, String jsonScores) {
    try {
      var clean = jsonScores.trim();
      if (clean.startsWith('```json')) clean = clean.substring(7);
      if (clean.startsWith('```')) clean = clean.substring(3);
      if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
      clean = clean.trim();

      final List<dynamic> updatesList = json.decode(clean);
      final Map<String, dynamic> updatesMap = {for (var it in updatesList) it['id'].toString(): it};

      return originals.map((match) {
        final update = updatesMap[match.id];
        if (update == null) return match;

        final statusStr = (update['status'] ?? '').toString().toLowerCase();
        MatchStatus status;
        if (statusStr.contains('live') || statusStr.contains('in_play') || statusStr.contains('1h') || statusStr.contains('2h') || statusStr.contains('ht')) {
          status = MatchStatus.live;
        } else if (statusStr.contains('ft') || statusStr.contains('finished') || statusStr.contains('ended')) {
          status = MatchStatus.finished;
        } else {
          status = match.status;
        }

        return MatchModel(
          id: match.id,
          homeTeam: match.homeTeam,
          awayTeam: match.awayTeam,
          league: match.league,
          dateTime: match.dateTime,
          status: status,
          homeScore: update['homeScore'] != null ? int.tryParse(update['homeScore'].toString()) : match.homeScore,
          awayScore: update['awayScore'] != null ? int.tryParse(update['awayScore'].toString()) : match.awayScore,
          timeElapsed: update['timeElapsed']?.toString() ?? match.timeElapsed,
          round: match.round,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Parse erreur scores IA: $e');
      return originals;
    }
  }
}

/// Classe interne utilitaire pour la cascade d'IAs
class _AiSource {
  final String name;
  final Future<dynamic> Function() fetch;
  _AiSource(this.name, this.fetch);
}
