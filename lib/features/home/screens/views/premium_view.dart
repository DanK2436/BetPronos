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

    _requestNotificationPermission();

    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id ?? '';
    final email = authProvider.user?.email ?? 'user@betpronos.com';
    final plan = _plans[_selectedPlanIndex];
    final reference = 'ref_${DateTime.now().millisecondsSinceEpoch}';
    final operator = _selectedOperator;
    final phoneNumber = _phoneController.text.trim();
    final planName = plan['title'];
    final price = plan['price'];

    // Envoi de la demande de push direct mobile money
    final res = await _shwaryService.initializeDirectPayment(
      userId: userId,
      email: email,
      amount: price.toDouble(),
      currency: 'CDF',
      reference: reference,
      operator: operator,
      phoneNumber: phoneNumber,
      planName: planName,
    );

    setState(() {
      _isProcessing = false;
    });

    if (res['success'] == true && mounted) {
      // Afficher le dialogue natif d'attente d'autorisation PIN
      _showUssdPushWaitingDialog(context, reference, planName, price, operator, phoneNumber, authProvider);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de la demande de paiement. Veuillez réessayer.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showUssdPushWaitingDialog(
    BuildContext context,
    String reference,
    String planName,
    int price,
    String operator,
    String phoneNumber,
    AuthProvider authProvider,
  ) {
    bool isCompleted = false;
    int secondsRemaining = 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            // Fonction de vérification d'état en boucle
            void startPolling() async {
              while (secondsRemaining > 0 && !isCompleted) {
                await Future.delayed(const Duration(seconds: 3));
                secondsRemaining -= 3;
                
                if (secondsRemaining <= 0 || isCompleted) break;
                
                final isPaid = await _shwaryService.verifyPaymentStatus(reference);
                if (isPaid) {
                  isCompleted = true;
                  Navigator.of(dialogContext).pop(); // Fermer le dialogue de chargement
                  await authProvider.makePremium();
                  if (context.mounted) {
                    _showSuccessSMSDialog(context, planName, price);
                  }
                  break;
                }
                
                if (context.mounted) {
                  setStateDialog(() {});
                }
              }
              
              if (!isCompleted && secondsRemaining <= 0) {
                isCompleted = true;
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Délai d\'autorisation du code PIN dépassé.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            }

            // Démarrer la boucle de vérification au premier build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (secondsRemaining == 60) {
                startPolling();
              }
            });

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF2A2D4A), width: 1),
              ),
              title: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Validation $operator',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Une demande de paiement de $price CDF a été envoyée sur votre téléphone ($phoneNumber).',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Veuillez saisir votre code PIN secret sur le prompt USSD qui s\'affiche sur votre mobile pour valider.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vérification en cours : ${secondsRemaining}s...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      isCompleted = true;
                      Navigator.of(dialogContext).pop();
                      await authProvider.makePremium();
                      if (context.mounted) {
                        _showSuccessSMSDialog(context, planName, price);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Simuler Succès (Test)', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      isCompleted = true;
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
              Navigator.pop(context); // Fermer le dialogue de succès
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
                  'Mode de Paiement (Shwary Direct)',
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
