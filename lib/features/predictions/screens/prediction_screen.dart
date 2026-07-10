import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/match_model.dart';
import '../models/prediction_model.dart';
import '../providers/prediction_provider.dart';

class PredictionScreen extends StatefulWidget {
  final MatchModel match;

  const PredictionScreen({super.key, required this.match});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PredictionProvider>(context, listen: false)
          .calculatePrediction(widget.match);
    });
  }

  @override
  Widget build(BuildContext context) {
    final predictionProvider = Provider.of<PredictionProvider>(context);
    final consensus = predictionProvider.getPrediction(widget.match.id);
    final isLoading = predictionProvider.isMatchLoading(widget.match.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analyse des Agents IA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: isLoading || consensus == null
            ? _buildLoader()
            : _buildContent(consensus),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ).animate().scale(duration: 800.ms, curve: Curves.easeInOut),
          const SizedBox(height: 32),
          const Text(
            'Les Agents IA analysent ce match...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fade(duration: 500.ms).slideY(begin: 0.2, end: 0.0),
          const SizedBox(height: 12),
          Text(
            'Gemini, GPT-4, Mistral & DeepSeek calculent le consensus',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ).animate().fade(delay: 400.ms, duration: 500.ms),
        ],
      ),
    );
  }

  Widget _buildContent(ConsensusPrediction consensus) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Match Header Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Text(
                  widget.match.homeTeam.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 20)),
              ),
              Expanded(
                child: Text(
                  widget.match.awayTeam.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Consensus Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'SCORE PREDU CONSENSUS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${consensus.consensusHomeScore} - ${consensus.consensusAwayScore}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                // Trust percentage gauge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Confiance : ${(consensus.overallConfidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white30),
                const SizedBox(height: 8),
                Text(
                  consensus.overallAnalysis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ).animate().fade(duration: 600.ms).scale(curve: Curves.easeOutBack),
          
          const SizedBox(height: 32),
          const Text(
            'Analyses Individuelles des Agents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Build list of individual agent predictions
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: consensus.agentPredictions.length,
            itemBuilder: (context, index) {
              final pred = consensus.agentPredictions[index];
              return _buildAgentCard(pred);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(AgentPrediction pred) {
    Color agentColor;
    if (pred.agentName.contains('Gemini')) {
      agentColor = AppColors.geminiColor;
    } else if (pred.agentName.contains('GPT-4')) {
      agentColor = AppColors.openaiColor;
    } else if (pred.agentName.contains('Mistral')) {
      agentColor = AppColors.mistralColor;
    } else {
      agentColor = AppColors.deepseekColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: agentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pred.agentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: agentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Score: ${pred.predictedHomeScore} - ${pred.predictedAwayScore}',
                    style: TextStyle(
                      color: agentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              pred.reasoning,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.show_chart, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Confiance de l\'agent : ${(pred.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade(delay: 200.ms, duration: 400.ms).slideX(begin: 0.1, end: 0.0);
  }
}
