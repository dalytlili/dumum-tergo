import 'package:dumum_tergo/models/camping_item.dart';
import 'package:dumum_tergo/services/api_service.dart';
import 'package:flutter/foundation.dart';

class CampingItemsViewModel with ChangeNotifier {
  List<CampingItem> _items = [];
  List<CampingItem> _filteredItems = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _error = '';
  ApiService? _apiService;
  String? _currentLocationId;
  int _currentPage = 1;
  bool _hasMore = true;

  // Filtres
  String _currentSearch = '';
  String _currentCategory = 'All';
  String _currentType = 'All';
  String _currentCondition = 'All';

  List<CampingItem> get items => _items;
  List<CampingItem> get filteredItems => _filteredItems;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get error => _error;
  String get currentCategory => _currentCategory;
  String get currentType => _currentType;
  String get currentCondition => _currentCondition;
  String? get currentLocationId => _currentLocationId;

  CampingItemsViewModel({required ApiService? apiService}) : _apiService = apiService;

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
    _currentPage = 1;
    _hasMore = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _apiService!.get('/camping/items?page=$_currentPage');
      
      _items = (response['data'] as List)
          .map((item) => CampingItem.fromJson(item))
          .toList();
      
      _hasMore = response['hasMore'] ?? false;
      _filteredItems = List.from(_items);
      applyFilters();
    } catch (e) {
      _error = 'Failed to load camping items: ${e.toString()}';
      if (kDebugMode) print('Error fetching items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreCampingItems() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final response = await _apiService!.get('/camping/items?page=$_currentPage');
      
      final newItems = (response['data'] as List)
          .map((item) => CampingItem.fromJson(item))
          .toList();
      
      _items.addAll(newItems);
      _hasMore = response['hasMore'] ?? false;
      applyFilters();
    } catch (e) {
      _currentPage--;
      _error = 'Failed to load more items: ${e.toString()}';
      if (kDebugMode) print('Error loading more items: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void applyFilters({
    String? searchTerm,
    String? category,
    String? type,
    String? condition,
    String? locationId,
  }) {
    _currentSearch = searchTerm?.toLowerCase() ?? _currentSearch;
    _currentCategory = category ?? _currentCategory;
    _currentType = type ?? _currentType;
    _currentCondition = condition ?? _currentCondition;
    _currentLocationId = locationId ?? _currentLocationId;

    _filteredItems = _items.where((item) {
      final matchesSearch = _currentSearch.isEmpty || 
          item.name.toLowerCase().contains(_currentSearch) || 
          item.description.toLowerCase().contains(_currentSearch);
      
      final matchesCategory = _currentCategory == 'All' || 
          item.category.toLowerCase() == _currentCategory.toLowerCase();
      
      final matchesType = _currentType == 'All' || 
          (_currentType == 'Sale' && item.isForSale) || 
          (_currentType == 'Rent' && item.isForRent);
      
      final matchesCondition = _currentCondition == 'All' || 
          (item.condition?.toLowerCase() == _currentCondition.toLowerCase());

      final matchesLocation = _currentLocationId == null || 
          item.location?.id == _currentLocationId;

      return matchesSearch && matchesCategory && matchesType && matchesCondition && matchesLocation;
    }).toList();

    _filteredItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> refreshItems() async {
    await fetchCampingItems();
  }
}