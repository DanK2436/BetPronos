import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/match_model.dart';
import '../services/football_aggregator.dart';

class MatchProvider extends ChangeNotifier {
  final FootballAggregator _aggregator = FootballAggregator();

  List<MatchModel> _matches = [];
  bool _isLoading = false;

  List<MatchModel> get matches => _matches;
  bool get isLoading => _isLoading;

  /// Matchs en cours (live)
  List<MatchModel> get liveMatches =>
      _matches.where((m) => m.status == MatchStatus.live).toList();

  /// Matchs programmés dans les 48 prochaines heures
  List<MatchModel> get upcoming48hMatches {
    final now = DateTime.now();
    final limit = now.add(const Duration(hours: 48));
    final result = _matches
        .where((m) =>
            m.status == MatchStatus.scheduled &&
            m.dateTime.isAfter(now) &&
            m.dateTime.isBefore(limit))
        .toList();
    result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return result;
  }

  /// Tous les matchs programmés (non filtrés par 48h)
  List<MatchModel> get scheduledMatches {
    final result = _matches
        .where((m) => m.status == MatchStatus.scheduled)
        .toList();
    result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return result;
  }

  List<MatchModel> get finishedMatches =>
      _matches.where((m) => m.status == MatchStatus.finished).toList();

  Future<void> fetchMatches() async {
    _isLoading = true;
    notifyListeners();
    try {
      _matches = await _aggregator.getTodayMatches();
    } catch (e) {
      debugPrint('Fetch matches error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
