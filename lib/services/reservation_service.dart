import 'dart:io';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:dumum_tergo/constants/api_constants.dart';

class ReservationService {
  static final ReservationService _instance = ReservationService._internal();
  factory ReservationService() => _instance;
  ReservationService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _baseUrl = ApiConstants.baseUrl;

  Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Map<String, dynamic>> createReservation({
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    required int childSeats,
    required int additionalDrivers,
    required String location,
    required String driverEmail,
    required String driverPhoneNumber,
    required File permisRectoImage,
    required File permisVersoImage,
    File? cinRectoImage,
    File? cinVersoImage,
    File? passportImage,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Token d\'authentification non trouvé');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/reservation'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields.addAll({
        'carId': carId,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        'childSeats': childSeats.toString(),
        'additionalDrivers': additionalDrivers.toString(),
        'location': location,
        'driverEmail': driverEmail,
        'driverPhoneNumber': driverPhoneNumber,
        'documentType': passportImage != null ? 'passport' : 'cin',
      });

      request.files.add(await http.MultipartFile.fromPath(
        'permisRecto', 
        permisRectoImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      request.files.add(await http.MultipartFile.fromPath(
        'permisVerso',
        permisVersoImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      if (cinRectoImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'cinRecto', 
          cinRectoImage.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      if (cinVersoImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'cinVerso', 
          cinVersoImage.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      if (passportImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'passport', 
          passportImage.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        
        if (decodedResponse is! Map<String, dynamic>) {
          throw Exception('Format de réponse invalide');
        }

        decodedResponse['car'] ??= {
          '_id': carId,
          'brand': 'Inconnu',
          'model': 'Inconnu',
          'images': [],
        };

        return decodedResponse;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 
               errorBody['error'] ?? 
               'Échec de la réservation (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Échec de la réservation: ${e.toString()}');
    }
  }

  Future<List<dynamic>> getUserReservations() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Token non trouvé');

      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/reservation/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded is List ? decoded : [];
      } else {
        throw Exception('Échec du chargement (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Token d\'authentification non trouvé');

      final response = await http.delete(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/reservation/$reservationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 
               errorBody['error'] ?? 
               'Échec de l\'annulation (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Échec de l\'annulation: ${e.toString()}');
    }
  }
}