import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/coupon_provider.dart';
import '../models/coupon_model.dart';
import '../../matches/providers/match_provider.dart';
import '../services/smart_coupon_service.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  final SmartCouponService _smartCouponService = SmartCouponService();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CouponProvider>(
      builder: (context, provider, child) {
        final coupon = provider.activeCoupon;
        final hasSelections = coupon != null && coupon.selections.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                const Text('Mon Coupon', style: TextStyle(color: AppColors.textPrimary)),
                if (hasSelections) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\${coupon.selectionCount}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
          ),
          body: hasSelections
              ? _buildCouponList(context, provider, coupon)
              : _buildEmptyState(context),
          bottomNavigationBar: hasSelections
              ? _buildBottomBar(context, provider, coupon)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt, size: 80, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Aucune sélection',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des pronostics depuis les matchs pour construire votre coupon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : () async {
              setState(() => _isGenerating = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Génération du coupon intelligent en cours...'),
                  backgroundColor: AppColors.primary,
                  duration: Duration(seconds: 2),
                ),
              );
              
              try {
                final matchProvider = Provider.of<MatchProvider>(context, listen: false);
                final couponProvider = Provider.of<CouponProvider>(context, listen: false);
                
                final coupon = await _smartCouponService.generateSmartCoupon(matchProvider.scheduledMatches);
                if (coupon != null && coupon.selections.isNotEmpty) {
                  for (final s in coupon.selections) {
                    couponProvider.addSelection(s);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coupon intelligent généré avec succès !'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aucun match sûr trouvé. Veuillez réessayer.'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                }
              } finally {
                if (mounted) {
                  setState(() => _isGenerating = false);
                }
              }
            },
            icon: _isGenerating 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('Générateur IA', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponList(BuildContext context, CouponProvider provider, Coupon coupon) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coupon.selections.length,
      itemBuilder: (context, index) {
        final selection = coupon.selections[index];
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '\${selection.homeTeamName} - \${selection.awayTeamName}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                      onPressed: () => provider.removeSelection(selection.matchId),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  selection.leagueName,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getBetTypeName(selection.betType),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selection.selectedValue,
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      selection.odds.toStringAsFixed(2),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, CouponProvider provider, Coupon coupon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cote Totale',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                Text(
                  coupon.totalOdds.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  provider.validateCoupon();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coupon validé avec succès !'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'VALIDER LE COUPON',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBetTypeName(BetType type) {
    switch (type) {
      case BetType.score: return 'Score Exact';
      case BetType.homeWin: return 'Victoire Domicile';
      case BetType.draw: return 'Match Nul';
      case BetType.awayWin: return 'Victoire Extérieur';
      case BetType.btts: return 'Les 2 Marquent';
      case BetType.over15: return 'Plus de 1.5 buts';
      case BetType.over25: return 'Plus de 2.5 buts';
      case BetType.oddEven: return 'Pair/Impair';
      default: return 'Pari';
    }
  }
}
