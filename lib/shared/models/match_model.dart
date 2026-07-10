import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final String logoUrl;

  const Team({
    required this.id,
    required this.name,
    required this.logoUrl,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logo'] ?? json['logoUrl'] ?? 'https://media.api-sports.io/football/teams/placeholder.png',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logoUrl': logoUrl,
      };

  @override
  List<Object?> get props => [id, name, logoUrl];
}

class League extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final String country;

  const League({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.country,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logo'] ?? json['logoUrl'] ?? 'https://media.api-sports.io/football/leagues/placeholder.png',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logoUrl': logoUrl,
        'country': country,
      };

  @override
  List<Object?> get props => [id, name, logoUrl, country];
}

enum MatchStatus { live, scheduled, finished }

class MatchModel extends Equatable {
  final String id;
  final Team homeTeam;
  final Team awayTeam;
  final League league;
  final DateTime dateTime;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final String? timeElapsed; // For live games (e.g. "75'")
  final String? round; // e.g. "Regular Season - 12"

  const MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.league,
    required this.dateTime,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.timeElapsed,
    this.round,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    String statusStr = (json['status'] ?? json['matchStatus'] ?? 'scheduled').toString().toLowerCase();
    MatchStatus parsedStatus;
    if (statusStr.contains('live') || statusStr.contains('in_play') || statusStr.contains('1h') || statusStr.contains('2h') || statusStr.contains('ht')) {
      parsedStatus = MatchStatus.live;
    } else if (statusStr.contains('ft') || statusStr.contains('finished') || statusStr.contains('ended')) {
      parsedStatus = MatchStatus.finished;
    } else {
      parsedStatus = MatchStatus.scheduled;
    }

    return MatchModel(
      id: json['id']?.toString() ?? '',
      homeTeam: Team.fromJson(json['homeTeam'] ?? json['home'] ?? {}),
      awayTeam: Team.fromJson(json['awayTeam'] ?? json['away'] ?? {}),
      league: League.fromJson(json['league'] ?? {}),
      dateTime: DateTime.parse(json['dateTime'] ?? json['date'] ?? DateTime.now().toIso8601String()),
      status: parsedStatus,
      homeScore: json['homeScore'] != null ? int.tryParse(json['homeScore'].toString()) : null,
      awayScore: json['awayScore'] != null ? int.tryParse(json['awayScore'].toString()) : null,
      timeElapsed: json['timeElapsed']?.toString(),
      round: json['round']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'homeTeam': homeTeam.toJson(),
        'awayTeam': awayTeam.toJson(),
        'league': league.toJson(),
        'dateTime': dateTime.toIso8601String(),
        'status': status.name,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'timeElapsed': timeElapsed,
        'round': round,
      };

  @override
  List<Object?> get props => [
        id,
        homeTeam,
        awayTeam,
        league,
        dateTime,
        status,
        homeScore,
        awayScore,
        timeElapsed,
        round,
      ];
}
