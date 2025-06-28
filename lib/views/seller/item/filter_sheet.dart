import 'package:dumum_tergo/viewmodels/seller/CampingItemSEllerViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({Key? key}) : super(key: key);

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late TextEditingController _locationController;
  late String _selectedCategory;
  late String _selectedType;
  late String _selectedCondition;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<CampingItemsSellerViewModel>(context, listen: false);
    
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
    final viewModel = Provider.of<CampingItemsSellerViewModel>(context, listen: false);
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
          const Center(
            child: Text(
              'Filtrer les résultats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _selectedType = 'All';
                      _selectedCondition = 'All';
                    });
                    _applyFiltersImmediately();
                    Navigator.pop(context);
                  },
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text('Fermer'),
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