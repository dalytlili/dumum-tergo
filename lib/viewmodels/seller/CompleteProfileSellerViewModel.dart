import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart'; // Pour MediaType

class CompleteProfileSellerViewModel with ChangeNotifier {
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
String? _idvendor; // Ajouter cette ligne pour déclarer la variable

  // Initialisation de FlutterSecureStorage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> loginUser(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Récupérer le token depuis FlutterSecureStorage
      String? token = await _storage.read(key: 'seller_token');
      debugPrint('Token récupéré: $token'); // Log pour vérifier le token // Log pour vérifier le token

    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/complete-profile');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['businessName'] = nameController.text
            ..fields['email'] = emailController.text
      ..fields['description'] = descriptionController.text
      ..fields['businessAddress'] = addressController.text;
 print('seller_token: $token');
    // Vérifier si une image a été sélectionnée et si elle existe
    if (imageUrlController.text.isNotEmpty) {
      File imageFile = File(imageUrlController.text);
      if (await imageFile.exists()) {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();

        var multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }
    }

    // Envoyer la requête
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    print('Réponse du serveur: $responseBody');

    // Analyser la réponse
    final Map<String, dynamic> responseJson = json.decode(responseBody);

    if (response.statusCode == 200) {
_idvendor = responseJson['vendor']?['_id'];


      // Succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );

       await _storage.write(key: 'businessName', value: nameController.text); // Enregistrer le nom
      await _storage.write(key: 'businessAddress', value: addressController.text); // Enregistrer l'adresse
  await _storage.write(key: '_id', value: _idvendor); // Clé 'token'
        print('id vendeur: $_idvendor');
      debugPrint('Nom enregistré: ${nameController.text}');
      debugPrint('Adresse enregistrée: ${addressController.text}');

      Navigator.pushReplacementNamed(context, '/PaymentView');

      // Recharger les données du profil après une mise à jour réussie

 
    
    }
  } catch (e) {
    // Gestion des exceptions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  void saveProfile() {
  
  }

  void cancelChanges() {
   
    notifyListeners();
  }
}