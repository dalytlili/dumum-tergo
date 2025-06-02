import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordViewModel extends ChangeNotifier {
  String? errorMessage;
 bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Ajouter un setter pour isLoading
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  late Country selectedCountry;

  TextEditingController phoneNumberController = TextEditingController();

  ForgotPasswordViewModel() {
    // Sélectionner la Tunisie par défaut
    selectedCountry = CountryParser.parseCountryCode('TN') ?? Country.worldWide;
  }


  Future<bool> verifyPhoneNumber() async {
    String phoneNumber = phoneNumberController.text.trim();

    // Validation du numéro de téléphone
    if (phoneNumber.isEmpty) {
      errorMessage = 'Veuillez entrer votre numéro de téléphone.';
      notifyListeners();
      return false;
    }

    if (!RegExp(r'^\d+$').hasMatch(phoneNumber)) {
      errorMessage = 'Veuillez entrer un numéro de téléphone valide.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Construire le numéro de téléphone complet avec le code pays
      String fullPhoneNumber = '+${selectedCountry.phoneCode}$phoneNumber';

      // Envoyer une requête HTTP POST à l'API
      final response = await _sendOtpRequest(fullPhoneNumber);

      // Vérifier la réponse
      if (response.statusCode == 200) {
        errorMessage = null;
        return true;
      } else {
        final error = jsonDecode(response.body);
        errorMessage = error['msg'] ?? "Erreur lors de l'envoi de l'OTP";
        return false;
      }
    } catch (e) {
      errorMessage = "Une erreur s'est produite : ${e.toString()}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<http.Response> _sendOtpRequest(String fullPhoneNumber) async {
    return await http.post(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/forgot-passwordP'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': fullPhoneNumber}),
    );
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    super.dispose();
  }
}