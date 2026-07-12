import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/match_model.dart';

class TheSportsDbService {
  final http.Client _client = http.Client();

  Future<List<MatchModel>> getNextEvents(String leagueId) async {
    try {
      final url = Uri.parse('${ApiConstants.theSportsDbV1Url}/${ApiConstants.theSportsDbKey}/eventsnextleague.php?id=$leagueId');
      final response = await _client.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseEvents(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('TheSportsDbService getNextEvents error: $e');
      return [];
    }
  }

  Future<List<MatchModel>> getMatchesByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().substring(0, 10);
      final url = Uri.parse('${ApiConstants.theSportsDbV1Url}/${ApiConstants.theSportsDbKey}/eventsday.php?d=$dateStr');
      final response = await _client.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseEvents(response.body, forceDate: date);
      }
      return [];
    } catch (e) {
      debugPrint('TheSportsDbService getMatchesByDate error: $e');
      return [];
    }
  }

  List<MatchModel> _parseEvents(String responseBody, {DateTime? forceDate}) {
    final data = json.decode(responseBody) as Map<String, dynamic>;
    final events = data['events'] as List<dynamic>? ?? [];

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
        dateTime: DateTime.tryParse('${event['dateEvent']} ${event['strTime']}') ?? forceDate ?? DateTime.now(),
        status: MatchStatus.scheduled,
        round: event['intRound']?.toString(),
      );
    }).where((m) => m.homeTeam.name.isNotEmpty && m.awayTeam.name.isNotEmpty).toList();
  }

  Future<String?> getTeamBadge(String teamName) async {
    try {
      final url = Uri.parse('${ApiConstants.theSportsDbV1Url}/${ApiConstants.theSportsDbKey}/searchteams.php?t=$teamName');
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final teams = data['teams'] as List<dynamic>? ?? [];
        if (teams.isNotEmpty) {
          return teams.first['strBadge']?.toString();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
