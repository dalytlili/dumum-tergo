import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginService {
  final http.Client client;

  LoginService({required this.client});

  Future<Map<String, dynamic>> authenticate(
    String identifier, String password, bool isPhoneMode, String? countryCode) async {
 final body = {
  'password': password,
};

if (isPhoneMode && countryCode != null) {
  if (!identifier.startsWith('+')) {
    body['identifier'] = '+$countryCode$identifier'; // Format: +21655947170
  } else {
    body['identifier'] = identifier; // Utiliser tel quel si le code pays est déjà présent
  }
  print('Numéro de téléphone complet: ${body['identifier']}');
} else {
  body['identifier'] = identifier; // Sinon, utiliser l'email
  print('Email: $identifier');
}

  final response = await client.post(
    Uri.parse('https://dumum-tergo-backend.onrender.com/api/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['msg'] ?? 'Authentication failed');
  }

}
}
