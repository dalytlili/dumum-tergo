import 'dart:async';
import 'dart:convert';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Ajoutez cette importation

class OtpSellerViewModel extends ChangeNotifier {
  final String fullPhoneNumber;
  String? _accessToken; // Declare the userId here
String? _idvendor; // Ajouter cette ligne pour déclarer la variable

  bool _isLoading = false;
  String _otpCode = '';
  int _countdown = 30; // Compte à rebours de 60 secondes
  Timer? _timer;

  bool get isLoading => _isLoading;
  int get countdown => _countdown;

 bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  OtpSellerViewModel({required this.fullPhoneNumber}) {
    startCountdown();
  }
  String? get accessToken => _accessToken; // Add a getter for userId

  void setOtpCode(String value) {
    _otpCode = value;
    notifyListeners();
  }

Future<void> autoLogin(BuildContext context) async {
  try {
    // Lire le token depuis le stockage
    final token = await storage.read(key: 'seller_token');
    debugPrint('Token lu depuis le stockage: $token'); // Log pour vérifier le token

    if (token != null) {
      _accessToken = token;
      _isLoggedIn = true; // Mettre à jour l'état de connexion
      debugPrint('Token trouvé, utilisateur connecté. Redirection vers /payment-success'); // Log de succès

      // Rediriger vers l'écran de succès
      Navigator.pushReplacementNamed(context, '/payment-success');
    } else {
      _isLoggedIn = false; // L'utilisateur n'est pas connecté
      debugPrint('Aucun token trouvé, redirection vers /onboarding'); // Log d'échec

      // Rediriger vers l'écran de connexion
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  } catch (e) {
    debugPrint('Erreur lors de l\'auto-login: $e'); // Log en cas d'erreur
  } finally {
    notifyListeners(); // Notifier les écouteurs
  }
}


Future<bool> verifyOTP(BuildContext context) async {
  if (_otpCode.length != 6) return false;

  _isLoading = true;
  notifyListeners();

  try {
    final response = await http.post(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': fullPhoneNumber,
        'otp': _otpCode,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['accessToken'];
      debugPrint('Token reçu: $_accessToken');
      
      await storage.write(key: 'seller_token', value: _accessToken);
      await storage.write(key: '_id', value: _idvendor);
      print('id vendeur: $_idvendor');
      print('Tokens enregistrés avec succès');

      final bool profileCompleted = data['profileCompleted'] ?? false;
      final String subscriptionStatus = data['subscription']?['status'] ?? 'inactive';

      if (!profileCompleted) {
        // Ferme toutes les pages et va à complete_profile
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/complete_profile',
          (Route<dynamic> route) => false,
        );
      } else if (profileCompleted && subscriptionStatus == 'active') {
        // Ferme toutes les pages et va à payment-success
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/payment-success',
          (Route<dynamic> route) => false,
        );
      } else if (profileCompleted && subscriptionStatus != 'active') {
        // Ferme toutes les pages et va à PaymentView
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/PaymentView',
          (Route<dynamic> route) => false,
        );
      }

      return true;
    } else {
      debugPrint('Erreur lors de la vérification OTP: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    debugPrint('Erreur lors de la vérification OTP: $e');
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        _countdown--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

Future<void> resendOtp() async {
  if (_countdown > 0) return;

  _isLoading = true;
  notifyListeners();

  try {
    final response = await _sendOtpRequest(fullPhoneNumber);

    if (response.statusCode == 200) {
      // Si la requête est réussie, redémarrez le compte à rebours
      _countdown = 60;
      startCountdown();
      notifyListeners();
    } else {
      // Gérez les erreurs de réponse ici
      debugPrint('Erreur lors de l\'envoi de l\'OTP: ${response.statusCode}');
    }
  } catch (e) {
    // Gérez les exceptions ici
    debugPrint('Erreur lors de l\'envoi de l\'OTP: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<http.Response> _sendOtpRequest(String fullPhoneNumber) async {
  return await http.post(
    Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/request-otp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'mobile': fullPhoneNumber}),
  );
}



  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
