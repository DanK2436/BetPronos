import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../coupons/providers/coupon_provider.dart';
import '../../../coupons/models/coupon_model.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                const Text('Coupons', style: TextStyle(color: AppColors.textPrimary)),
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
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ]
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Coupon Actif'),
                Tab(text: 'Historique'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Active coupon
              hasSelections
                  ? _buildCouponList(context, provider, coupon)
                  : _buildEmptyState(context, provider),
              // Tab 2: History
              _buildHistory(context, provider),
            ],
          ),
          bottomNavigationBar: hasSelections && _tabController.index == 0
              ? _buildBottomBar(context, provider, coupon)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, CouponProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt, size: 80, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Aucune sélection',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Allez dans "Pronos" pour ajouter des matchs à votre coupon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context, CouponProvider provider) {
    final history = provider.coupons;
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Aucun coupon validé',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vos coupons validés apparaîtront ici.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final c = history[index];
        return _buildHistoryCouponCard(c);
      },
    );
  }

  Widget _buildHistoryCouponCard(Coupon coupon) {
    final status = coupon.overallStatus;
    final isWon = status == CouponSelectionStatus.won;
    final isLost = status == CouponSelectionStatus.lost;
    final statusColor = isWon ? AppColors.success : isLost ? AppColors.error : AppColors.warning;
    final statusText = isWon ? 'GAGNE' : isLost ? 'PERDU' : 'EN COURS';
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(coupon.createdAt);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\${coupon.selectionCount} sélection(s)',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'x\${coupon.totalOdds.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        children: coupon.selections.map((s) {
          final selStatus = s.status;
          final selColor = selStatus == CouponSelectionStatus.won
              ? AppColors.success
              : selStatus == CouponSelectionStatus.lost
                  ? AppColors.error
                  : AppColors.textMuted;
          final selIcon = selStatus == CouponSelectionStatus.won
              ? Icons.check_circle
              : selStatus == CouponSelectionStatus.lost
                  ? Icons.cancel
                  : Icons.pending;

          return ListTile(
            leading: Icon(selIcon, color: selColor, size: 20),
            title: Text(
              '\${s.homeTeamName} vs \${s.awayTeamName}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            subtitle: Text(
              '\${_getBetTypeName(s.betType)}: \${s.selectedValue}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Text(
              s.odds.toStringAsFixed(2),
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
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
                        '\${selection.homeTeamName} vs \${selection.awayTeamName}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
                const Text('Cote Totale', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                Text(
                  coupon.totalOdds.toStringAsFixed(2),
                  style: const TextStyle(color: AppColors.success, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await provider.validateCoupon();
                  if (context.mounted) {
                    _tabController.animateTo(1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coupon valide ! Retrouvez-le dans l\'Historique.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
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
      case BetType.homeWin: return 'Victoire Dom.';
      case BetType.draw: return 'Match Nul';
      case BetType.awayWin: return 'Victoire Ext.';
      case BetType.btts: return 'Les 2 Marquent';
      case BetType.over15: return '+1.5 buts';
      case BetType.over25: return '+2.5 buts';
      case BetType.oddEven: return 'Pair/Impair';
    }
  }
}
