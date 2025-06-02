import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OtpVerificationViewModel extends ChangeNotifier {
  final String fullPhoneNumber;
  String? _userId; // Declare the userId here

  bool _isLoading = false;
  String _otpCode = '';
  int _countdown = 60; // Compte à rebours de 60 secondes
  Timer? _timer;

  bool get isLoading => _isLoading;
  int get countdown => _countdown;

  OtpVerificationViewModel({required this.fullPhoneNumber}) {
    startCountdown();
  }
  String? get userId => _userId; // Add a getter for userId

  void setOtpCode(String value) {
    _otpCode = value;
    notifyListeners();
  }

  Future<bool> verifyOTP() async {
  if (_otpCode.length != 6) return false;

  _isLoading = true;
  notifyListeners();

  try {
    final response = await http.post(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/verifyOtpPhone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': fullPhoneNumber,
        'otp': _otpCode,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _userId = data['user_id']; // Utiliser 'user_id' au lieu de 'userId'
      debugPrint('User ID reçu: $_userId'); // Afficher userId dans la console
      return data['success'] ?? false;
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
      await Future.delayed(const Duration(seconds: 1));
      // Logique pour renvoyer l'OTP via API
    } finally {
      _isLoading = false;
      _countdown = 60;
      startCountdown();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
