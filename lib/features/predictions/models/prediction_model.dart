class BettingOptions {
  final String bttsFullTime;   // "Oui" / "Non"
  final String bttsFirstHalf;  // "Oui" / "Non"
  final String bttsSecondHalf; // "Oui" / "Non"
  final String overUnder15;    // "Plus de 1.5" / "Moins de 1.5"
  final String overUnder25;    // "Plus de 2.5" / "Moins de 2.5"
  final String oddEven;        // "Pair" / "Impair"
  final String estimatedOdds;   // ex: "Victoire: 1.80 | Nul: 3.40 | Défaite: 4.20 (1XBet/BetPawa)"

  BettingOptions({
    required this.bttsFullTime,
    required this.bttsFirstHalf,
    required this.bttsSecondHalf,
    required this.overUnder15,
    required this.overUnder25,
    required this.oddEven,
    required this.estimatedOdds,
  });

  factory BettingOptions.fromJson(Map<String, dynamic> json) {
    return BettingOptions(
      bttsFullTime: json['bttsFullTime']?.toString() ?? 'Non',
      bttsFirstHalf: json['bttsFirstHalf']?.toString() ?? 'Non',
      bttsSecondHalf: json['bttsSecondHalf']?.toString() ?? 'Non',
      overUnder15: json['overUnder15']?.toString() ?? 'Moins de 1.5',
      overUnder25: json['overUnder25']?.toString() ?? 'Moins de 2.5',
      oddEven: json['oddEven']?.toString() ?? 'Impair',
      estimatedOdds: json['estimatedOdds']?.toString() ?? '1.50',
    );
  }

  Map<String, dynamic> toJson() => {
        'bttsFullTime': bttsFullTime,
        'bttsFirstHalf': bttsFirstHalf,
        'bttsSecondHalf': bttsSecondHalf,
        'overUnder15': overUnder15,
        'overUnder25': overUnder25,
        'oddEven': oddEven,
        'estimatedOdds': estimatedOdds,
      };
}

class AgentPrediction {
  final String agentName;
  final int predictedHomeScore;
  final int predictedAwayScore;
  final double confidence; // e.g. 0.85 (85%)
  final String reasoning;
  final BettingOptions bettingOptions;

  AgentPrediction({
    required this.agentName,
    required this.predictedHomeScore,
    required this.predictedAwayScore,
    required this.confidence,
    required this.reasoning,
    required this.bettingOptions,
  });

  factory AgentPrediction.fromJson(Map<String, dynamic> json) {
    return AgentPrediction(
      agentName: json['agentName'] ?? '',
      predictedHomeScore: json['predictedHomeScore'] ?? 0,
      predictedAwayScore: json['predictedAwayScore'] ?? 0,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? '',
      bettingOptions: BettingOptions.fromJson(json['bettingOptions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'agentName': agentName,
        'predictedHomeScore': predictedHomeScore,
        'predictedAwayScore': predictedAwayScore,
        'confidence': confidence,
        'reasoning': reasoning,
        'bettingOptions': bettingOptions.toJson(),
      };
}

class ConsensusPrediction {
  final String matchId;
  final List<AgentPrediction> agentPredictions;
  final int consensusHomeScore;
  final int consensusAwayScore;
  final double overallConfidence;
  final String overallAnalysis;
  final BettingOptions consensusBetting;

  ConsensusPrediction({
    required this.matchId,
    required this.agentPredictions,
    required this.consensusHomeScore,
    required this.consensusAwayScore,
    required this.overallConfidence,
    required this.overallAnalysis,
    required this.consensusBetting,
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
      consensusBetting: BettingOptions.fromJson(json['consensusBetting'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'agentPredictions': agentPredictions.map((e) => e.toJson()).toList(),
        'consensusHomeScore': consensusHomeScore,
        'consensusAwayScore': consensusAwayScore,
        'overallConfidence': overallConfidence,
        'overallAnalysis': overallAnalysis,
        'consensusBetting': consensusBetting.toJson(),
      };
}
