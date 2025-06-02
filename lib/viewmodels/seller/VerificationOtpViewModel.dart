import 'dart:async';
import 'dart:convert';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VerificationOtpViewModel extends ChangeNotifier {
  final String fullPhoneNumber;
  String? _userId; // Pour stocker l'ID de l'utilisateur
  bool _isLoading = false;
  String _otpCode = '';
  int _countdown = 60; // Compte à rebours de 60 secondes
  Timer? _timer;

  bool get isLoading => _isLoading;
  int get countdown => _countdown;
  String? get userId => _userId;

  VerificationOtpViewModel({required this.fullPhoneNumber}) {
    startCountdown();
  }

  void setOtpCode(String value) {
    _otpCode = value;
    notifyListeners();
  }

Future<bool> verifyOTP(String authToken) async {
  if (_otpCode.length != 6) return false;

  _isLoading = true;
  notifyListeners();
  String? token = await storage.read(key: 'seller_token');
    if (token == null) throw Exception('Token not found');
  try {
        debugPrint('OTP envoyé au serveur: $_otpCode'); // Log pour déboguer

    final response = await http.post(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/verify-otp-update-mobile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken', // Include the token here
      },
      body: jsonEncode({
        'otp': _otpCode,
      }),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Afficher userId dans la console
      return data['success'] ?? false;
      
    } else {
      // Gestion des erreurs spécifiques
      if (data.containsKey('msg')) {
        throw Exception(data['msg']); // Afficher le message d'erreur de l'API
      } else {
        throw Exception('Erreur inattendue: ${response.statusCode}');
      }
    }
  } catch (e) {
    debugPrint('Erreur lors de la vérification OTP: $e');
    rethrow; // Propager l'erreur pour l'afficher dans l'UI
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<void> resendOtp() async {
    if (_countdown > 0) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Envoyer une requête pour renvoyer l'OTP
      final response = await http.post(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': fullPhoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Réinitialiser le compte à rebours
          _countdown = 60;
          startCountdown();
        }
      } else {
        debugPrint('Erreur lors du renvoi de l\'OTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur lors du renvoi de l\'OTP: $e');
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}