
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SideMenuViewModelSeller extends ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String name = 'Chargement...';
  String profileImageUrl = '';
  
  bool get isLoading => _isLoading;
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController adressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  void reset() {
    _isLoading = false;
    name = 'Chargement...';
    profileImageUrl = '';
    nameController.clear();
    emailController.clear();
    descriptionController.clear();
    adressController.clear();
    phoneNumberController.clear();
    imageUrlController.clear();
    notifyListeners();
  }
    Future<void> clearStorage() async {
    await storage.deleteAll();
      await storage.delete(key: '_id');

            await storage.delete(key: 'seller_token');

 // Supprime toutes les entrées du stockage sécurisé
    reset(); // Réinitialise les données du viewModel
  }
  
  Future<void>
   fetchProfileData() async {
    try {
      _isLoading = true;
      notifyListeners();

      String? token = await storage.read(key: 'seller_token');
      if (token == null || token.isEmpty) {
        print('Token not found');
        return;
      }

      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success']) {
          final Map<String, dynamic> userData = jsonResponse['data'];

          // Assign the data from API response to the controllers
          nameController.text = userData['businessName'] ?? 'Inconnu';
          name = nameController.text; // Update the name for display
          emailController.text = userData['email'] ?? 'Inconnu';
          descriptionController.text = userData['description'] ?? 'Inconnu';
          adressController.text = userData['businessAddress'] ?? 'Inconnu';
          
          // Handle phone number
          String rawPhoneNumber = userData['mobile'] ?? '';
          phoneNumberController.text = rawPhoneNumber;
          print(userData['mobile']);

          // Handle image URL
          profileImageUrl = userData['image'] != null && userData['image'].startsWith('http')
              ? userData['image']
              : "https://res.cloudinary.com/dcs2edizr/image/upload/${userData['image'] ?? '/images/images.png'}";
          imageUrlController.text = profileImageUrl;

          // Update subscription expiration date
     
        } else {
          throw Exception("Données utilisateur non trouvées");
        }
      } else {
        throw Exception('Failed to load profile data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      // Set default values in case of error
      name = 'Erreur de chargement';
      profileImageUrl = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}