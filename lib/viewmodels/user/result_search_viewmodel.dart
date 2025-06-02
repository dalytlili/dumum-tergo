// result_search_viewmodel.dart
import 'package:flutter/material.dart';

class ResultSearchViewModel with ChangeNotifier {
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  List<dynamic> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  Future<void> loadSearchResults(List<dynamic> results) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500)); // Simule un chargement
    
    _searchResults = results;
    _isLoading = false;
    notifyListeners();
  }
}