import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';

class ApiFootballService {
  final http.Client _client = http.Client();

  /// Récupère les matchs en direct
  Future<List<MatchModel>> getMatches({bool liveOnly = false}) async {
    if (liveOnly) {
      return _fetchFixtures({'live': 'all'});
    }
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    return _fetchFixtures({'date': todayStr});
  }

  /// Récupère les matchs pour une date spécifique
  Future<List<MatchModel>> getMatchesByDate(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    return _fetchFixtures({'date': dateStr});
  }

  Future<List<MatchModel>> _fetchFixtures(Map<String, String> params) async {
    try {
      final uri = Uri.parse('${ApiConstants.apiFootballBaseUrl}/fixtures')
          .replace(queryParameters: params);

      final response = await _client.get(
        uri,
        headers: {
          'x-rapidapi-key': ApiConstants.apiFootballKey,
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final responseList = data['response'] as List<dynamic>? ?? [];

        return responseList.map((item) {
          final fixture = item['fixture'] as Map<String, dynamic>? ?? {};
          final league = item['league'] as Map<String, dynamic>? ?? {};
          final teams = item['teams'] as Map<String, dynamic>? ?? {};
          final goals = item['goals'] as Map<String, dynamic>? ?? {};

          return MatchModel(
            id: 'apifootball-${fixture['id']}',
            homeTeam: Team(
              id: teams['home']?['id']?.toString() ?? '',
              name: teams['home']?['name'] ?? '',
              logoUrl: teams['home']?['logo'] ?? '',
            ),
            awayTeam: Team(
              id: teams['away']?['id']?.toString() ?? '',
              name: teams['away']?['name'] ?? '',
              logoUrl: teams['away']?['logo'] ?? '',
            ),
            league: League(
              id: league['id']?.toString() ?? '',
              name: league['name'] ?? '',
              logoUrl: league['logo'] ?? '',
              country: league['country'] ?? '',
            ),
            dateTime: DateTime.tryParse(fixture['date']?.toString() ?? '') ?? DateTime.now(),
            status: _parseStatus(fixture['status']?['short']?.toString()),
            homeScore: goals['home'] != null ? int.tryParse(goals['home'].toString()) : null,
            awayScore: goals['away'] != null ? int.tryParse(goals['away'].toString()) : null,
            timeElapsed: fixture['status']?['elapsed']?.toString(),
            round: league['round']?.toString(),
          );
        }).where((m) => m.homeTeam.name.isNotEmpty && m.awayTeam.name.isNotEmpty).toList();
      } else {
        debugPrint('ApiFootball HTTP ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('ApiFootballService error: $e');
      return [];
    }
  }

  MatchStatus _parseStatus(String? short) {
    if (short == null) return MatchStatus.scheduled;
    switch (short) {
      case 'LIVE':
      case '1H':
      case '2H':
      case 'HT':
      case 'ET':
      case 'P':
        return MatchStatus.live;
      case 'FT':
      case 'AET':
      case 'PEN':
        return MatchStatus.finished;
      default:
        return MatchStatus.scheduled;
    }
  }
}
