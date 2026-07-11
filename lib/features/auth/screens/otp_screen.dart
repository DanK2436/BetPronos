import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../services/email_otp_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final EmailOtpService otpService;
  final VoidCallback onVerified;
  final bool isSignup; // true = OtpType.signup, false = OtpType.email

  const OtpScreen({
    super.key,
    required this.email,
    required this.otpService,
    required this.onVerified,
    this.isSignup = true,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _hasError = false;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) _canResend = true;
      });
      return _resendCountdown > 0;
    });
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  /// Masque partiellement l'email pour l'affichage
  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${name[0]}***@$domain';
    return '${name.substring(0, 2)}***@$domain';
  }

  void _verify() async {
    if (_enteredOtp.length < 6) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final bool isValid = widget.isSignup
        ? await widget.otpService.verifySignupOtp(widget.email, _enteredOtp)
        : await widget.otpService.verifyEmailOtp(widget.email, _enteredOtp);

    if (isValid) {
      widget.onVerified();
    } else {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _resend() async {
    if (!_canResend) return;
    setState(() => _isLoading = true);
    try {
      await widget.otpService.sendOtp(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('📧 Code renvoyé par email !'),
          backgroundColor: AppColors.success,
        ));
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Échec du renvoi. Vérifiez votre connexion.'),
          backgroundColor: AppColors.error,
        ));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône email
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_rounded,
                      color: AppColors.primary, size: 48),
                ).animate().fade(duration: 600.ms).scale(delay: 100.ms, duration: 500.ms),

                const SizedBox(height: 32),

                Text(
                  'Vérification par email',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 200.ms),

                const SizedBox(height: 12),

                Text(
                  'Nous avons envoyé un code à 6 chiffres à\n$_maskedEmail\nVérifiez vos spams si vous ne le voyez pas.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.6),
                ).animate().fade(delay: 300.ms),

                const SizedBox(height: 40),

                // Champs OTP 6 chiffres
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _hasError
                              ? AppColors.error.withValues(alpha: 0.15)
                              : AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _hasError
                                  ? AppColors.error
                                  : const Color(0xFF23263D),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          if (_enteredOtp.length == 6) _verify();
                        },
                      ),
                    );
                  }),
                ).animate().fade(delay: 400.ms),

                if (_hasError) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '❌ Code incorrect ou expiré. Réessayez.',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w500),
                  ).animate().shake(),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading || _enteredOtp.length < 6 ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirmer le code',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ).animate().fade(delay: 500.ms),

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: _canResend ? _resend : null,
                  child: Text(
                    _canResend
                        ? '📧 Renvoyer le code par email'
                        : 'Renvoyer dans $_resendCountdown secondes...',
                    style: TextStyle(
                      color: _canResend
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight: _canResend
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← Modifier l\'email',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
