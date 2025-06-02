// services/api_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      // Read token from secure storage
      final token = await storage.read(key: 'token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('API request failed: ${e.toString()}');
    }
  }
Future<Map<String, dynamic>> getseller(String endpoint) async {
    try {
      // Read token from secure storage
      final token = await storage.read(key: 'seller_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('API request failed: ${e.toString()}');
    }
  }
  Future<Map<String, dynamic>> post(String endpoint, {dynamic body}) async {
    try {
      final token = await storage.read(key: 'token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('API request failed: ${e.toString()}');
    }
  }

  // Add similar methods for PUT, DELETE etc. as needed

  Map<String, dynamic> _handleResponse(http.Response response) {
    final responseBody = json.decode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      // Extract error message from response if available
      final errorMessage = responseBody['message'] ?? 
          'Request failed with status: ${response.statusCode}';
      throw Exception(errorMessage);
    }
  }

  // Token management methods
  Future<void> saveToken(String token) async {
    await storage.write(key: 'token', value: token);
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'token');
  }

  Future<bool> hasToken() async {
    return await storage.containsKey(key: 'token');
  }
}