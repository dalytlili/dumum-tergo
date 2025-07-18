import 'package:dumum_tergo/views/seller/car/search-location.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dumum_tergo/viewmodels/user/camping_items_viewmodel.dart';

class FilterSheet1 extends StatefulWidget {
  const FilterSheet1({Key? key}) : super(key: key);

  @override
  State<FilterSheet1> createState() => _FilterSheet1State();
}

class _FilterSheet1State extends State<FilterSheet1> {
  late TextEditingController _locationController;
  late String _selectedCategory;
  late String _selectedType;
  late String _selectedCondition;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<CampingItemsViewModel>(context, listen: false);
    
    _locationController = TextEditingController();
    _selectedCategory = viewModel.currentCategory;
    _selectedType = viewModel.currentType;
    _selectedCondition = viewModel.currentCondition;
    
    if (viewModel.currentLocationId != null) {
      _locationController.text = "Localisation sélectionnée";
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _applyFiltersImmediately() {
    final viewModel = Provider.of<CampingItemsViewModel>(context, listen: false);
    viewModel.applyFilters(
      category: _selectedCategory,
      type: _selectedType,
      condition: _selectedCondition,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Filtrer les résultats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          
          // Champ de recherche de localisation
          const Text('Localisation', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SearchLocationField(
            controller: _locationController,
          ),
          
          const SizedBox(height: 16),
          
          // Filtre par catégorie
          const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              'All', 'Tente', 'Sac de couchage', 'Réchaud', 'Lampe', 'Autre'
            ].map((category) {
              return FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                selectedColor: colorScheme.primary,
                checkmarkColor: colorScheme.onPrimary,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : 'All';
                  });
                  _applyFiltersImmediately();
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Filtre par type
          const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              _FilterOption(label: 'Tous', value: 'All'),
              _FilterOption(label: 'Vente', value: 'Sale'),
              _FilterOption(label: 'Location', value: 'Rent'),
            ].map((option) {
              return FilterChip(
                label: Text(option.label),
                selected: _selectedType == option.value,
                selectedColor: colorScheme.primary,
                checkmarkColor: colorScheme.onPrimary,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? option.value : 'All';
                  });
                  _applyFiltersImmediately();
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Filtre par condition
          const Text('Condition', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              _FilterOption(label: 'Tous', value: 'All'),
              _FilterOption(label: 'Neuf', value: 'neuf'),
              _FilterOption(label: 'Occasion', value: 'occasion'),
            ].map((option) {
              return FilterChip(
                label: Text(option.label),
                selected: _selectedCondition == option.value,
                selectedColor: colorScheme.primary,
                checkmarkColor: colorScheme.onPrimary,
                onSelected: (selected) {
                  setState(() {
                    _selectedCondition = selected ? option.value : 'All';
                  });
                  _applyFiltersImmediately();
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _selectedType = 'All';
                      _selectedCondition = 'All';
                      _locationController.clear();
                    });
                    final viewModel = Provider.of<CampingItemsViewModel>(context, listen: false);
                    viewModel.applyFilters(
                      category: 'All',
                      type: 'All',
                      condition: 'All',
                      locationId: null,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      )
      ,
    );
  }
}

class _FilterOption {
  final String label;
  final String value;

  _FilterOption({required this.label, required this.value});
}