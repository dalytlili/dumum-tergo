import 'dart:convert';
import 'package:dumum_tergo/services/WebSocketService.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentMethod {
  final String id;
  final String name;
  final bool isSelected;

  PaymentMethod({
    required this.id,
    required this.name,
    this.isSelected = false,
  });

  PaymentMethod copyWith({
    String? id,
    String? name,
    bool? isSelected,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class PaymentViewModel with ChangeNotifier {
  PaymentMethod _paymentMethod = PaymentMethod(id: '1', name: 'Flouci');
  double? _amount;
  bool _isLoading = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final WebSocketService _webSocketService = WebSocketService();
  final Function(BuildContext)? onPaymentSuccess;

  PaymentMethod get paymentMethod => _paymentMethod;
  bool get isLoading => _isLoading;
  double? get amount => _amount;

  PaymentViewModel({this.onPaymentSuccess}) {
    _webSocketService.connect();
    _listenToWebSocket();
  }

  void _listenToWebSocket() {
  debugPrint('Nouvelle connexion WebSocket'); // Affiche un message lors de la connexion

  _webSocketService.stream.listen((message) {
    final data = json.decode(message);
    if (data['event'] == 'payment_success') {
      debugPrint('ok'); // Affiche "ok" si le paiement est réussi
      debugPrint('Paiement réussi pour le vendeur: ${data['vendorId']}');
      debugPrint('ID de paiement: ${data['paymentId']}');
      if (onPaymentSuccess != null) {
        // onPaymentSuccess!(context);
      }
    } else {
      debugPrint('no'); // Affiche "no" si l'événement n'est pas "payment_success"
    }
  }, onError: (error) {
    debugPrint('Erreur WebSocket: $error');
  }, onDone: () {
    debugPrint('Connexion WebSocket fermée');
  });
}

  void selectPaymentMethod() {
    _paymentMethod = _paymentMethod.copyWith(isSelected: true);
    notifyListeners();
  }

  Future<void> payement(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
    String? token = await _storage.read(key: 'seller_token');
    debugPrint('Token récupéré: $token'); // Log pour vérifier le token

    if (token == null) throw Exception('Token not found');

      final response = await http.post(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/initiate-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': _amount,
        }),
      );

      debugPrint('Statut de la réponse: ${response.statusCode}');
      debugPrint('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('Réponse JSON: $responseData');

        if (responseData['result'] != null && responseData['result']['link'] != null) {
          final String paymentLink = responseData['result']['link'];
          debugPrint('Lien de paiement: $paymentLink');

          if (await canLaunch(paymentLink)) {
            await launch(paymentLink);
          } else {
            throw Exception('Impossible d\'ouvrir le lien de paiement');
          }
        } else {
          throw Exception('Lien de paiement non trouvé dans la réponse');
        }
      } else {
        debugPrint('Erreur: ${response.statusCode}');
        throw Exception('Erreur lors du paiement');
      }
    } catch (e) {
      debugPrint('Erreur lors du paiement: $e');
      throw Exception('Erreur lors du paiement');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setAmount(String priceText) {
    final RegExp regExp = RegExp(r'\d+');
    final String? match = regExp.stringMatch(priceText);

    if (match != null) {
      _amount = double.parse(match);
    } else {
      _amount = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }
}