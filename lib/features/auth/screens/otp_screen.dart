import 'package:flutter/material.dart';
import 'package:betpronos/features/auth/services/email_otp_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isSignup; // true pour inscription, false pour connexion
  final EmailOtpService otpService;

  const OtpScreen({
    Key? key,
    required this.email,
    required this.isSignup,
    required this.otpService,
  }) : super(key: key);

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _enteredOtp = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vérification OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Un code a été envoyé à ${widget.email}'),
            TextField(
              decoration: InputDecoration(labelText: 'Code OTP'),
              onChanged: (value) => _enteredOtp = value,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: Text('Vérifier'),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un code à 6 chiffres')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ✅ Utilisation de la méthode unique verifyOtp avec paramètres nommés
      bool success = await widget.otpService.verifyOtp(
        email: widget.email,
        code: _enteredOtp,
      );

      if (success) {
        // Rediriger vers l'écran suivant
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code invalide, veuillez réessayer')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Méthode pour renvoyer un OTP (si besoin)
  Future<void> _resendOtp() async {
    try {
      // ✅ Appel avec paramètre nommé
      await widget.otpService.sendOtp(email: widget.email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Un nouveau code a été envoyé')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du renvoi: $e')),
      );
    }
  }
}
