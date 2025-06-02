import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AuthService {
  static const String _baseUrl = 'https://dumum-tergo-backend.onrender.com/api';

static Future<Map<String, dynamic>> register({
  required String name,
  required String genre,
  required String email,
  required String mobile,
  required String password,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": name,
        "genre": genre,
        "email": email,
        "mobile": mobile,
        "password": password,
      }),
    );

    final Map<String, dynamic> responseData = jsonDecode(response.body);

    return responseData; // Retourner l'objet JSON complet
  } catch (e) {
    return {'success': false, 'msg': "Erreur lors de l'enregistrement: $e"};
  }
}

}
