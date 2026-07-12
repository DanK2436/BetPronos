import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/coupon_model.dart';
import '../../predictions/services/prediction_orchestrator.dart';
import '../../predictions/models/prediction_model.dart';
import '../../../shared/models/match_model.dart';

class SmartCouponService {
  final PredictionOrchestrator _orchestrator = PredictionOrchestrator();

  Future<Coupon?> generateSmartCoupon(List<MatchModel> availableMatches) async {
    if (availableMatches.isEmpty) return null;

    // Shuffle and pick max 10 matches to avoid analyzing too many via AI (to save time/tokens)
    final random = Random();
    final matchesToAnalyze = availableMatches.toList()..shuffle(random);
    final selectedMatches = matchesToAnalyze.take(min(10, availableMatches.length)).toList();

    List<CouponSelection> bestSelections = [];

    for (final match in selectedMatches) {
      try {
        final consensus = await _orchestrator.getConsensus(match);
        
        // Only select matches where the AI has high confidence (e.g. > 70%)
        if (consensus.overallConfidence > 0.70) {
          final selection = _extractBestSelection(match, consensus);
          if (selection != null) {
            bestSelections.add(selection);
          }
        }
      } catch (e) {
        // Skip if prediction fails
        continue;
      }
    }

    if (bestSelections.isEmpty) return null;

    // Pick top 3-5 most confident selections for the final smart coupon
    bestSelections.sort((a, b) => b.odds.compareTo(a.odds)); // Or sort by confidence if available
    final finalSelections = bestSelections.take(min(5, bestSelections.length)).toList();

    return Coupon(
      id: const Uuid().v4(),
      selections: finalSelections,
      createdAt: DateTime.now(),
    );
  }

  CouponSelection? _extractBestSelection(MatchModel match, ConsensusPrediction consensus) {
    // Determine the safest bet
    final diff = (consensus.consensusHomeScore - consensus.consensusAwayScore).abs();
    
    BetType betType;
    String selectedValue;
    double odds = 1.80; // Mock default odds

    // Parse odds
    double parseOdds(String key, double defaultVal) {
      try {
        if (consensus.consensusBetting.estimatedOdds.contains(key)) {
          final parts = consensus.consensusBetting.estimatedOdds.split(key);
          if (parts.length > 1) {
            final val = parts[1].split('|').first.trim();
            return double.tryParse(val) ?? defaultVal;
          }
        }
      } catch (_) {}
      return defaultVal;
    }

    if (diff >= 2) {
      // Clear winner
      if (consensus.consensusHomeScore > consensus.consensusAwayScore) {
        betType = BetType.homeWin;
        selectedValue = '1';
        odds = parseOdds('1:', 1.50);
      } else {
        betType = BetType.awayWin;
        selectedValue = '2';
        odds = parseOdds('2:', 1.50);
      }
    } else if (consensus.consensusBetting.bttsFullTime == 'Oui') {
      // Both teams to score is a strong prediction
      betType = BetType.btts;
      selectedValue = 'Oui';
      odds = 1.75;
    } else {
      // Default to Over/Under 1.5
      betType = BetType.over15;
      selectedValue = 'Plus de 1.5';
      odds = 1.30;
    }

    return CouponSelection(
      matchId: match.id,
      homeTeamName: match.homeTeam.name,
      awayTeamName: match.awayTeam.name,
      leagueName: match.league.name,
      betType: betType,
      selectedValue: selectedValue,
      odds: odds,
      matchDateTime: match.dateTime,
    );
  }
}
