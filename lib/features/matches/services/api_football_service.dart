import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';

class ApiFootballService {
  final http.Client _client = http.Client();

  Future<List<MatchModel>> getMatches({bool liveOnly = false}) async {
    try {
      final queryParameters = {
        'wixfutures': 'live',
      };
      
      if (liveOnly) {
        queryParameters['live'] = 'all';
      } else {
        // Fetch matches for today
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        queryParameters['date'] = todayStr;
      }

      final uri = Uri.parse('${ApiConstants.apiFootballBaseUrl}/fixtures')
          .replace(queryParameters: queryParameters);

      final response = await _client.get(
        uri,
        headers: {
          'x-rapidapi-key': ApiConstants.apiFootballKey,
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> responseList = data['response'] ?? [];
        
        return responseList.map((item) {
          final fixture = item['fixture'] ?? {};
          final league = item['league'] ?? {};
          final teams = item['teams'] ?? {};
          final goals = item['goals'] ?? {};
          
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
            dateTime: DateTime.parse(fixture['date'] ?? DateTime.now().toIso8601String()),
            status: _parseStatus(fixture['status']?['short']),
            homeScore: goals['home'],
            awayScore: goals['away'],
            timeElapsed: fixture['status']?['elapsed']?.toString(),
            round: league['round']?.toString(),
          );
        }).toList();
      } else {
        throw Exception('Failed to load api-football fixtures: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiFootballService Error: $e');
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
