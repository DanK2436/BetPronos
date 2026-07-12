import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../matches/providers/match_provider.dart';
import '../../coupons/providers/coupon_provider.dart';
import '../../coupons/models/coupon_model.dart';
import '../../predictions/services/prediction_orchestrator.dart';
import '../../predictions/models/prediction_model.dart';
import '../../../shared/models/match_model.dart';

class PredictionsView extends StatefulWidget {
  const PredictionsView({super.key});

  @override
  State<PredictionsView> createState() => _PredictionsViewState();
}

class _PredictionsViewState extends State<PredictionsView> {
  final PredictionOrchestrator _orchestrator = PredictionOrchestrator();
  final Map<String, ConsensusPrediction> _predictions = {};
  final Map<String, bool> _isLoading = {};

  Future<void> _fetchPrediction(MatchModel match, AuthProvider auth) async {
    if (!auth.canAccessPredictions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accès premium ou jetons requis.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading[match.id] = true;
    });

    try {
      final consensus = await _orchestrator.getConsensus(match);
      setState(() {
        _predictions[match.id] = consensus;
      });
      // Deduct one prediction from the user if not premium
      await auth.usePrediction();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la prédiction: \$e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading[match.id] = false;
        });
      }
    }
  }

  void _addToCoupon(MatchModel match, ConsensusPrediction consensus) {
    final couponProvider = Provider.of<CouponProvider>(context, listen: false);
    
    // Convert odds string (e.g. "1: 1.90 | X: 3.30 | 2: 3.80") to actual odds
    // For simplicity, we just use 1.90 as default if we can't parse it well
    double parseOdds(String oddsStr, String key) {
      try {
        if (oddsStr.contains(key)) {
          final parts = oddsStr.split(key);
          if (parts.length > 1) {
            final val = parts[1].split('|').first.trim();
            return double.tryParse(val) ?? 1.90;
          }
        }
      } catch (_) {}
      return 1.90;
    }

    final homeOdds = parseOdds(consensus.consensusBetting.estimatedOdds, '1:');
    final drawOdds = parseOdds(consensus.consensusBetting.estimatedOdds, 'X:');
    final awayOdds = parseOdds(consensus.consensusBetting.estimatedOdds, '2:');

    // Add main prediction as selection
    BetType betType;
    double selectedOdds;
    String selectedValue;
    
    if (consensus.consensusHomeScore > consensus.consensusAwayScore) {
      betType = BetType.homeWin;
      selectedOdds = homeOdds;
      selectedValue = '1';
    } else if (consensus.consensusAwayScore > consensus.consensusHomeScore) {
      betType = BetType.awayWin;
      selectedOdds = awayOdds;
      selectedValue = '2';
    } else {
      betType = BetType.draw;
      selectedOdds = drawOdds;
      selectedValue = 'X';
    }

    final selection = CouponSelection(
      matchId: match.id,
      homeTeamName: match.homeTeam.name,
      awayTeamName: match.awayTeam.name,
      leagueName: match.league.name,
      betType: betType,
      selectedValue: selectedValue,
      odds: selectedOdds,
      matchDateTime: match.dateTime,
    );

    couponProvider.addSelection(selection);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sélection ajoutée au coupon'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final matchProvider = Provider.of<MatchProvider>(context);
    final couponProvider = Provider.of<CouponProvider>(context);

    // Filter to show only matches not yet started (or we can show all)
    final matches = matchProvider.scheduledMatches;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Prédictions IA', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          if (authProvider.user != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    authProvider.isPremium ? 'Illimité' : '\${authProvider.predictionsLeft}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: matches.isEmpty
          ? const Center(
              child: Text('Aucun match disponible pour la prédiction.', style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final hasPrediction = _predictions.containsKey(match.id);
                final isLoading = _isLoading[match.id] ?? false;
                
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Match Header
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.sports_soccer, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    match.league.name,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormat('dd/MM HH:mm').format(match.dateTime),
                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Teams
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                match.homeTeam.name,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('VS', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Text(
                                match.awayTeam.name,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Action / Result
                        if (isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          )
                        else if (hasPrediction)
                          _buildPredictionResult(match, _predictions[match.id]!)
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _fetchPrediction(match, authProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Générer la prédiction IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPredictionResult(MatchModel match, ConsensusPrediction consensus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Consensus IA', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\${(consensus.overallConfidence * 100).toStringAsFixed(0)}% Confiance',
                  style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '\${consensus.consensusHomeScore} - \${consensus.consensusAwayScore}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            consensus.overallAnalysis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          // Options supplémentaires
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBetChip('BTTS: \${consensus.consensusBetting.bttsFullTime}'),
              _buildBetChip('Buts: \${consensus.consensusBetting.overUnder25}'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addToCoupon(match, consensus),
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              label: const Text('Ajouter au coupon', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }
}
