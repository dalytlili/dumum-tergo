import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:dumum_tergo/models/camping_item.dart';
import 'package:dumum_tergo/views/seller/item/camping_item_detail_seller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class CampingItemCardSellerViewModel with ChangeNotifier {
  final CampingItem item;
  final Function()? onDeleteCallback;
  final Function()? onEditCallback;
  final Function()? onMarkAsSoldCallback;

  CampingItemCardSellerViewModel({
    required this.item,
    this.onDeleteCallback,
    this.onEditCallback,
    this.onMarkAsSoldCallback,
  });

   Future<void> deleteItem(BuildContext context) async {
    // Afficher la boîte de dialogue de confirmation
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet article ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmDelete) return;

    final token = await storage.read(key: 'seller_token');
    final url = Uri.parse('https://dumum-tergo-backend.onrender.com/api/camping/items/${item.id}');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article supprimé avec succès')),
        );
        onDeleteCallback?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la suppression (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  void editItem() {
    onEditCallback?.call();
    notifyListeners();
  }

  void markAsSold() {
    onMarkAsSoldCallback?.call();
    notifyListeners();
  }

  String formatTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(item.createdAt);

    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} j';

    return DateFormat('dd/MM/yyyy').format(item.createdAt);
  }

void navigateToDetail(BuildContext context) async {
  // Afficher un indicateur de chargement
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final itemDetails = await fetchItemDetails(item.id);
    Navigator.pop(context); // Fermer l'indicateur de chargement
    
    if (itemDetails != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            body: CampingItemDetailSellerScreen(item: itemDetails),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les données reçues sont invalides'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur technique: ${e.toString()}'),
        duration: Duration(seconds: 2),
      ),
    );
    print('Detailed Error: $e');
  }
}

  // Dans CampingItemCardSellerViewModel
Future<CampingItem?> fetchItemDetails(String itemId) async {
  final token = await storage.read(key: 'seller_token');

  try {
    final response = await http.get(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/camping/items/$itemId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    print('API Response - Status: ${response.statusCode}');
    print('API Response - Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final jsonData = jsonDecode(response.body);
        // Handle both direct item response and data wrapper
        if (jsonData is Map<String, dynamic>) {
          if (jsonData.containsKey('data')) {
            return CampingItem.fromJson(jsonData['data'] as Map<String, dynamic>);
          } else {
            return CampingItem.fromJson(jsonData);
          }
        }
        return null;
      } catch (e) {
        print('JSON Parsing Error: $e');
        return null;
      }
    } else {
      print('API Error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Network Error: $e');
    return null;
  }
}


}
