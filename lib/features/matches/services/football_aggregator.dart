import 'package:flutter/foundation.dart';
import '../../../shared/models/match_model.dart';
import 'api_football_service.dart';
import 'thesportsdb_service.dart';
import 'football_data_service.dart';
import 'ai_football_fallback_service.dart';

/// Agrège les matchs de football de toutes les sources disponibles.
/// Priorité : IA web search (matchs réels) → APIs officielles → Mockup statique
class FootballAggregator {
  final ApiFootballService _apiFootball = ApiFootballService();
  final FootballDataService _footballData = FootballDataService();
  final AiFootballFallbackService _aiFallback = AiFootballFallbackService();

  Future<List<MatchModel>> getTodayMatches() async {
    List<MatchModel> aggregated = [];

    // ── 1. PRIORITÉ : IA Web Search (Perplexity/Grok/Gemini) ──
    // Les IAs recherchent les vrais matchs sur internet (72h, toutes compétitions)
    try {
      debugPrint('🤖 Recherche de matchs via IA Web Search...');
      final aiMatches = await _aiFallback.fetchMatchesFromAI();
      if (aiMatches.isNotEmpty) {
        debugPrint('✅ IA a trouvé ${aiMatches.length} matchs');
        aggregated.addAll(aiMatches);
      }
    } catch (e) {
      debugPrint('⚠️ IA fallback failed: $e');
    }

    // ── 2. APIs officielle (complément ou premier résultat si IA a échoué) ──
    try {
      final apiMatches = await _apiFootball.getMatches();
      if (apiMatches.isNotEmpty) {
        debugPrint('✅ API Football: ${apiMatches.length} matchs');
        aggregated.addAll(apiMatches);
      }
    } catch (e) {
      debugPrint('API Football failed: $e');
    }

    if (aggregated.isEmpty) {
      try {
        final fdMatches = await _footballData.getMatches();
        if (fdMatches.isNotEmpty) {
          debugPrint('✅ Football-Data: ${fdMatches.length} matchs');
          aggregated.addAll(fdMatches);
        }
      } catch (e) {
        debugPrint('Football Data failed: $e');
      }
    }

    // ── 3. Fallback statique (si tout échoue) ──
    if (aggregated.isEmpty) {
      debugPrint('📋 Utilisation du mockup statique (pas de connexion)');
      aggregated = _getMockMatches();
    }

    // ── Déduplication par paires d'équipes ──
    final Map<String, MatchModel> unique = {};
    for (final match in aggregated) {
      final key = '${match.homeTeam.name.toLowerCase()}_vs_${match.awayTeam.name.toLowerCase()}';
      if (!unique.containsKey(key)) {
        unique[key] = match;
      }
    }

    final result = unique.values.toList();
    result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    debugPrint('📊 Total matchs agrégés (dédupliqués): ${result.length}');
    return result;
  }

  List<MatchModel> _getMockMatches() {
    final now = DateTime.now();
    return [
      MatchModel(
        id: 'mock-1',
        homeTeam: const Team(id: 't-real', name: 'Real Madrid', logoUrl: 'https://media.api-sports.io/football/teams/541.png'),
        awayTeam: const Team(id: 't-barca', name: 'FC Barcelona', logoUrl: 'https://media.api-sports.io/football/teams/529.png'),
        league: const League(id: 'l-laliga', name: 'La Liga', logoUrl: 'https://media.api-sports.io/football/leagues/140.png', country: 'Spain'),
        dateTime: now.subtract(const Duration(minutes: 75)),
        status: MatchStatus.live,
        homeScore: 2, awayScore: 1, timeElapsed: '75\'', round: 'Matchday 32',
      ),
      MatchModel(
        id: 'mock-2',
        homeTeam: const Team(id: 't-psg', name: 'Paris Saint Germain', logoUrl: 'https://media.api-sports.io/football/teams/85.png'),
        awayTeam: const Team(id: 't-om', name: 'Marseille', logoUrl: 'https://media.api-sports.io/football/teams/81.png'),
        league: const League(id: 'l-ligue1', name: 'Ligue 1', logoUrl: 'https://media.api-sports.io/football/leagues/61.png', country: 'France'),
        dateTime: now.add(const Duration(hours: 2)),
        status: MatchStatus.scheduled, round: 'Matchday 28',
      ),
      MatchModel(
        id: 'mock-3',
        homeTeam: const Team(id: 't-mancity', name: 'Manchester City', logoUrl: 'https://media.api-sports.io/football/teams/50.png'),
        awayTeam: const Team(id: 't-liverpool', name: 'Liverpool', logoUrl: 'https://media.api-sports.io/football/teams/40.png'),
        league: const League(id: 'l-pl', name: 'Premier League', logoUrl: 'https://media.api-sports.io/football/leagues/39.png', country: 'England'),
        dateTime: now.add(const Duration(hours: 4)),
        status: MatchStatus.scheduled, round: 'Matchday 30',
      ),
      MatchModel(
        id: 'mock-4',
        homeTeam: const Team(id: 't-bayern', name: 'Bayern Munich', logoUrl: 'https://media.api-sports.io/football/teams/157.png'),
        awayTeam: const Team(id: 't-dortmund', name: 'Borussia Dortmund', logoUrl: 'https://media.api-sports.io/football/teams/165.png'),
        league: const League(id: 'l-bundes', name: 'Bundesliga', logoUrl: 'https://media.api-sports.io/football/leagues/78.png', country: 'Germany'),
        dateTime: now.add(const Duration(hours: 24)),
        status: MatchStatus.scheduled, round: 'Matchday 27',
      ),
      MatchModel(
        id: 'mock-5',
        homeTeam: const Team(id: 't-inter', name: 'Inter Milan', logoUrl: 'https://media.api-sports.io/football/teams/505.png'),
        awayTeam: const Team(id: 't-ac', name: 'AC Milan', logoUrl: 'https://media.api-sports.io/football/teams/489.png'),
        league: const League(id: 'l-seriea', name: 'Serie A', logoUrl: 'https://media.api-sports.io/football/leagues/135.png', country: 'Italy'),
        dateTime: now.add(const Duration(hours: 48)),
        status: MatchStatus.scheduled, round: 'Matchday 31',
      ),
      MatchModel(
        id: 'mock-6',
        homeTeam: const Team(id: 't-arsenal', name: 'Arsenal', logoUrl: 'https://media.api-sports.io/football/teams/42.png'),
        awayTeam: const Team(id: 't-chelsea', name: 'Chelsea', logoUrl: 'https://media.api-sports.io/football/teams/49.png'),
        league: const League(id: 'l-pl2', name: 'Premier League', logoUrl: 'https://media.api-sports.io/football/leagues/39.png', country: 'England'),
        dateTime: now.add(const Duration(hours: 60)),
        status: MatchStatus.scheduled, round: 'Matchday 33',
      ),
    ];
  }
}
