import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../payment/services/shwary_service.dart';

class PremiumView extends StatefulWidget {
  const PremiumView({super.key});

  @override
  State<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<PremiumView> {
  final ShwaryService _shwaryService = ShwaryService();
  bool _isProcessing = false;

  int _selectedPlanIndex = 1; // Par défaut : 1 Semaine
  String _selectedOperator = 'Orange Money';
  final TextEditingController _phoneController = TextEditingController();

  final List<Map<String, dynamic>> _plans = [
    {'title': '1 Jour',    'price': 500,   'desc': 'Idéal pour tester',                   'popular': false},
    {'title': '1 Semaine', 'price': 2000,  'desc': 'Suivez tous les championnats',         'popular': true},
    {'title': '1 Mois',    'price': 6000,  'desc': 'Le choix des parieurs réguliers',      'popular': false},
    {'title': '1 Année',   'price': 25000, 'desc': 'Accès illimité — meilleur rapport',   'popular': false},
  ];

  final List<Map<String, String>> _operators = [
    {'name': 'Orange Money', 'asset': 'assets/images/orange_money.jpg'},
    {'name': 'Airtel Money', 'asset': 'assets/images/airtel_money.jpg'},
    {'name': 'M-pesa',       'asset': 'assets/images/mpesa.jpg'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) await Permission.notification.request();
  }

  void _initiatePayment(BuildContext context) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez saisir votre numéro de téléphone Mobile Money'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    _requestNotificationPermission();
    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final plan = _plans[_selectedPlanIndex];
    final reference = 'bp_${DateTime.now().millisecondsSinceEpoch}';

    final res = await _shwaryService.initializeDirectPayment(
      userId: authProvider.user?.id ?? '',
      email: authProvider.user?.email ?? 'user@betpronos.com',
      amount: (plan['price'] as int).toDouble(),
      currency: 'CDF',
      reference: reference,
      operator: _selectedOperator,
      phoneNumber: phone,
      planName: plan['title'],
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _showPinWaitingDialog(
        context: context,
        reference: res['reference'] ?? reference,
        planName: plan['title'],
        price: plan['price'],
        authProvider: authProvider,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ ${res['error'] ?? 'Échec du paiement. Vérifiez votre numéro.'}'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  void _showPinWaitingDialog({
    required BuildContext context,
    required String reference,
    required String planName,
    required int price,
    required AuthProvider authProvider,
  }) {
    bool _completed = false;
    int _secsLeft = 90;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setD) {
          // Lancer le polling dès le premier build
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (_secsLeft == 90) {
              while (_secsLeft > 0 && !_completed) {
                await Future.delayed(const Duration(seconds: 5));
                _secsLeft -= 5;
                if (!dialogCtx.mounted) break;
                final paid = await _shwaryService.verifyPaymentStatus(reference);
                if (paid) {
                  _completed = true;
                  Navigator.of(dialogCtx).pop();
                  await authProvider.makePremium();
                  if (context.mounted) _showSuccessDialog(context, planName, price);
                  break;
                }
                if (dialogCtx.mounted) setD(() {});
              }
              if (!_completed && _secsLeft <= 0) {
                _completed = true;
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Délai dépassé. Si vous avez confirmé le PIN, réessayez.'),
                    backgroundColor: AppColors.warning,
                  ));
                }
              }
            }
          });

          final op = _operators.firstWhere(
            (o) => o['name'] == _selectedOperator,
            orElse: () => _operators[0],
          );

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF2A2D4A)),
            ),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(op['asset']!, width: 32, height: 32, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Confirmation $_selectedOperator',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.phone_android, color: AppColors.primary, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Un message de confirmation a été envoyé sur votre téléphone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entrez votre code PIN $_selectedOperator pour valider ${price} CDF',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(
                      'Vérification... ${_secsLeft}s',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _completed = true;
                  Navigator.of(dialogCtx).pop();
                },
                child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String planTitle, int price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text('Paiement confirmé !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Votre accès Premium "$planTitle" est activé.\nbetPronos : $price CDF débité via $_selectedOperator.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Profiter du Premium'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isPremium = authProvider.isPremium;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── En-tête ───
                const Center(
                  child: Icon(Icons.workspace_premium_rounded, size: 64, color: AppColors.warning),
                ),
                const SizedBox(height: 12),
                Text(
                  isPremium ? '✅ Vous êtes PREMIUM' : 'Passer en Premium',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isPremium
                      ? 'Profitez des pronostics exclusifs de nos 5 agents IA.'
                      : 'Débloquez les analyses IA de toutes les compétitions.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 28),

                if (isPremium) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.success, size: 48),
                        SizedBox(height: 12),
                        Text('Abonnement actif', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ] else ...[

                  // ─── Plans ───
                  ...List.generate(_plans.length, (i) {
                    final plan = _plans[i];
                    final isSelected = _selectedPlanIndex == i;
                    final isPopular = plan['popular'] as bool;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlanIndex = i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFF2A2D4A),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: i,
                              groupValue: _selectedPlanIndex,
                              onChanged: (v) => setState(() => _selectedPlanIndex = v!),
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(plan['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                      if (isPopular) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text('⭐ Populaire', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(plan['desc'], style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            Text('${plan['price']} FC', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // ─── Opérateurs ───
                  const Text('Opérateur Mobile Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: _operators.map((op) {
                      final isSel = _selectedOperator == op['name'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedOperator = op['name']!),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? AppColors.primary : const Color(0xFF2A2D4A),
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    op['asset']!,
                                    width: 40,
                                    height: 30,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 30, color: AppColors.textMuted),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  op['name']!,
                                  style: TextStyle(
                                    color: isSel ? AppColors.primary : AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // ─── Numéro de téléphone ───
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      hintText: 'ex: 0812345678  ou  +243812345678',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.phone_android, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A2D4A))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'ℹ️ Le numéro doit correspondre à votre compte $_selectedOperator.\nLe format +243 est appliqué automatiquement.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.5),
                  ),

                  const SizedBox(height: 28),

                  // ─── Bouton Payer ───
                  ElevatedButton(
                    onPressed: _isProcessing ? null : () => _initiatePayment(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    ),
                    child: _isProcessing
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            'Payer ${_plans[_selectedPlanIndex]['price']} FC — ${_plans[_selectedPlanIndex]['title']}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    '🔒 Paiement sécurisé via Shwary · Orange Money · Airtel · M-Pesa',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
