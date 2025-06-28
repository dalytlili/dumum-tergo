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
  String _currentType = 'All';
  String _currentCondition = 'All';

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
      _error = 'Service API non initialisé';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _apiService!.getseller('/camping/vendor/items');
      
      // Si la réponse est une Map (JSON)
      if (response is Map<String, dynamic>) {
        if (response['success'] == false) {
          _error = response['error'] ?? 'Erreur lors du chargement des articles';
        } else {
          _items = (response['data'] as List)
              .map((item) => CampingItem.fromJson(item))
              .toList();
          applyFilters();
        }
      }
      // Si la réponse n'est pas une Map (erreur directe)
      else {
        throw Exception('Format de réponse inattendu');
      }
    } catch (e) {
      // Gestion spécifique des erreurs 403
      if (e.toString().contains('403')) {
        _error = 'Votre abonnement n\'est pas actif. Veuillez souscrire à un abonnement !';
      } else {
        _error = 'Échec du chargement des articles de camping: ${e.toString().replaceAll('Exception: API request failed: Exception: ', '')}';
      }
      
      if (kDebugMode) print('Erreur lors du chargement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
// Ajoutez ces getters pour les options de filtres
List<String> get categoryOptions => ['All', 'Tente', 'Sac de couchage', 'Réchaud', 'Lampe', 'Autre'];
List<String> get typeOptions => ['All', 'Sale', 'Rent'];
List<String> get conditionOptions => ['All', 'neuf', 'occasion'];

// Modifiez la méthode applyFilters
void applyFilters({
  String searchTerm = '',
  String? category,
  String? type,
  String? condition,
  String? locationId,
}) {
  _currentSearch = searchTerm.toLowerCase();
  _currentCategory = category ?? _currentCategory;
  _currentType = type ?? _currentType;
  _currentCondition = condition ?? _currentCondition;
  _currentLocationId = locationId ?? _currentLocationId;

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