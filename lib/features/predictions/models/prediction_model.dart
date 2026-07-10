class AgentPrediction {
  final String agentName;
  final int predictedHomeScore;
  final int predictedAwayScore;
  final double confidence; // e.g. 0.85 (85%)
  final String reasoning;

  AgentPrediction({
    required this.agentName,
    required this.predictedHomeScore,
    required this.predictedAwayScore,
    required this.confidence,
    required this.reasoning,
  });

  factory AgentPrediction.fromJson(Map<String, dynamic> json) {
    return AgentPrediction(
      agentName: json['agentName'] ?? '',
      predictedHomeScore: json['predictedHomeScore'] ?? 0,
      predictedAwayScore: json['predictedAwayScore'] ?? 0,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'agentName': agentName,
        'predictedHomeScore': predictedHomeScore,
        'predictedAwayScore': predictedAwayScore,
        'confidence': confidence,
        'reasoning': reasoning,
      };
}

class ConsensusPrediction {
  final String matchId;
  final List<AgentPrediction> agentPredictions;
  final int consensusHomeScore;
  final int consensusAwayScore;
  final double overallConfidence;
  final String overallAnalysis;

  ConsensusPrediction({
    required this.matchId,
    required this.agentPredictions,
    required this.consensusHomeScore,
    required this.consensusAwayScore,
    required this.overallConfidence,
    required this.overallAnalysis,
  });

  factory ConsensusPrediction.fromJson(Map<String, dynamic> json) {
    var list = json['agentPredictions'] as List? ?? [];
    List<AgentPrediction> predictionsList =
        list.map((i) => AgentPrediction.fromJson(i)).toList();

    return ConsensusPrediction(
      matchId: json['matchId'] ?? '',
      agentPredictions: predictionsList,
      consensusHomeScore: json['consensusHomeScore'] ?? 0,
      consensusAwayScore: json['consensusAwayScore'] ?? 0,
      overallConfidence: (json['overallConfidence'] ?? 0.0).toDouble(),
      overallAnalysis: json['overallAnalysis'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'agentPredictions': agentPredictions.map((e) => e.toJson()).toList(),
        'consensusHomeScore': consensusHomeScore,
        'consensusAwayScore': consensusAwayScore,
        'overallConfidence': overallConfidence,
        'overallAnalysis': overallAnalysis,
      };
}
