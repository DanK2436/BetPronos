import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';
import '../services/prediction_orchestrator.dart';

class PredictionProvider extends ChangeNotifier {
  final PredictionOrchestrator _orchestrator = PredictionOrchestrator();

  final Map<String, ConsensusPrediction> _cache = {};
  final Map<String, bool> _loadingStates = {};

  bool isMatchLoading(String matchId) => _loadingStates[matchId] ?? false;

  ConsensusPrediction? getPrediction(String matchId) => _cache[matchId];

  Future<ConsensusPrediction?> calculatePrediction(MatchModel match) async {
    if (_cache.containsKey(match.id)) {
      return _cache[match.id];
    }

    _loadingStates[match.id] = true;
    notifyListeners();

    try {
      final prediction = await _orchestrator.getConsensus(match);
      _cache[match.id] = prediction;
      return prediction;
    } catch (e) {
      debugPrint('Prediction calculation failed: $e');
      return null;
    } finally {
      _loadingStates[match.id] = false;
      notifyListeners();
    }
  }
}
