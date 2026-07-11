import 'package:cloud_functions/cloud_functions.dart';

class EmailOtpService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Demande l'envoi d'un OTP à l'adresse email fournie.
  /// Appelle une Cloud Function qui gère l'envoi et le stockage côté serveur.
  Future<void> sendOtp({required String email}) async {
    final callable = _functions.httpsCallable('sendOtp');
    await callable.call(<String, dynamic>{
      'email': email,
    });
  }

  /// Vérifie l'OTP saisi par l'utilisateur en interrogeant le serveur.
  /// Retourne `true` si le code est valide et non expiré.
  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    final callable = _functions.httpsCallable('verifyOtp');
    final result = await callable.call(<String, dynamic>{
      'email': email,
      'code': code,
    });
    return result.data['valid'] as bool;
  }
}
