import 'dart:convert';
import 'package:dumum_tergo/services/logout_service.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SideMenuViewModel with ChangeNotifier {
  final LogoutService logoutService;
  bool _isDarkMode = false;
  bool _isLoading = false;
    bool _isDataLoaded = false; // Nouveau flag pour suivre le chargement initial

  String _errorMessage = '';
  String _name = ''; 
  String _profileImageUrl = ''; 
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
    bool get isDataLoaded => _isDataLoaded; // Getter pour le nouveau flag

  String get errorMessage => _errorMessage;
  String get name => _name;
  String get profileImageUrl => _profileImageUrl;
  SideMenuViewModel({required this.logoutService});

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }
void resetUserData() {
  _name = '';
  _profileImageUrl = '';
  _isDataLoaded = false;
  notifyListeners();
}
 Future<void> fetchUserData() async {
    if (_isDataLoaded) return; // Ne pas recharger si déjà fait
    
    try {
      _isLoading = true;
      notifyListeners();

      String? token = await storage.read(key: 'token');
      String? refreshToken = await storage.read(key: 'refreshToken');

      if (token == null || refreshToken == null) {
        throw Exception('Veuillez vous reconnecter');
      }

      var response = await _makeProfileRequest(token);

      if (response.statusCode == 401) {
        try {
          final newTokens = await _refreshToken(refreshToken);
          await _storeNewTokens(newTokens);
          response = await _makeProfileRequest(newTokens['accessToken']);
        } catch (e) {
          throw Exception('Session expirée, veuillez vous reconnecter');
        }
      }

      if (response.statusCode == 200) {
        await _processProfileResponse(response);
        _isDataLoaded = true; // Marquer les données comme chargées
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<http.Response> _makeProfileRequest(String token) async {
    return await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Map<String, dynamic>> _refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/refresh-token'),
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
      throw Exception(errorData['msg'] ?? 'Échec du rafraîchissement');
    } catch (e) {
      print('Erreur _refreshToken: $e');
      rethrow;
    }
  }

  Future<void> _storeNewTokens(Map<String, dynamic> tokens) async {
    await Future.wait([
      storage.write(key: 'token', value: tokens['accessToken']),
      storage.write(key: 'refreshToken', value: tokens['refreshToken']),
    ]);
  }



   Future<void> _processProfileResponse(http.Response response) async {
    final jsonResponse = jsonDecode(response.body);
    
    if (jsonResponse.containsKey('data')) {
      final userData = jsonResponse['data'];
      _name = userData['name'] ?? 'Inconnu';
      
      // Gestion améliorée de l'URL de l'image
      if (userData['image'] == null || userData['image'].isEmpty) {
        _profileImageUrl = 'assets/images/default.png';
      } else if (userData['image'].startsWith('http')) {
        _profileImageUrl = userData['image'];
      } else {
        _profileImageUrl = 'https://res.cloudinary.com/dcs2edizr/image/upload/${userData['image']}';
      }

      notifyListeners();
    } else {
      throw Exception("Format de réponse invalide");
    }
  }

  Future<void> logoutUser(BuildContext context, String token) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
          resetUserData();

      await logoutService.logout(token);
      await storage.delete(key: 'email');
      await storage.delete(key: 'accessToken');
      await storage.delete(key: 'token');
      await storage.delete(key: 'refreshToken');
      await storage.delete(key: 'userId');

      await storage.delete(key: 'password');
      await storage.delete(key: 'is_verified');
      await storage.delete(key: 'role');
      await storage.delete(key: 'genre');
      await storage.delete(key: 'image');
      await storage.delete(key: 'mobile');
      await storage.delete(key: 'name');
        
       
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout successful!')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
    } on Exception catch (e) {
      _errorMessage = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void navigateToHistory(BuildContext context) {
    // Navigate to history page
  }

  void navigateToIACamping(BuildContext context) {
    // Navigate to IA Camping page
  }
}