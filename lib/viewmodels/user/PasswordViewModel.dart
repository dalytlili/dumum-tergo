import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PasswordViewModel extends ChangeNotifier {
  final String userId;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  PasswordViewModel({required this.userId});

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible = !isConfirmPasswordVisible;
    notifyListeners();
  }

  Future<void> setPassword(String password, c_password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId, // Envoyer user_id avec le mot de passe
          'password': password,
          'c_password': c_password,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Mot de passe changé avec succès');
      } else {
        debugPrint('Erreur lors du changement de mot de passe');
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
