import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/match_model.dart';
import '../services/football_aggregator.dart';

class MatchProvider extends ChangeNotifier {
  final FootballAggregator _aggregator = FootballAggregator();

  List<MatchModel> _matches = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<MatchModel> get matches => _matches;
  bool get isLoading => _isLoading;

  List<MatchModel> get liveMatches =>
      _matches.where((m) => m.status == MatchStatus.live).toList();

  List<MatchModel> get scheduledMatches =>
      _matches.where((m) => m.status == MatchStatus.scheduled).toList();

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

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
