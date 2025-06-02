import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/seller/CampingItemSEllerViewModel.dart';
import 'package:dumum_tergo/views/seller/item/add-item-page.dart';
import 'package:dumum_tergo/views/seller/item/camping_item_card_seller.dart';
import 'package:dumum_tergo/views/user/item/filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

class CampingItemsScreenSeller extends StatefulWidget {
  const CampingItemsScreenSeller({Key? key}) : super(key: key);

  @override
  State<CampingItemsScreenSeller> createState() => _CampingItemsScreenSellerState();
}

class _CampingItemsScreenSellerState extends State<CampingItemsScreenSeller> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _searchBarOffset = 0;
  double _lastScrollPosition = 0;
  bool _isAtTop = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CampingItemsSellerViewModel>(context, listen: false).fetchCampingItems();
    });

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Changer le style de la status bar selon le thème
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }

  void _handleScroll() {
    final currentPosition = _scrollController.offset;
    final scrollDirection = currentPosition > _lastScrollPosition
        ? ScrollDirection.reverse
        : ScrollDirection.forward;
    final scrollDistance = (currentPosition - _lastScrollPosition).abs();

    setState(() {
      _isAtTop = currentPosition <= 0;

      if (scrollDirection == ScrollDirection.reverse && !_isAtTop) {
        _searchBarOffset = (_searchBarOffset - scrollDistance * 2.5).clamp(-120.0, 0.0);
      } else if (scrollDirection == ScrollDirection.forward) {
        _searchBarOffset = (_searchBarOffset + scrollDistance * 2.5).clamp(-120.0, 0.0);
      }
      _lastScrollPosition = currentPosition;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<CampingItemsSellerViewModel>(context, listen: false)
        .applyFilters(searchTerm: _searchController.text);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const FilterSheet(),
    );
  }

  void _showAddCarDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AddCampingItemPage(
          onItemAdded: () {
            Provider.of<CampingItemsSellerViewModel>(context, listen: false)
                .refreshItems();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<CampingItemsSellerViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mes annonces'),
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        systemOverlayStyle: isDarkMode 
            ? SystemUiOverlayStyle.light 
            : SystemUiOverlayStyle.dark,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                color: AppColors.primary,
                onPressed: _showAddCarDialog,
                tooltip: 'Ajouter un item',
              ),
            ],
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
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

  Widget _buildSlidingSearchBar(BuildContext context, CampingItemsSellerViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      top: _searchBarOffset,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        color: theme.cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Rechercher du matériel...',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
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
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: _showFilterSheet,
                    ),
                  ),
                ],
              ),
            ),
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
                          label: const Text('Localisation sélectionnée'),
                          backgroundColor: colorScheme.surface,
                          side: BorderSide(color: colorScheme.outline),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => viewModel.applyFilters(locationId: null),
                        ),
                      ),
                  ],
                ),
              ),
            const Divider(height: 16, thickness: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CampingItemsSellerViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.only(top: _isAtTop ? 80 : 0),
      child: _buildContentList(viewModel),
    );
  }

  Widget _buildContentList(CampingItemsSellerViewModel viewModel) {
    if (viewModel.isLoading && viewModel.filteredItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error.isNotEmpty) return _buildErrorWidget(viewModel);

    return RefreshIndicator(
      onRefresh: () => viewModel.refreshItems(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverToBoxAdapter(
              child: viewModel.filteredItems.isEmpty
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: _buildEmptyWidget(),
                    )
                  : Container(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = viewModel.filteredItems[index];
                  return CampingItemCardSeller(
                    key: ValueKey(item.id),
                    item: item,
                    onDelete: () async {
                      await viewModel.refreshItems();
                      setState(() {});
                    },
                  );
                },
                childCount: viewModel.filteredItems.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(CampingItemsSellerViewModel viewModel) {
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
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Aucun résultat trouvé'),
        ],
      ),
    );
  }
}
