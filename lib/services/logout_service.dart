import 'dart:convert';

import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LogoutService {
  final String apiUrl = 'https://dumum-tergo-backend.onrender.com/api/logout';
  final String apiUrlSeller = 'https://dumum-tergo-backend.onrender.com/api/vendor/logout';
  final String refreshTokenUrl = 'https://dumum-tergo-backend.onrender.com/api/refresh-token';

  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<void> logout(String token) async {
    try {
      // First try to logout with the current token
      var response = await _makeLogoutRequest(token);

      // If token is expired (401), try to refresh it
      if (response.statusCode == 401) {
        final refreshToken = await storage.read(key: 'refreshToken');
        if (refreshToken != null) {
          try {
            final newTokens = await _refreshToken(refreshToken);
            await _storeNewTokens(newTokens);
            // Retry logout with new token
            response = await _makeLogoutRequest(newTokens['accessToken']);
          } catch (e) {
            await _clearTokens();
            throw Exception('Session expired, please login again');
          }
        } else {
          await _clearTokens();
          throw Exception('No refresh token available');
        }
      }

      // Clear storage in all cases
      await _clearTokens();

      // Check if logout was successful
      if (response.statusCode != 200) {
        throw Exception('Logout failed: ${response.statusCode}');
      }

      print('Logout successful.');
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

 

  Future<http.Response> _makeLogoutRequest(String token) async {
    return await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<http.Response> _makeSellerLogoutRequest(String token) async {
    return await http.get(
      Uri.parse(apiUrlSeller),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<Map<String, dynamic>> _refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(refreshTokenUrl),
        headers: {'Authorization': 'Bearer $refreshToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'accessToken': data['accessToken'],
            'refreshToken': data['refreshToken'],
          };
        }
      }

      final errorData = jsonDecode(response.body);
      throw Exception(errorData['msg'] ?? 'Token refresh failed');
    } catch (e) {
      print('Error in _refreshToken: $e');
      rethrow;
    }
  }

  Future<void> _storeNewTokens(Map<String, dynamic> tokens) async {
    await Future.wait([
      storage.write(key: 'token', value: tokens['accessToken']),
      storage.write(key: 'refreshToken', value: tokens['refreshToken']),
    ]);
  }

  Future<void> _storeNewSellerTokens(Map<String, dynamic> tokens) async {
    await Future.wait([
      storage.write(key: 'seller_token', value: tokens['accessToken']),
      storage.write(key: 'seller_refreshToken', value: tokens['refreshToken']),
    ]);
  }

  Future<void> _clearTokens() async {
    await Future.wait([
      storage.delete(key: 'token'),
      storage.delete(key: 'refreshToken'),
      storage.delete(key: 'email'),
      storage.delete(key: 'password'),
    ]);
  }

  Future<void> _clearSellerTokens() async {
    await Future.wait([
      storage.delete(key: 'seller_token'),
      storage.delete(key: 'seller_refreshToken'),
      // Add any other seller-specific keys here
    ]);
  }
     Future<void> logoutSeller(String token) async {
  try {
    // Récupérer le token depuis le stockage sécurisé
    final token = await storage.read(key: 'seller_token'); // Utilisez la clé 'seller_token'
    print('Token récupéré: $token'); // Vérifiez ce qui est affiché dans la console

    // Vérifier si le token est valide
    if (token == null || token.isEmpty) {
      throw Exception('Aucun token trouvé pour la déconnexion');
    }

    // Envoyer une requête GET pour la déconnexion
    final response = await http.get(
      Uri.parse(apiUrlSeller),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Vérifier la réponse du serveur
    if (response.statusCode == 200) {
      // Supprimer le token et le refreshToken depuis le stockage sécurisé
      await storage.delete(key: 'seller_token'); // Supprimez le token avec la clé 'seller_token'
      await storage.delete(key: 'refreshToken'); // Supprimez aussi le refreshToken si présent

      print('Déconnexion réussie.');
    } else {
      throw Exception(
          'Erreur lors de la déconnexion: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Erreur lors de la déconnexion: $e');
    throw Exception('Erreur lors de la déconnexion: $e');
  }
}
}
  

