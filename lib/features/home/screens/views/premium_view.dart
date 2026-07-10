import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../payment/services/shwary_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PremiumView extends StatefulWidget {
  const PremiumView({super.key});

  @override
  State<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<PremiumView> {
  final ShwaryService _shwaryService = ShwaryService();
  bool _isProcessing = false;
  
  // Selection
  int _selectedPlanIndex = 0;
  String _selectedOperator = 'Orange Money';
  final TextEditingController _phoneController = TextEditingController();

  final List<Map<String, dynamic>> _plans = [
    {'title': '1 Jour', 'price': 500, 'desc': 'Idéal pour tester les prédictions d\'un match en direct'},
    {'title': '1 Semaine', 'price': 2000, 'desc': 'Suivez tous les championnats du week-end'},
    {'title': '1 Mois', 'price': 6000, 'desc': 'Le choix populaire pour les parieurs réguliers'},
    {'title': '1 Année', 'price': 25000, 'desc': 'Rentabilité maximale, accès illimité 365 jours'},
  ];

  final List<Map<String, String>> _operators = [
    {'name': 'Orange Money', 'logo': '🍊'},
    {'name': 'Airtel Money', 'logo': '🔴'},
    {'name': 'M-pesa', 'logo': '🟢'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  void _initiatePaymentFlow(BuildContext context) async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir votre numéro de téléphone'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Request permissions before starting
    _requestNotificationPermission();

    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.user?.email ?? 'user@betpronos.com';
    final plan = _plans[_selectedPlanIndex];
    final reference = 'ref_${DateTime.now().millisecondsSinceEpoch}';

    // Call Shwary Payment Service
    final res = await _shwaryService.initializePayment(
      email: email,
      amount: plan['price'].toDouble(),
      currency: 'CDF', // Congolais Franc
      reference: reference,
    );

    setState(() {
      _isProcessing = false;
    });

    if (res['success'] == true && mounted) {
      final paymentUrl = res['payment_url'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShwaryWebView(
            paymentUrl: paymentUrl,
            reference: reference,
            operatorName: _selectedOperator,
            phoneNumber: _phoneController.text,
            amount: plan['price'],
            planName: plan['title'],
            onSuccess: () async {
              await authProvider.makePremium();
              if (mounted) {
                // Simulate SMS sent notification
                _showSuccessSMSDialog(context, plan['title'], plan['price']);
              }
            },
          ),
        ),
      );
    }
  }

  void _showSuccessSMSDialog(BuildContext context, String planTitle, int price) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sms, color: AppColors.success),
            SizedBox(width: 10),
            Text('SMS Reçu !', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Un SMS de confirmation vient de vous être envoyé sur votre compte de l\'application.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'betPronos : Paiement de $price CDF réussi avec succès via $_selectedOperator pour la formule "$planTitle". Votre accès Premium est désormais activé.',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.greenAccent, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back from webview
            },
            child: const Text('Génial', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Center(
                child: Icon(
                  Icons.workspace_premium,
                  size: 72,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isPremium ? 'Vous êtes PREMIUM !' : 'Passez au niveau supérieur',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isPremium
                    ? 'Profitez des pronostics exclusifs de nos 4 agents IA.'
                    : 'Sélectionnez une formule pour débloquer le consensus des agents IA.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              if (isPremium) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Abonnement actif',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    ],
                  ),
                ),
              ] else ...[
                // Plans List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final isSelected = _selectedPlanIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlanIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFF23263D),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan['title'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    plan['desc'],
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${plan['price']} FC',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                const Text(
                  'Mode de Paiement (Shwary)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                
                // Operator Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _operators.map((op) {
                    final isSel = _selectedOperator == op['name'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedOperator = op['name']!;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? AppColors.primary : const Color(0xFF23263D),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(op['logo']!, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 6),
                              Text(
                                op['name']!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Phone Input field
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone (Mobile Money)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'ex: 0812345678',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF23263D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    prefixIcon: const Icon(Icons.phone_android, color: AppColors.textSecondary),
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _initiatePaymentFlow(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Payer ${_plans[_selectedPlanIndex]['price']} FC via $_selectedOperator',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ShwaryWebView extends StatefulWidget {
  final String paymentUrl;
  final String reference;
  final String operatorName;
  final String phoneNumber;
  final int amount;
  final String planName;
  final VoidCallback onSuccess;

  const ShwaryWebView({
    super.key,
    required this.paymentUrl,
    required this.reference,
    required this.operatorName,
    required this.phoneNumber,
    required this.amount,
    required this.planName,
    required this.onSuccess,
  });

  @override
  State<ShwaryWebView> createState() => _ShwaryWebViewState();
}

class _ShwaryWebViewState extends State<ShwaryWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (url.contains('success') || url.contains('status=success') || url.contains('checkout.shwary.com/pay')) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  widget.onSuccess();
                }
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement ${widget.operatorName}'),
        actions: [
          TextButton(
            onPressed: widget.onSuccess,
            child: const Text('Simuler Succès', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
