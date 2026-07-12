import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';

class FootballDataService {
  final http.Client _client = http.Client();

  Future<List<MatchModel>> getMatches() async {
    return getMatchesByDate(DateTime.now());
  }

  Future<List<MatchModel>> getMatchesByDate(DateTime date) async {
    try {
      final dateFrom = date.toIso8601String().substring(0, 10);
      final dateTo = dateFrom;
      final url = Uri.parse(
          '${ApiConstants.footballDataBaseUrl}/matches?dateFrom=$dateFrom&dateTo=$dateTo');

      final response = await _client.get(
        url,
        headers: {'X-Auth-Token': ApiConstants.footballDataToken},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final matches = data['matches'] as List<dynamic>? ?? [];

        return matches.map((match) {
          final competition = match['competition'] as Map<String, dynamic>? ?? {};
          final homeTeam = match['homeTeam'] as Map<String, dynamic>? ?? {};
          final awayTeam = match['awayTeam'] as Map<String, dynamic>? ?? {};
          final score = match['score'] as Map<String, dynamic>? ?? {};
          final fullTime = score['fullTime'] as Map<String, dynamic>? ?? {};

          return MatchModel(
            id: 'footballdata-${match['id']}',
            homeTeam: Team(
              id: homeTeam['id']?.toString() ?? '',
              name: homeTeam['name'] ?? '',
              logoUrl: homeTeam['crest'] ?? '',
            ),
            awayTeam: Team(
              id: awayTeam['id']?.toString() ?? '',
              name: awayTeam['name'] ?? '',
              logoUrl: awayTeam['crest'] ?? '',
            ),
            league: League(
              id: competition['id']?.toString() ?? '',
              name: competition['name'] ?? '',
              logoUrl: competition['emblem'] ?? '',
              country: '',
            ),
            dateTime: DateTime.tryParse(match['utcDate']?.toString() ?? '') ?? date,
            status: _parseStatus(match['status']?.toString()),
            homeScore: fullTime['home'] != null ? int.tryParse(fullTime['home'].toString()) : null,
            awayScore: fullTime['away'] != null ? int.tryParse(fullTime['away'].toString()) : null,
            round: match['matchday']?.toString(),
          );
        }).where((m) => m.homeTeam.name.isNotEmpty && m.awayTeam.name.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      debugPrint('FootballDataService error: $e');
      return [];
    }
  }

  MatchStatus _parseStatus(String? status) {
    if (status == null) return MatchStatus.scheduled;
    switch (status.toUpperCase()) {
      case 'LIVE':
      case 'IN_PLAY':
      case 'PAUSED':
        return MatchStatus.live;
      case 'FINISHED':
      case 'AWARDED':
        return MatchStatus.finished;
      default:
        return MatchStatus.scheduled;
    }
  }
}
