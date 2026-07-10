import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';

class FootballDataService {
  final http.Client _client = http.Client();

  Future<List<MatchModel>> getMatches() async {
    try {
      final url = Uri.parse('${ApiConstants.footballDataBaseUrl}/matches');
      final response = await _client.get(
        url,
        headers: {
          'X-Auth-Token': ApiConstants.footballDataToken,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> matches = data['matches'] ?? [];

        return matches.map((match) {
          final competition = match['competition'] ?? {};
          final homeTeam = match['homeTeam'] ?? {};
          final awayTeam = match['awayTeam'] ?? {};
          final score = match['score'] ?? {};
          final fullTime = score['fullTime'] ?? {};

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
            dateTime: DateTime.parse(match['utcDate'] ?? DateTime.now().toIso8601String()),
            status: _parseStatus(match['status']),
            homeScore: fullTime['home'],
            awayScore: fullTime['away'],
            round: match['matchday']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('FootballDataService Error: $e');
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
