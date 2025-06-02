import 'dart:io';
import 'dart:convert';
import 'package:country_picker/country_picker.dart';
import 'package:dumum_tergo/views/seller/auth/VerificationOtpChangeMobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Pour MediaType

class EditProfileSellerViewModel with ChangeNotifier {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController adressController = TextEditingController();
DateTime? _subscriptionExpirationDate;

DateTime? get subscriptionExpirationDate => _subscriptionExpirationDate;
  bool _isLoading = false;

   String _selectedGender = '';

  // Getter pour accéder à selectedGender
  String get selectedGender => _selectedGender;
  TextEditingController phoneNumberController = TextEditingController();

  // Getter pour isLoading
  bool get isLoading => _isLoading;
    Country selectedCountry = CountryParser.parseCountryCode('TN') ?? Country.worldWide;

  // Méthode pour mettre à jour le genre
 


  // Récupérer les données du profil utilisateur
  Future<void> fetchProfileData() async {
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
        emailController.text = userData['email'] ?? 'Inconnu';
                descriptionController.text = userData['description'] ?? 'Inconnu';

                adressController.text = userData['businessAddress'] ?? 'Inconnu';
        // Mettre à jour le contrôleur de texte
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

     // Mettre à jour la date d'expiration de l'abonnement
        if (userData['subscription'] != null) {
          _subscriptionExpirationDate = DateTime.parse(userData['subscription']['expirationDate']);
        }
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
String get remainingSubscriptionTime {
  if (_subscriptionExpirationDate == null) {
    return 'Aucune date d\'expiration trouvée';
  }

  final now = DateTime.now();
  final difference = _subscriptionExpirationDate!.difference(now);

  if (difference.isNegative) {
    return 'Abonnement expiré';
  }

  final days = difference.inDays;
  final hours = difference.inHours % 24;
  final minutes = difference.inMinutes % 60;

  return '$days jours';
}


Future<void> updateProfile(BuildContext context) async {
  try {
    _isLoading = true;
    notifyListeners();

    // Accédez à la propriété `text` du contrôleur pour obtenir la valeur réelle
    String fullPhoneNumber = '+${selectedCountry.phoneCode}${phoneNumberController.text}';

    String? token = await storage.read(key: 'seller_token');
    if (token == null) throw Exception('Token not found');

    // Récupérer le vendeur actuel pour vérifier si le numéro de mobile a changé
    final currentVendorResponse = await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (currentVendorResponse.statusCode != 200) {
      throw Exception('Failed to fetch current profile data');
    }

    final Map<String, dynamic> currentVendorData = json.decode(currentVendorResponse.body);
    final String currentMobile = currentVendorData['data']['mobile'];

    // Vérifier si le numéro de mobile a changé
    final bool isMobileChanged = fullPhoneNumber != currentMobile;

    final uri = Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/update-profile');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['businessName'] = nameController.text
      ..fields['businessAddress'] = adressController.text
      ..fields['description'] = descriptionController.text
..fields['email'] = emailController.text;
    // Si le numéro de mobile a changé, ajoutez-le à la requête
    if (isMobileChanged) {
      request.fields['mobile'] = fullPhoneNumber;
    }

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
      // Si le numéro de mobile a changé, rediriger vers la page de vérification OTP
      if (isMobileChanged) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationOtpChangeMobile(fullPhoneNumber: fullPhoneNumber),
          ),
        );
      } else {
        // Sinon, afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );

        // Recharger les données du profil après une mise à jour réussie
        await fetchProfileData();
      }
    } else {
      // Gestion des erreurs
      if (responseJson.containsKey('errors')) {
        final List<dynamic> errors = responseJson['errors'];
        for (var error in errors) {
          if (error['msg'] == 'Le numéro de mobile est déjà utilisé par un autre utilisateur.') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error['msg']), backgroundColor: Colors.red),
            );
            Navigator.pop(context);
            break;
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur inattendue: ${responseJson['msg']}'), backgroundColor: Colors.red),
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
}