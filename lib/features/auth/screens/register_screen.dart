import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/email_otp_service.dart';
import '../../home/screens/home_screen.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final EmailOtpService _otpService = EmailOtpService();

  /// Traduit les erreurs techniques en messages clairs
  String _translateError(String error) {
    if (error.contains('Email rate limit exceeded') ||
        error.contains('over_email_send_rate_limit')) {
      return 'Trop de tentatives. Attendez quelques minutes avant de réessayer.';
    }
    if (error.contains('already registered') ||
        error.contains('already been registered') ||
        error.contains('User already registered')) {
      return 'Cette adresse email est déjà utilisée. Essayez de vous connecter.';
    }
    if (error.contains('Password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (error.contains('Invalid email') || error.contains('invalid_email')) {
      return "L'adresse email n'est pas valide.";
    }
    if (error.contains('Limite de 2 comptes')) {
      return 'Limite atteinte : 2 comptes maximum par appareil.';
    }
    if (error.contains('network') || error.contains('SocketException')) {
      return '📵 Pas de connexion internet. Vérifiez votre réseau.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();

    try {
      await authProvider.register(
        email,
        _passwordController.text,
        _usernameController.text.trim(),
      );

      if (!mounted) return;

      // Aller vers l'écran OTP pour confirmer l'email
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpScreen(
          email: email,
          otpService: _otpService,
          isSignup: true,
          onVerified: () {
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ Inscription réussie ! Bienvenue sur betPronos !'),
              backgroundColor: AppColors.success,
            ));
          },
        ),
      ));
    } catch (e) {
      if (mounted) {
        final msg = _translateError(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Créer un compte',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Rejoignez la communauté betPronos',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    _buildField(
                      controller: _usernameController,
                      label: "Nom d'utilisateur",
                      icon: Icons.person,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? "Saisissez un nom d'utilisateur"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Email invalide'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6
                          ? 'Au moins 6 caractères requis'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // Info OTP
                    Row(
                      children: const [
                        Icon(Icons.info_outline,
                            color: AppColors.textMuted, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Un code de vérification sera envoyé par email.',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("S'inscrire",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
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
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
      ),
      validator: validator,
    );
  }
}
