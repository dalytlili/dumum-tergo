import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ProfileViewModel with ChangeNotifier {
  String name = '';
  String profileImageUrl = '';
  bool isLoading = true;
  List<dynamic> experiences = [];
  int followersCount = 0;
  int followingCount = 0;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<void> fetchProfileData() async {
    try {
      isLoading = true;
      notifyListeners();

      String? token = await storage.read(key: 'token');
      String? refreshToken = await storage.read(key: 'refreshToken');
      String? userId = await storage.read(key: 'userId');

      if (token == null || refreshToken == null || userId == null) {
        throw Exception('Tokens ou ID utilisateur non disponibles');
      }

      // Première tentative avec le token actuel
      var profileResponse = await _makeProfileRequest(token);
      var experiencesResponse = await _makeExperiencesRequest(token, userId);

      // Si le token a expiré (401), on le rafraîchit
      if (profileResponse.statusCode == 401 || experiencesResponse.statusCode == 401) {
        print('Token expiré, tentative de rafraîchissement...');
        final newTokens = await _refreshToken(refreshToken);
        
        await storage.write(key: 'token', value: newTokens['accessToken']);
        await storage.write(key: 'refreshToken', value: newTokens['refreshToken']);
        
        profileResponse = await _makeProfileRequest(newTokens['accessToken']);
        experiencesResponse = await _makeExperiencesRequest(newTokens['accessToken'], userId);
      }

      if (profileResponse.statusCode == 200) {
        await _processProfileResponse(profileResponse);
      } else {
        throw Exception('Échec du chargement du profil: ${profileResponse.statusCode}');
      }

      if (experiencesResponse.statusCode == 200) {
        await _processExperiencesResponse(experiencesResponse);
      } else {
        throw Exception('Échec du chargement des expériences: ${experiencesResponse.statusCode}');
      }
    } catch (e) {
      print('Erreur: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<http.Response> _makeProfileRequest(String token) async {
    return await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> _makeExperiencesRequest(String token, String userId) async {
    return await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Map<String, dynamic>> _refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/refresh-token'),
      headers: {'Authorization': 'Bearer $refreshToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du rafraîchissement du token');
    }
  }

  Future<void> _processProfileResponse(http.Response response) async {
    final jsonResponse = json.decode(response.body);
    
    if (jsonResponse.containsKey('data')) {
      final userData = jsonResponse['data'];
      name = userData['name'] ?? 'Inconnu';
      
      // Mise à jour de l'image de profil
      profileImageUrl = userData['image']?.toString().startsWith('http') ?? false
          ? userData['image']
              .replaceAll(RegExp(r'width=\d+&height=\d+'), 'width=200&height=200')
          : "https://res.cloudinary.com/dcs2edizr/image/upload/${userData['image'] ?? '/images/default.png'}";

      // Mise à jour des compteurs d'abonnés/abonnements
      followersCount = userData['followersCount'] ?? userData['followers']?.length ?? 0;
      followingCount = userData['followingCount'] ?? userData['following']?.length ?? 0;

      notifyListeners();
    } else {
      throw Exception("Format de réponse invalide pour le profil");
    }
  }

  Future<void> _processExperiencesResponse(http.Response response) async {
    final jsonResponse = json.decode(response.body);
    
    if (jsonResponse is List) {
      experiences = jsonResponse;
      notifyListeners();
    } else if (jsonResponse.containsKey('data')) {
      experiences = jsonResponse['data'];
      notifyListeners();
    } else {
      throw Exception("Format de réponse invalide pour les expériences");
    }
  }
}