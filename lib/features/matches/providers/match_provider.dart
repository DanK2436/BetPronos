import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/match_model.dart';
import '../services/football_aggregator.dart';
import '../services/ai_football_fallback_service.dart';

class MatchProvider extends ChangeNotifier {
  final FootballAggregator _aggregator = FootballAggregator();
  final AiFootballFallbackService _aiFallback = AiFootballFallbackService();

  List<MatchModel> _matches = [];
  bool _isLoading = false;
  bool _isCheckingScores = false;

  List<MatchModel> get matches => _matches;
  bool get isLoading => _isLoading;
  bool get isCheckingScores => _isCheckingScores;

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
      // Lancer immédiatement la vérification des scores en temps réel par les IAs après le fetch
      if (_matches.isNotEmpty) {
        verifyLiveScores();
      }
    } catch (e) {
      debugPrint('Fetch matches error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifie et met à jour en arrière-plan les scores en direct à l'aide de l'IA (Perplexity / Grok / Gemini)
  Future<void> verifyLiveScores() async {
    if (_isCheckingScores) return;
    _isCheckingScores = true;
    notifyListeners();

    try {
      // Nous envoyons tous les matchs en direct et programmés proches à l'IA pour vérifier s'ils ont commencé ou ont changé
      final updatedMatches = await _aiFallback.verifyLiveScoresWithAI(_matches);
      _matches = updatedMatches;
    } catch (e) {
      debugPrint('Error verifying live scores with AI: $e');
    } finally {
      _isCheckingScores = false;
      notifyListeners();
    }
  }
}
