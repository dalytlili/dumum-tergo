import 'package:dumum_tergo/services/logout_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class AccueilViewModel extends ChangeNotifier {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final LogoutService _logoutService = LogoutService();
  String? _token;

  String? get token => _token;

  Future<void> fetchToken() async {
    // Récupérer le token depuis FlutterSecureStorage
    _token = await _storage.read(key: 'seller_token');
   // debugPrint('Token récupéré: $_token');
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
  if (_token == null) {
    debugPrint('Aucun token trouvé pour la déconnexion');
    return;
  }

  try {
    await _logoutService.logoutSeller(_token!);
  } catch (e) {
    debugPrint('Erreur lors de la déconnexion: $e');
    throw Exception('Erreur lors de la déconnexion: $e');
  }

  // Supprimer le token et le refreshToken depuis FlutterSecureStorage
  await _storage.delete(key: 'seller_token');
  await _storage.delete(key: 'refreshToken'); // Supprimer aussi le refreshToken si présent

  // Redirection après déconnexion
  Navigator.pushReplacementNamed(context, "/welcome");
}
}