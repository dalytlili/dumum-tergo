import 'package:country_picker/country_picker.dart';
import 'package:dumum_tergo/main.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../services/auth_service.dart'; // Importer le service

class SignUpViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Country selectedCountry = Country(
    phoneCode: "216",
    countryCode: "TN",
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: "Tunisia",
    example: "Tunisia",
    displayName: "Tunisia",
    displayNameNoCountryCode: "TN",
    e164Key: "",
  );

  String selectedGender = '';
  bool acceptedTerms = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  void updateCountry(Country country) {
    selectedCountry = country;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible = !isConfirmPasswordVisible;
    notifyListeners();
  }

  void updateGender(String gender) {
    selectedGender = gender;
    notifyListeners();
  }

  void toggleTermsAcceptance(bool? value) {
    acceptedTerms = value ?? false;
    notifyListeners();
  }
 Future<void> loginWithGoogle(BuildContext context) async {
    final url = 'https://dumum-tergo-backend.onrender.com/auth/google';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'dumumtergo',
      );

      final uri = Uri.parse(result);
      print('URL de retour: $uri'); // Affichez l'URL de retour pour vérification

      final accessToken = uri.queryParameters['accessToken'];
      final refreshToken = uri.queryParameters['refreshToken'];

      if (accessToken != null && refreshToken != null) {
        // Enregistrer les tokens dans FlutterSecureStorage
        await storage.write(key: 'token', value: accessToken); // Clé 'token'
        await storage.write(key: 'refreshToken', value: refreshToken);

        print('Tokens enregistrés avec succès');
        print('Access Token: $accessToken');
        print('Refresh Token: $refreshToken');

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion avec Google réussie')),
        );

        // Naviguer vers la page d'accueil
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw Exception('Tokens non reçus');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la connexion avec Google.')),
      );
    }
  }


 Future<void> loginWithFacebook(BuildContext context) async {
    final url = 'https://dumum-tergo-backend.onrender.com/auth/facebook/callback';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'dumumtergo',
      );

      final uri = Uri.parse(result);
      print('URL de retour: $uri'); // Affichez l'URL de retour pour vérification

      final accessToken = uri.queryParameters['accessToken'];
      final refreshToken = uri.queryParameters['refreshToken'];

      if (accessToken != null && refreshToken != null) {
        // Enregistrer les tokens dans FlutterSecureStorage
        await storage.write(key: 'token', value: accessToken); // Clé 'token'
        await storage.write(key: 'refreshToken', value: refreshToken);

        print('Tokens enregistrés avec succès');
        print('Access Token: $accessToken');
        print('Refresh Token: $refreshToken');

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion avec Facebook réussie')),
        );

        // Naviguer vers la page d'accueil
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw Exception('Tokens non reçus');
      }
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la connexion avec Facebook.')),
      );
    }
  }
  Future<bool> signUp() async {
  // Valider les entrées
  if (!_validateInputs()) {
    throw Exception('Veuillez remplir tous les champs correctement.');
  }

  isLoading = true;
  notifyListeners();

  try {
    // Construire le numéro de téléphone complet avec le code du pays
    final fullMobileNumber = '+${selectedCountry.phoneCode}${phoneController.text}';

    // Appeler le service d'enregistrement avec le numéro de téléphone complet
    final response = await AuthService.register(
      name: nameController.text,
      genre: selectedGender,
      email: emailController.text,
      mobile: fullMobileNumber, // Utiliser le numéro de téléphone complet
      password: passwordController.text,
    );

    // Vérifier si l'enregistrement a réussi
    if (response['success'] == true) {
      debugPrint('Enregistrement réussi: ${response['msg']}');
      debugPrint('Utilisateur enregistré: ${response['user']}');
      return true;
    } else {
      // Si l'enregistrement échoue, extraire le message d'erreur
      final errorMessage = response['msg'] ?? 'Erreur inconnue';
      throw Exception(errorMessage); // Lancer une exception avec le message d'erreur
    }
  } catch (e) {
    // Capturer l'exception et la propager
    debugPrint('Erreur lors de l\'enregistrement: $e');
    throw Exception('Erreur lors de l\'enregistrement: ${e.toString()}');
  } finally {
    isLoading = false;
    notifyListeners();
  }
}
  bool _validateInputs() {
    // Valider les entrées
    if (nameController.text.isEmpty) {
      return false;
    }

    if (emailController.text.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text)) {
      return false;
    }

    if (phoneController.text.isEmpty ||
        !RegExp(r'^\d+$').hasMatch(phoneController.text)) {
      return false;
    }

    if (selectedGender.isEmpty || !['Homme', 'Femme'].contains(selectedGender)) {
      return false;
    }

    if (passwordController.text.isEmpty || passwordController.text.length < 8) {
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      return false;
    }

    if (!acceptedTerms) {
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}