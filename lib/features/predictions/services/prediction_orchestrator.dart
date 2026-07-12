import 'package:flutter/foundation.dart';
import '../agents/base_agent.dart';
import '../agents/gemini_agent.dart';
import '../agents/openai_agent.dart';
import '../agents/mistral_agent.dart';
import '../agents/deepseek_agent.dart';
import '../agents/kimi_agent.dart';
import '../agents/grok_agent.dart';
import '../agents/zai_agent.dart';
import '../models/prediction_model.dart';
import '../../../shared/models/match_model.dart';

/// Orchestre tous les agents IA en parallèle et calcule le consensus final avec options de paris sportifs.
class PredictionOrchestrator {
  final List<BaseAgent> _agents = [
    GeminiAgent(),
    OpenAiAgent(),
    MistralAgent(),
    DeepSeekAgent(),
    KimiAgent(),
    GrokAgent(),
    ZaiAgent(),
  ];

  Future<ConsensusPrediction> getConsensus(MatchModel match) async {
    debugPrint('🤖 Lancement de ${_agents.length} agents IA pour ${match.homeTeam.name} vs ${match.awayTeam.name}...');

    // Lancer tous les agents en parallèle
    final List<Future<AgentPrediction>> futures =
        _agents.map((agent) => agent.predict(match)).toList();

    final List<AgentPrediction> predictions = await Future.wait(futures);

    // Calculer le score exact moyen pondéré par la confiance
    double weightedHome = 0;
    double weightedAway = 0;
    double totalWeight = 0;

    // Compteurs pour les options de paris sportifs (vote majoritaire)
    int bttsFullTimeYes = 0;
    int bttsFirstHalfYes = 0;
    int bttsSecondHalfYes = 0;
    int over15Yes = 0;
    int over25Yes = 0;
    int pairYes = 0;
    String odds = '';

    for (final pred in predictions) {
      final w = pred.confidence;
      weightedHome += pred.predictedHomeScore * w;
      weightedAway += pred.predictedAwayScore * w;
      totalWeight += w;

      final opts = pred.bettingOptions;
      if (opts.bttsFullTime.toLowerCase() == 'oui') bttsFullTimeYes++;
      if (opts.bttsFirstHalf.toLowerCase() == 'oui') bttsFirstHalfYes++;
      if (opts.bttsSecondHalf.toLowerCase() == 'oui') bttsSecondHalfYes++;
      if (opts.overUnder15.toLowerCase().contains('plus')) over15Yes++;
      if (opts.overUnder25.toLowerCase().contains('plus')) over25Yes++;
      if (opts.oddEven.toLowerCase().contains('pair')) pairYes++;
      
      if (opts.estimatedOdds.isNotEmpty && odds.isEmpty) {
        odds = opts.estimatedOdds;
      }
    }

    final consensusHome = totalWeight > 0
        ? (weightedHome / totalWeight).round()
        : (predictions.map((p) => p.predictedHomeScore).reduce((a, b) => a + b) / predictions.length).round();
    final consensusAway = totalWeight > 0
        ? (weightedAway / totalWeight).round()
        : (predictions.map((p) => p.predictedAwayScore).reduce((a, b) => a + b) / predictions.length).round();
    final overallConfidence = totalWeight / predictions.length;

    // Détermination de la majorité pour les options de paris
    final halfLength = predictions.length / 2;
    final bttsFT = bttsFullTimeYes > halfLength ? 'Oui' : 'Non';
    final btts1H = bttsFirstHalfYes > halfLength ? 'Oui' : 'Non';
    final btts2H = bttsSecondHalfYes > halfLength ? 'Oui' : 'Non';
    final overUnder15 = over15Yes > halfLength ? 'Plus de 1.5' : 'Moins de 1.5';
    final overUnder25 = over25Yes > halfLength ? 'Plus de 2.5' : 'Moins de 2.5';
    final oddEven = pairYes > halfLength ? 'Pair' : 'Impair';
    
    if (odds.isEmpty) {
      odds = '1: 1.90 | X: 3.30 | 2: 3.80';
    }

    final consensusBetting = BettingOptions(
      bttsFullTime: bttsFT,
      bttsFirstHalf: btts1H,
      bttsSecondHalf: btts2H,
      overUnder15: overUnder15,
      overUnder25: overUnder25,
      oddEven: oddEven,
      estimatedOdds: odds,
    );

    // Résumé de l'analyse
    final pct = (overallConfidence * 100).toStringAsFixed(0);
    String summary;
    if (consensusHome > consensusAway) {
      summary = 'Consensus : Victoire de ${match.homeTeam.name} à domicile ($consensusHome–$consensusAway). Options recommandées : ${overUnder1.5 == "Plus de 1.5" ? "Plus de 1.5 buts" : "Moins de 1.5 buts"} et les deux équipes marquent : $bttsFT. Cotes : $odds.';
    } else if (consensusAway > consensusHome) {
      summary = 'Consensus : Victoire à l\'extérieur de ${match.awayTeam.name} ($consensusHome–$consensusAway). Options recommandées : $overUnder25 et les deux équipes marquent : $bttsFT. Cotes : $odds.';
    } else {
      summary = 'Consensus : Match nul à forte intensité ($consensusHome–$consensusAway). Recommandation : BTTS $bttsFT et total de buts $oddEven. Cotes : $odds.';
    }

    return ConsensusPrediction(
      matchId: match.id,
      agentPredictions: predictions,
      consensusHomeScore: consensusHome,
      consensusAwayScore: consensusAway,
      overallConfidence: overallConfidence,
      overallAnalysis: summary,
      consensusBetting: consensusBetting,
    );
  }
}
