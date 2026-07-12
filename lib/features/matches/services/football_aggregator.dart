import 'package:flutter/foundation.dart';
import '../../../shared/models/match_model.dart';
import 'api_football_service.dart';
import 'thesportsdb_service.dart';
import 'football_data_service.dart';
import 'ai_football_fallback_service.dart';
import 'match_cache_service.dart';

/// Agrège les matchs de football de toutes les sources disponibles.
/// Priorité : Cache local → APIs officielles → Fallback IA
/// Les faux matchs mockés ont été supprimés.
class FootballAggregator {
  final ApiFootballService _apiFootball = ApiFootballService();
  final TheSportsDbService _sportsDb = TheSportsDbService();
  final FootballDataService _footballData = FootballDataService();
  final AiFootballFallbackService _aiFallback = AiFootballFallbackService();
  final MatchCacheService _cache = MatchCacheService();

  /// Récupère les matchs pour hier, aujourd'hui et demain.
  Future<List<MatchModel>> getTodayMatches() async {
    final now = DateTime.now();
    final dates = [
      now.subtract(const Duration(days: 1)), // Hier
      now,                                   // Aujourd'hui
      now.add(const Duration(days: 1)),      // Demain
    ];

    // Nettoyage automatique du vieux cache
    await _cache.cleanOldCache();

    List<MatchModel> allMatches = [];

    for (final date in dates) {
      final dayMatches = await _getMatchesForDate(date);
      allMatches.addAll(dayMatches);
    }

    // Déduplication par ID ou par paire d'équipes
    final Map<String, MatchModel> unique = {};
    for (final match in allMatches) {
      final key = match.id.isNotEmpty
          ? match.id
          : '${match.homeTeam.name.toLowerCase()}_vs_${match.awayTeam.name.toLowerCase()}_${match.dateTime.day}';
      if (!unique.containsKey(key)) {
        unique[key] = match;
      }
    }

    final result = unique.values.toList();
    result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    debugPrint('FootballAggregator: ${result.length} matchs au total (hier/aujourd\'hui/demain)');
    return result;
  }

  /// Récupère les matchs en direct uniquement (pour le polling temps réel)
  Future<List<MatchModel>> getLiveMatches() async {
    try {
      final liveMatches = await _apiFootball.getMatches(liveOnly: true);
      if (liveMatches.isNotEmpty) return liveMatches;
    } catch (e) {
      debugPrint('getLiveMatches apiFootball error: $e');
    }
    return [];
  }

  /// Récupère les matchs pour une date spécifique avec cache
  Future<List<MatchModel>> _getMatchesForDate(DateTime date) async {
    // 1. Vérifier le cache d'abord
    if (_cache.isCacheValid(date)) {
      final cached = await _cache.getCachedMatches(date);
      if (cached.isNotEmpty) {
        debugPrint('Cache hit pour ${date.toIso8601String().substring(0, 10)}: ${cached.length} matchs');
        return cached;
      }
    }

    List<MatchModel> matches = [];

    // 2. API Football (RapidAPI) — Priorité 1
    try {
      final apiMatches = await _apiFootball.getMatchesByDate(date);
      if (apiMatches.isNotEmpty) {
        debugPrint('API Football: ${apiMatches.length} matchs pour ${date.toIso8601String().substring(0, 10)}');
        matches.addAll(apiMatches);
      }
    } catch (e) {
      debugPrint('API Football error for date: $e');
    }

    // 3. Football-Data.org — Priorité 2 (si API Football vide)
    if (matches.isEmpty) {
      try {
        final fdMatches = await _footballData.getMatchesByDate(date);
        if (fdMatches.isNotEmpty) {
          debugPrint('Football-Data: ${fdMatches.length} matchs');
          matches.addAll(fdMatches);
        }
      } catch (e) {
        debugPrint('Football-Data error: $e');
      }
    }

    // 4. TheSportsDB — Priorité 3
    if (matches.isEmpty) {
      try {
        final sdbMatches = await _sportsDb.getMatchesByDate(date);
        if (sdbMatches.isNotEmpty) {
          debugPrint('TheSportsDB: ${sdbMatches.length} matchs');
          matches.addAll(sdbMatches);
        }
      } catch (e) {
        debugPrint('TheSportsDB error: $e');
      }
    }

    // 5. Fallback IA (Perplexity/Kimi) — Uniquement si toutes les APIs échouent
    if (matches.isEmpty) {
      try {
        debugPrint('Fallback IA pour ${date.toIso8601String().substring(0, 10)}...');
        final aiMatches = await _aiFallback.fetchMatchesForDate(date);
        if (aiMatches.isNotEmpty) {
          debugPrint('IA Fallback: ${aiMatches.length} matchs trouvés');
          matches.addAll(aiMatches);
        }
      } catch (e) {
        debugPrint('IA Fallback error: $e');
      }
    }

    // Mettre en cache si on a des résultats
    if (matches.isNotEmpty) {
      await _cache.cacheMatches(date, matches);
    }

    return matches;
  }
}
