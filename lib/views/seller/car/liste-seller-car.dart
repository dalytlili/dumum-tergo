import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/seller/liste_car_viewmodel.dart';
import 'package:dumum_tergo/views/seller/car/add-car-rental-page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ListeSellerCar extends StatefulWidget {
  final Function(Map<String, dynamic>) onCarSelected;

  const ListeSellerCar({Key? key, required this.onCarSelected}) : super(key: key);

  @override
  State<ListeSellerCar> createState() => _ListeSellerCarState();
}

class _ListeSellerCarState extends State<ListeSellerCar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final currentOffset = _scrollController.offset;
    if (currentOffset > _lastScrollOffset && currentOffset > 50) {
      // Scrolling down and past threshold
      if (_showSearchBar) {
        setState(() {
          _showSearchBar = false;
        });
      }
    } else if (currentOffset < _lastScrollOffset || currentOffset <= 50) {
      // Scrolling up or at top
      if (!_showSearchBar) {
        setState(() {
          _showSearchBar = true;
        });
      }
    }
    _lastScrollOffset = currentOffset;
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
        child: AddCarRentalPage(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => ListeCarViewModel()..fetchCarsFromVendor(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Liste des voitures',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          centerTitle: true,
          elevation: 0,
                    backgroundColor: isDarkMode ? Colors.black : Colors.white,

          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _showAddCarDialog,
              tooltip: 'Ajouter une voiture',
            ),
          ],
        ),
        body: Consumer<ListeCarViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _showSearchBar ? null : 0,
                  child: _showSearchBar
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Rechercher par matricule...',
                              prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        viewModel.searchByRegistrationNumber('');
                                        _searchFocusNode.unfocus();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onChanged: (value) {
                              viewModel.searchByRegistrationNumber(value);
                            },
                          ),
                        )
                      : null,
                ),
           
                if (viewModel.isLoading && viewModel.searchResults.isEmpty)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  )
                else if (viewModel.error != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            viewModel.error!,
                            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (viewModel.searchResults.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.car_rental, size: 48, color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun véhicule trouvé',
                            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await viewModel.fetchCarsFromVendor();
                      },
                      color: AppColors.primary,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.searchResults.length,
                        itemBuilder: (context, index) {
                          return _buildCarCard(viewModel.searchResults[index], context);
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }



  Widget _buildCarCard(Map<String, dynamic> car, BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    const String baseUrl = "https://res.cloudinary.com/dcs2edizr/image/upload/";
    List<String> images = (car['images'] is List)
        ? (car['images'] as List).map((image) => "$baseUrl$image").toList()
        : [];

    return GestureDetector(
      onTap: () => widget.onCarSelected(car),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  images[0],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${car['brand']} ${car['model']}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildFeatureRow(
                              Icons.directions_car,
                              '${car['registrationNumber']}',
                              AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            _buildFeatureRow(
                              Icons.location_on,
                              '${car['location']['title']}',
                              isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${car['pricePerDay']}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'TND/jour',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}