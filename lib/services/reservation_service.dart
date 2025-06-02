import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
    required String driverFirstName,
    required String driverLastName,
    required String driverBirthDate,
    required String driverPhoneNumber,
    required String driverCountry,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Token d\'authentification non trouvé');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/reservation'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "carId": carId,
          "startDate": startDate.toIso8601String(),
          "endDate": endDate.toIso8601String(),
          "childSeats": childSeats,
          "additionalDrivers": additionalDrivers,
          "location": location,
          "driverEmail": driverEmail,
          "driverFirstName": driverFirstName,
          "driverLastName": driverLastName,
          "driverBirthDate": driverBirthDate,
          "driverPhoneNumber": driverPhoneNumber,
          "driverCountry": driverCountry,
        }),
      );

      if (response.statusCode == 201) {
        if (response.body.isEmpty) {
          throw Exception('Réponse vide du serveur');
        }

        final decodedResponse = json.decode(response.body);
        
        if (decodedResponse is! Map<String, dynamic>) {
          throw Exception('Format de réponse invalide');
        }

        // Gestion du cas où car est null
        if (decodedResponse['car'] == null) {
          decodedResponse['car'] = {
            '_id': carId,
            'brand': 'Inconnu',
            'model': 'Inconnu',
            'images': [],
          };
        }

        return decodedResponse;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Échec de la réservation (${response.statusCode})');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur réseau: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Erreur de format: ${e.message}');
    } catch (e) {
      throw Exception('Échec de la réservation: $e');
    }
  }

  Future<List<dynamic>> getUserReservations() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Token d\'authentification non trouvé');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/reservation/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        if (decoded is! List) {
          throw Exception('Format de réponse invalide');
        }

        // Nettoyage des données pour gérer les valeurs null
        return decoded.map((reservation) {
          if (reservation['car'] == null) {
            reservation['car'] = {
              '_id': 'inconnu',
              'brand': 'Inconnu',
              'model': 'Inconnu',
              'images': [],
            };
          }
          return reservation;
        }).toList();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Échec du chargement (${response.statusCode})');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur réseau: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Erreur de format: ${e.message}');
    } catch (e) {
      throw Exception('Échec du chargement: $e');
    }
  }
}