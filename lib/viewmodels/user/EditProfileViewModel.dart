import 'dart:io';
import 'dart:convert';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Pour MediaType

class EditProfileViewModel with ChangeNotifier {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController genreController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  bool _isLoading = false;

   String _selectedGender = '';

  // Getter pour accéder à selectedGender
  String get selectedGender => _selectedGender;
  TextEditingController phoneNumberController = TextEditingController();

  // Getter pour isLoading
  bool get isLoading => _isLoading;
    Country selectedCountry = CountryParser.parseCountryCode('TN') ?? Country.worldWide;

  // Méthode pour mettre à jour le genre
  void updateGender(String gender) {
    _selectedGender = gender;
    genreController.text = gender; // Mettre à jour le contrôleur de texte
    notifyListeners();
  }


  // Récupérer les données du profil utilisateur
  Future<void> fetchProfileData() async {
  try {
    _isLoading = true;
    notifyListeners();

    String? token = await storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      print('Token not found');
      return;
    }

    final response = await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse['success']) {
        final Map<String, dynamic> userData = jsonResponse['data'];

        // Assign the data from API response to the controllers
        nameController.text = userData['name'] ?? 'Inconnu';
        emailController.text = userData['email'] ?? 'Inconnu';
          _selectedGender = userData['genre'] ?? 'Non spécifié'; // Mettre à jour selectedGender
        genreController.text = selectedGender; // Mettre à jour le contrôleur de texte
String rawPhoneNumber = userData['mobile'] ;

// Supprimer le code du pays si présent
if (rawPhoneNumber.startsWith('+${selectedCountry.phoneCode}')) {
  rawPhoneNumber = rawPhoneNumber.replaceFirst('+${selectedCountry.phoneCode}', '');
}

phoneNumberController.text = rawPhoneNumber;
    print(userData['mobile']);

        // Handle image URL and ensure it is a valid URL
        imageUrlController.text = userData['image'] != null &&
                userData['image'].startsWith('http')
            ? userData['image']
            : "https://res.cloudinary.com/dcs2edizr/image/upload/${userData['image'] ?? '/images/images.png'}";


        // Notify listeners for UI update
        notifyListeners();
      } else {
        throw Exception("Données utilisateur non trouvées");
      }
    } else {
      throw Exception('Failed to load profile data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    _isLoading = false;
    notifyListeners(); // Notify about loading state
  }
}

  // Mettre à jour le profil de l'utilisateur



Future<void> updateProfile(BuildContext context) async {
  try {
    _isLoading = true;
    notifyListeners();

    String fullPhoneNumber = '+${selectedCountry.phoneCode}${phoneNumberController.text}';

    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('https://dumum-tergo-backend.onrender.com/api/update-Profile');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = nameController.text
      ..fields['genre'] = genreController.text
      ..fields['mobile'] = fullPhoneNumber;

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

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    print('Réponse du serveur: $responseBody');

    final Map<String, dynamic> responseJson = json.decode(responseBody);

 if (response.statusCode == 200) {
  // Vérifiez d'abord si responseJson['data'] existe
  final dynamic responseData = responseJson['user'];
  String? newImageUrl;

  if (responseData != null && responseData is Map<String, dynamic>) {
    newImageUrl = responseData['image'] as String?;

  }
        print('Nouvelle image URL : $responseData'); // ← Ici l'affichage en console

  // Mise à jour du stockage avec les nouvelles données
  await _updateStorageData(
    name: nameController.text,
    genre: genreController.text,
    mobile: fullPhoneNumber,
    image: newImageUrl ,
  );
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Profil mis à jour avec succès')),
  );

  await fetchProfileData();
  Navigator.pop(context);
} else {
      if (responseJson.containsKey('errors')) {
        final List<dynamic> errors = responseJson['errors'];
        for (var error in errors) {
          if (error['msg'] == 'Le numéro de mobile est déjà utilisé par un autre utilisateur.') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error['msg']),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pop(context);
            break;
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue: ${responseJson['msg']}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

// Méthode pour mettre à jour les données dans le stockage
// Méthode pour mettre à jour les données dans le stockage
Future<void> _updateStorageData({
  required String name,
  required String genre,
  required String mobile,
  String? image,
}) async {
  await storage.write(key: 'userName', value: name);
  await storage.write(key: 'userGenre', value: genre);
  await storage.write(key: 'userMobile', value: mobile);

    await storage.write(key: 'userImage', value: image);

  
  // Vous pouvez aussi mettre à jour l'email si nécessaire
  // (bien que normalement l'email ne change pas souvent)
  String? email = await storage.read(key: 'userEmail');
  if (email == null) {
    email = emailController.text;
    await storage.write(key: 'userEmail', value: email);
  }
}
}