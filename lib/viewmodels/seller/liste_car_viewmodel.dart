import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart'; // Vérifier si ce fichier est nécessaire

class ListeCarViewModel with ChangeNotifier {
  List<dynamic> _searchResults = [];
  List<dynamic> _allCars = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fonction pour récupérer les voitures du vendeur
  Future<void> fetchCarsFromVendor() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? token = await storage.read(key: 'seller_token');
      if (token == null) {
        _error = 'Session expirée. Veuillez vous reconnecter.';
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse("https://dumum-tergo-backend.onrender.com/api/cars/vendor"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          _allCars = responseData['data'];
          _searchResults = _allCars;
        } else {
          _error = 'Erreur dans la réponse du serveur';
        }
      } else {
        _error = 'Erreur ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      _error = 'Erreur de connexion: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fonction pour rechercher par matricule
  void searchByRegistrationNumber(String query) {
    if (query.isEmpty) {
      _searchResults = _allCars;
    } else {
      _searchResults = _allCars.where((car) =>
        car['registrationNumber'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  // Fonction pour charger les résultats de recherche (utilisée pour la simulation de chargement)
  Future<void> loadSearchResults(List<dynamic> results) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500)); // Simule un chargement
    
    _searchResults = results;
    _isLoading = false;
    notifyListeners();
  }
}
