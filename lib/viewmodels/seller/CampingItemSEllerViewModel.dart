// camping_items_viewmodel.dart
import 'package:dumum_tergo/models/camping_item.dart';
import 'package:dumum_tergo/services/api_service.dart';
import 'package:flutter/foundation.dart';

class CampingItemsSellerViewModel with ChangeNotifier {
  List<CampingItem> _items = [];
  List<CampingItem> _filteredItems = [];
  bool _isLoading = false;
  String _error = '';
  ApiService? _apiService;
  String? _currentLocationId;

  // Filtres
  String _currentSearch = '';
  String _currentCategory = 'All';
  String _currentType = 'All'; // 'All', 'Sale', 'Rent'
  String _currentCondition = 'All'; // 'All', 'neuf', 'occasion'

  // Getters
  List<CampingItem> get items => _items;
  List<CampingItem> get filteredItems => _filteredItems;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get currentCategory => _currentCategory;
  String get currentType => _currentType;
  String get currentCondition => _currentCondition;
  String? get currentLocationId => _currentLocationId;

  CampingItemsSellerViewModel({required ApiService? apiService}) : _apiService = apiService;

  void updateApiService(ApiService apiService) {
    _apiService = apiService;
  }

  Future<void> fetchCampingItems() async {
    if (_apiService == null) {
      _error = 'API Service not initialized';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _apiService!.getseller('/camping/vendor/items');
      
      _items = (response['data'] as List)
          .map((item) => CampingItem.fromJson(item))
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _filteredItems = List.from(_items);
      applyFilters(
        searchTerm: _currentSearch,
        category: _currentCategory,
        type: _currentType,
        condition: _currentCondition,
        locationId: _currentLocationId,
      );
    } catch (e) {
      _error = 'Failed to load camping items: ${e.toString()}';
      if (kDebugMode) print('Error fetching items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyFilters({
    String searchTerm = '',
    String category = 'All',
    String type = 'All',
    String condition = 'All',
    String? locationId,
  }) {
    _currentSearch = searchTerm.toLowerCase();
    _currentCategory = category;
    _currentType = type;
    _currentCondition = condition;
    _currentLocationId = locationId;

    _filteredItems = _items.where((item) {
      // Filtre par recherche
      final matchesSearch = _currentSearch.isEmpty || 
          item.name.toLowerCase().contains(_currentSearch) || 
          item.description.toLowerCase().contains(_currentSearch);
      
      // Filtre par catégorie
      final matchesCategory = _currentCategory == 'All' || 
          item.category.toLowerCase() == _currentCategory.toLowerCase();
      
      // Filtre par type (vente/location)
      final matchesType = _currentType == 'All' || 
          (_currentType == 'Sale' && item.isForSale) || 
          (_currentType == 'Rent' && item.isForRent);
      
      // Filtre par condition
      final matchesCondition = _currentCondition == 'All' || 
          (item.condition?.toLowerCase() == _currentCondition.toLowerCase());

      // Filtre par localisation
      final matchesLocation = _currentLocationId == null || 
          item.location?.id == _currentLocationId;

      return matchesSearch && matchesCategory && matchesType && matchesCondition && matchesLocation;
    }).toList();

    // Maintenir le tri après filtrage
    _filteredItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    notifyListeners();
  }

Future<void> refreshItems() async {
  _isLoading = true;
  notifyListeners();
  
  try {
    await fetchCampingItems();
  } catch (e) {
    _error = 'Failed to refresh items: ${e.toString()}';
    if (kDebugMode) print('Error refreshing items: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  
}