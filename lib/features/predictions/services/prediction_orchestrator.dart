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

/// Orchestre tous les agents IA en parallèle et calcule le consensus final.
/// Agents actifs : Gemini · GPT-4o · Mistral · DeepSeek · Kimi · Grok · Z.ai
class PredictionOrchestrator {
  final List<BaseAgent> _agents = [
    GeminiAgent(),    // Google Gemini 1.5 Flash
    OpenAiAgent(),    // GPT-4o
    MistralAgent(),   // Mistral Large
    DeepSeekAgent(),  // DeepSeek Chat
    KimiAgent(),      // Moonshot Kimi v1
    GrokAgent(),      // xAI Grok-2
    ZaiAgent(),       // Z.ai GLM-4
  ];

  Future<ConsensusPrediction> getConsensus(MatchModel match) async {
    debugPrint('🤖 Lancement de ${_agents.length} agents IA pour ${match.homeTeam.name} vs ${match.awayTeam.name}...');

    // Tous les agents tournent en parallèle (Future.wait)
    final List<Future<AgentPrediction>> futures =
        _agents.map((agent) => agent.predict(match)).toList();

    final List<AgentPrediction> predictions = await Future.wait(futures);

    debugPrint('✅ ${predictions.length} prédictions reçues');

    // ── Calcul du consensus pondéré par la confiance ──
    double weightedHome = 0;
    double weightedAway = 0;
    double totalWeight = 0;

    for (final pred in predictions) {
      final w = pred.confidence; // la confiance sert de poids
      weightedHome += pred.predictedHomeScore * w;
      weightedAway += pred.predictedAwayScore * w;
      totalWeight += w;
    }

    final consensusHome = totalWeight > 0
        ? (weightedHome / totalWeight).round()
        : (predictions.map((p) => p.predictedHomeScore).reduce((a, b) => a + b) / predictions.length).round();
    final consensusAway = totalWeight > 0
        ? (weightedAway / totalWeight).round()
        : (predictions.map((p) => p.predictedAwayScore).reduce((a, b) => a + b) / predictions.length).round();
    final overallConfidence = totalWeight / predictions.length;

    // ── Résumé en français ──
    final pct = (overallConfidence * 100).toStringAsFixed(0);
    String summary;
    if (consensusHome > consensusAway) {
      summary = '${predictions.length} agents IA s\'accordent en faveur de ${match.homeTeam.name} à domicile ($consensusHome–$consensusAway). Indice de confiance moyen : $pct%.';
    } else if (consensusAway > consensusHome) {
      summary = '${predictions.length} agents IA penchent pour ${match.awayTeam.name} à l\'extérieur ($consensusHome–$consensusAway). Indice de confiance moyen : $pct%.';
    } else {
      summary = '${predictions.length} agents IA prédisent un match nul ($consensusHome–$consensusAway) entre ${match.homeTeam.name} et ${match.awayTeam.name}. Indice de confiance : $pct%.';
    }

    return ConsensusPrediction(
      matchId: match.id,
      agentPredictions: predictions,
      consensusHomeScore: consensusHome,
      consensusAwayScore: consensusAway,
      overallConfidence: overallConfidence,
      overallAnalysis: summary,
    );
  }
}
