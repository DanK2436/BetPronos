import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../models/match_model.dart';
import '../../features/predictions/screens/prediction_screen.dart';
import '../../features/home/screens/views/premium_view.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isPremium = authProvider.isPremium;
    final canAccess = authProvider.canAccessPredictions;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (canAccess) {
            if (!isPremium) {
              authProvider.usePrediction();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Essai gratuit : Prédiction consultée. Reste : ${authProvider.predictionsLeft}'),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PredictionScreen(match: match),
              ),
            );
          } else {
            // Suggest subscription
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Votre essai gratuit est expiré ou vous avez épuisé vos 5 prédictions. Passez Premium !'),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Scaffold(
                body: PremiumView(),
              )),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // League & Status header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (match.league.logoUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: match.league.logoUrl,
                          width: 20,
                          height: 20,
                          placeholder: (context, url) => const SizedBox(width: 20, height: 20),
                          errorWidget: (context, url, error) => const Icon(Icons.emoji_events, size: 16, color: AppColors.primary),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        match.league.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 16),
              // Teams & Scores
              Row(
                children: [
                  // Home Team
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogo(match.homeTeam.logoUrl),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeam.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Score / Time
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        if (match.status == MatchStatus.live || match.status == MatchStatus.finished)
                          Text(
                            '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          )
                        else
                          Text(
                            DateFormat('HH:mm').format(match.dateTime),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        if (match.status == MatchStatus.live && match.timeElapsed != null)
                          Text(
                            match.timeElapsed!,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (match.status == MatchStatus.scheduled)
                          Text(
                            DateFormat('dd MMM').format(match.dateTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Away Team
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogo(match.awayTeam.logoUrl),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeam.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // AI Call To Action / Prediction badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E213A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      canAccess ? 'Consensus IA : Voir Prédiction (${isPremium ? "Illimité" : "${authProvider.predictionsLeft} restants"})' : 'Consensus IA : 🔒 Premium requis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: canAccess ? AppColors.secondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String url) {
    if (url.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.sports_soccer, size: 24, color: AppColors.textMuted),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: 48,
      height: 48,
      placeholder: (context, url) => Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.sports_soccer, size: 24, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    String label;
    switch (match.status) {
      case MatchStatus.live:
        color = AppColors.error;
        label = 'LIVE';
        break;
      case MatchStatus.finished:
        color = AppColors.textMuted;
        label = 'TERMINE';
        break;
      case MatchStatus.scheduled:
        color = AppColors.primary;
        label = 'A VENIR';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
