import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';

class TheSportsDbService {
  final http.Client _client = http.Client();

  Future<List<MatchModel>> getNextEvents(String leagueId) async {
    try {
      final url = Uri.parse('${ApiConstants.theSportsDbV1Url}/${ApiConstants.theSportsDbKey}/eventsnextleague.php?id=$leagueId');
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> events = data['events'] ?? [];

        return events.map((event) {
          return MatchModel(
            id: 'thesportsdb-${event['idEvent']}',
            homeTeam: Team(
              id: event['idHomeTeam']?.toString() ?? '',
              name: event['strHomeTeam'] ?? '',
              logoUrl: 'https://www.thesportsdb.com/images/media/team/badge/small/${event['idHomeTeam']}.png',
            ),
            awayTeam: Team(
              id: event['idAwayTeam']?.toString() ?? '',
              name: event['strAwayTeam'] ?? '',
              logoUrl: 'https://www.thesportsdb.com/images/media/team/badge/small/${event['idAwayTeam']}.png',
            ),
            league: League(
              id: event['idLeague']?.toString() ?? '',
              name: event['strLeague'] ?? '',
              logoUrl: '',
              country: event['strCountry'] ?? '',
            ),
            dateTime: DateTime.tryParse('${event['dateEvent']} ${event['strTime']}') ?? DateTime.now(),
            status: MatchStatus.scheduled,
            round: event['intRound']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('TheSportsDbService Error: $e');
      return [];
    }
  }

  Future<String?> getTeamBadge(String teamName) async {
    try {
      final url = Uri.parse('${ApiConstants.theSportsDbV1Url}/${ApiConstants.theSportsDbKey}/searchteams.php?t=$teamName');
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> teams = data['teams'] ?? [];
        if (teams.isNotEmpty) {
          return teams.first['strBadge'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
