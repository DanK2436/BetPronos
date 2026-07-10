import '../agents/base_agent.dart';
import '../agents/gemini_agent.dart';
import '../agents/openai_agent.dart';
import '../agents/mistral_agent.dart';
import '../agents/deepseek_agent.dart';
import '../models/prediction_model.dart';
import '../../../shared/models/match_model.dart';

class PredictionOrchestrator {
  final List<BaseAgent> _agents = [
    GeminiAgent(),
    OpenAiAgent(),
    MistralAgent(),
    DeepSeekAgent(),
  ];

  Future<ConsensusPrediction> getConsensus(MatchModel match) async {
    // Run all agents in parallel
    final List<Future<AgentPrediction>> futures = 
        _agents.map((agent) => agent.predict(match)).toList();
    
    final List<AgentPrediction> predictions = await Future.wait(futures);

    // Calculate consensus score by averaging and rounding
    double totalHome = 0;
    double totalAway = 0;
    double totalConfidence = 0;

    for (var pred in predictions) {
      totalHome += pred.predictedHomeScore;
      totalAway += pred.predictedAwayScore;
      totalConfidence += pred.confidence;
    }

    final consensusHome = (totalHome / predictions.length).round();
    final consensusAway = (totalAway / predictions.length).round();
    final overallConfidence = totalConfidence / predictions.length;

    // Generate consensus summary in French
    String summary = 'Les agents IA s\'accordent sur un match serré. ';
    if (consensusHome > consensusAway) {
      summary += 'La majorité préconise une victoire de ${match.homeTeam.name} à domicile avec un indice de confiance de ${(overallConfidence * 100).toStringAsFixed(0)}%.';
    } else if (consensusAway > consensusHome) {
      summary += 'La tendance s\'oriente vers une victoire à l\'extérieur de ${match.awayTeam.name} avec un indice de confiance de ${(overallConfidence * 100).toStringAsFixed(0)}%.';
    } else {
      summary += 'Un match nul est fortement probable entre ${match.homeTeam.name} et ${match.awayTeam.name}.';
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
