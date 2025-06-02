// filter_sheet.dart
import 'package:dumum_tergo/views/seller/car/search-location.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dumum_tergo/viewmodels/user/camping_items_viewmodel.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({Key? key}) : super(key: key);

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
    final viewModel = Provider.of<CampingItemsViewModel>(context, listen: false);
    if (viewModel.currentLocationId != null) {
      // Vous devrez peut-être charger le nom de la localisation ici
      _locationController.text = "Localisation sélectionnée";
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CampingItemsViewModel>(context, listen: false);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              'All', 'tente', 'Sac de couchage', 'réchaud', 'Lampe', 'Autre'
            ].map((category) {
              return FilterChip(
                label: Text(category),
                selected: viewModel.currentCategory == category,
                onSelected: (selected) {
                  viewModel.applyFilters(category: selected ? category : 'All');
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
                selected: viewModel.currentType == option.value,
                onSelected: (selected) {
                  viewModel.applyFilters(type: selected ? option.value : 'All');
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
                selected: viewModel.currentCondition == option.value,
                onSelected: (selected) {
                  viewModel.applyFilters(condition: selected ? option.value : 'All');
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _locationController.clear();
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final String value;

  _FilterOption({required this.label, required this.value});
}