// rental_search_viewmodel.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class RentalSearchViewModel with ChangeNotifier {
  String _pickupLocation = '';
  bool _returnToSameLocation = true;
  DateTime _pickupDate = DateTime.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _returnTime = const TimeOfDay(hour: 10, minute: 0);
  bool _driverAgeBetween30And65 = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _showLocationError = false;

  // Getters
  String get pickupLocation => _pickupLocation;
  bool get returnToSameLocation => _returnToSameLocation;
  DateTime get pickupDate => _pickupDate;
  DateTime get returnDate => _returnDate;
  TimeOfDay get pickupTime => _pickupTime;
  TimeOfDay get returnTime => _returnTime;
  bool get driverAgeBetween30And65 => _driverAgeBetween30And65;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get showLocationError => _showLocationError;

  // Setters
    void setPickupLocation(String result) {
    if (result.isNotEmpty) {
      _pickupLocation = result;
      _showLocationError = false; // Réinitialiser l'erreur quand la location change
      notifyListeners();
    }
  }
  void validateForm() {
    _showLocationError = _pickupLocation.isEmpty;
    notifyListeners();
  }
  void setReturnToSameLocation(bool value) {
    _returnToSameLocation = value;
    notifyListeners();
  }

  void setPickupDate(DateTime value) {
    _pickupDate = value;
    _pickupTime = TimeOfDay(hour: value.hour, minute: value.minute);
    notifyListeners();
  }

  void setReturnDate(DateTime value) {
    _returnDate = value;
    _returnTime = TimeOfDay(hour: value.hour, minute: value.minute);
    notifyListeners();
  }

  void setPickupTime(TimeOfDay value) {
    _pickupTime = value;
    notifyListeners();
  }

  void setReturnTime(TimeOfDay value) {
    _returnTime = value;
    notifyListeners();
  }

  void setDriverAgeBetween30And65(bool value) {
    _driverAgeBetween30And65 = value;
    notifyListeners();
  }

  Future<void> search() async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://dumum-tergo-backend.onrender.com/api/cars/search?'
        'location=${Uri.encodeComponent(_pickupLocation)}&'
        'startDate=${_pickupDate.toIso8601String()}&'
        'endDate=${_returnDate.toIso8601String()}'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        
        if (decoded is List) {
          _searchResults = List<Map<String, dynamic>>.from(decoded);
        } else {
          _searchResults = [];
        }
      } else {
        _searchResults = [];
      }
    } catch (e) {
      _searchResults = [];
      print('API call error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

 void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  }