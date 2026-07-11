import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../shared/models/match_model.dart';
import '../services/football_aggregator.dart';
import '../services/ai_football_fallback_service.dart';

class MatchProvider extends ChangeNotifier {
  final FootballAggregator _aggregator = FootballAggregator();
  final AiFootballFallbackService _aiFallback = AiFootballFallbackService();

  List<MatchModel> _matches = [];
  bool _isLoading = false;
  bool _isCheckingScores = false;
  Timer? _scoreRefreshTimer;

  List<MatchModel> get matches => _matches;
  bool get isLoading => _isLoading;
  bool get isCheckingScores => _isCheckingScores;

  /// Matchs en cours (live)
  List<MatchModel> get liveMatches =>
      _matches.where((m) => m.status == MatchStatus.live).toList();

  /// Matchs programmés dans les 72 prochaines heures
  List<MatchModel> get upcoming72hMatches {
    final now = DateTime.now();
    final limit = now.add(const Duration(hours: 72));
    final result = _matches
        .where((m) =>
            m.status == MatchStatus.scheduled &&
            m.dateTime.isAfter(now) &&
            m.dateTime.isBefore(limit))
        .toList();
    result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return result;
  }

  /// Alias conservé pour compatibilité
  List<MatchModel> get upcoming48hMatches => upcoming72hMatches;

  /// Tous les matchs programmés (non filtrés)
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

    // Lancer la vérification des scores en temps réel après le chargement initial
    _startScoreRefresh();
  }

  /// Démarre un timer de rafraîchissement des scores toutes les 2 minutes
  void _startScoreRefresh() {
    _scoreRefreshTimer?.cancel();
    // Premier check immédiat
    verifyLiveScores();
    // Puis toutes les 2 minutes
    _scoreRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      verifyLiveScores();
    });
  }

  /// Vérifie et met à jour les scores en direct grâce aux IAs (Perplexity / Grok / Gemini)
  Future<void> verifyLiveScores() async {
    if (_isCheckingScores || _matches.isEmpty) return;
    _isCheckingScores = true;
    notifyListeners();

    try {
      final updatedMatches = await _aiFallback.verifyLiveScoresWithAI(_matches);
      _matches = updatedMatches;
    } catch (e) {
      debugPrint('Error verifying live scores with AI: $e');
    } finally {
      _isCheckingScores = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _scoreRefreshTimer?.cancel();
    super.dispose();
  }
}
