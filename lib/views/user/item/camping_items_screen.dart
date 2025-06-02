import 'dart:ui';

import 'package:dumum_tergo/viewmodels/user/camping_items_viewmodel.dart';
import 'package:dumum_tergo/views/user/item/camping_item_card.dart';
import 'package:dumum_tergo/views/user/item/filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

class CampingItemsScreen extends StatefulWidget {
  const CampingItemsScreen({Key? key}) : super(key: key);

  @override
  State<CampingItemsScreen> createState() => _CampingItemsScreenState();
}

class _CampingItemsScreenState extends State<CampingItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _searchBarOffset = 0;
  double _lastScrollPosition = 0;
  bool _isAtTop = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CampingItemsViewModel>(context, listen: false).fetchCampingItems();
    });
    _searchController.addListener(_onSearchChanged);
    
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final currentPosition = _scrollController.offset;
    final scrollDirection = currentPosition > _lastScrollPosition 
        ? ScrollDirection.reverse 
        : ScrollDirection.forward;
    final scrollDistance = (currentPosition - _lastScrollPosition).abs();

    setState(() {
      _isAtTop = currentPosition <= 0;
      
      if (scrollDirection == ScrollDirection.reverse && !_isAtTop) {
        _searchBarOffset = (_searchBarOffset - scrollDistance * 2.5)
            .clamp(-120.0, 0.0);
      } else if (scrollDirection == ScrollDirection.forward) {
        _searchBarOffset = (_searchBarOffset + scrollDistance * 2.5)
            .clamp(-120.0, 0.0);
      }
      _lastScrollPosition = currentPosition;
    });

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = maxScroll - currentScroll;

    if (delta < 100 && 
        !Provider.of<CampingItemsViewModel>(context, listen: false).isLoadingMore &&
        Provider.of<CampingItemsViewModel>(context, listen: false).hasMore) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    await Provider.of<CampingItemsViewModel>(context, listen: false).loadMoreCampingItems();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<CampingItemsViewModel>(context, listen: false)
        .applyFilters(searchTerm: _searchController.text);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => const FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CampingItemsViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              _buildContent(viewModel),
              _buildSlidingSearchBar(context, viewModel),
            ],
          ),
        );
      },
    );
  }

Widget _buildSlidingSearchBar(BuildContext context, CampingItemsViewModel viewModel) {
  final theme = Theme.of(context);

  return Positioned(
    top: _searchBarOffset,
    left: 0,
    right: 0,
    child: Material(
      elevation: 6,
      color: Colors.white, // Fond complètement transparent
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Effet de flou
          child: Container(
            decoration: BoxDecoration(
              //color: theme.cardColor.withOpacity(0.7), // Fond semi-transparent
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  
                  child: Row(
                    children: [
                      
                      // Champ de recherche
                      Expanded(
                        child: Container(
                           decoration: BoxDecoration(
              border: Border.all(
               color:  Colors.grey.shade300
              ),
              borderRadius: BorderRadius.circular(8),
            ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: theme.colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Rechercher du matériel...',
                              hintStyle: TextStyle(color: theme.hintColor),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              prefixIcon: Icon(Icons.search, color: theme.hintColor),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, size: 20, color: theme.hintColor),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged();
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bouton filtre
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.filter_list, color: theme.colorScheme.onPrimary),
                          onPressed: _showFilterSheet,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filtres sélectionnés (chips)
                if (viewModel.currentCategory != 'All' ||
                    viewModel.currentType != 'All' ||
                    viewModel.currentCondition != 'All')
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        if (viewModel.currentLocationId != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text('Localisation sélectionnée',
                                  style: TextStyle(color: theme.colorScheme.onSurface)),
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide(color: theme.dividerColor),
                              deleteIcon: Icon(Icons.close, size: 18, color: theme.hintColor),
                              onDeleted: () => viewModel.applyFilters(locationId: null),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}


  Widget _buildContent(CampingItemsViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.only(top: _isAtTop ? 72 : 0),
      child: _buildContentList(viewModel),
    );
  }

Widget _buildContentList(CampingItemsViewModel viewModel) {
  if (viewModel.isLoading && !viewModel.isLoadingMore) {
    return const Center(child: CircularProgressIndicator());
  }
  
  if (viewModel.error.isNotEmpty) return _buildErrorWidget(viewModel);
  if (viewModel.filteredItems.isEmpty) return _buildEmptyWidget();
  
  return LayoutBuilder(
    builder: (context, constraints) {
      // Calcul dynamique du nombre de colonnes en fonction de la largeur de l'écran
      final crossAxisCount = constraints.maxWidth > 600 
          ? 3 
          : 2; // 3 colonnes pour les grands écrans, 2 pour les petits
      
      // Ajustement dynamique du childAspectRatio
      final childAspectRatio = constraints.maxWidth > 400 
          ? 0.55
          : 0.48;
      
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) => true,
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          onRefresh: () => viewModel.refreshItems(),
          child: Stack(
            children: [
              GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: viewModel.filteredItems.length + (viewModel.hasMore ? 1 : 0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  if (index >= viewModel.filteredItems.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final item = viewModel.filteredItems[index];
                  return CampingItemCard(item: item);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildErrorWidget(CampingItemsViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            viewModel.error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.fetchCampingItems(),
            child: Text('Réessayer', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: 16),
          Text('Aucun résultat trouvé', style: TextStyle(color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}