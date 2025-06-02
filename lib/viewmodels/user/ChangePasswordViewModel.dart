import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChangePasswordViewModel with ChangeNotifier {
  // États du ViewModel
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSuccess = false;

  // États pour la visibilité de chaque champ de mot de passe
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Getters pour accéder aux états
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;

  // Getters pour la visibilité de chaque champ
  bool get isOldPasswordVisible => _isOldPasswordVisible;
  bool get isNewPasswordVisible => _isNewPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;

  // Stockage sécurisé pour le token
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Méthodes pour basculer la visibilité de chaque champ
  void toggleOldPasswordVisibility() {
    _isOldPasswordVisible = !_isOldPasswordVisible;
    notifyListeners(); // Notifier les écouteurs du changement d'état
  }

  void toggleNewPasswordVisibility() {
    _isNewPasswordVisible = !_isNewPasswordVisible;
    notifyListeners(); // Notifier les écouteurs du changement d'état
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners(); // Notifier les écouteurs du changement d'état
  }

  // Méthode pour modifier le mot de passe
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Réinitialiser les états avant de commencer
    _isLoading = true;
    _errorMessage = '';
    _isSuccess = false;
    notifyListeners();

    try {
      // Récupérer le token depuis le stockage sécurisé
      String? token = await _storage.read(key: 'token');

      if (token == null) {
        throw "Vous devez être connecté pour modifier votre mot de passe.";
      }

      // Valider les entrées
      if (newPassword != confirmPassword) {
        throw "Le nouveau mot de passe et la confirmation ne correspondent pas.";
      }

      if (newPassword.length < 8) {
        throw "Le nouveau mot de passe doit contenir au moins 8 caractères.";
      }

      // Envoyer la requête à l'API
      final response = await http.post(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/change-password'), // URL de l'API
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      // Vérifier la réponse de l'API
      if (response.statusCode == 200) {
        // Succès : mettre à jour l'état
        _isSuccess = true;
      } else {
        // Erreur : extraire le message d'erreur de la réponse
        final responseData = jsonDecode(response.body);
        throw responseData['msg'] ?? 'Une erreur est survenue.';
      }
    } catch (error) {
      // Gestion des erreurs
      _errorMessage = error.toString();
    } finally {
      // Mettre à jour l'état de chargement
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthode pour réinitialiser les états
  void resetState() {
    _isLoading = false;
    _errorMessage = '';
    _isSuccess = false;
    notifyListeners();
  }
}