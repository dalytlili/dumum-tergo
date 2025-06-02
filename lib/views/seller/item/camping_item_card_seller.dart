import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dumum_tergo/models/camping_item.dart';
import 'package:dumum_tergo/viewmodels/seller/camping_item_card_seller_viewmodel.dart';
import 'package:dumum_tergo/views/seller/item/add-item-page.dart';

class CampingItemCardSeller extends StatelessWidget {
  final CampingItem item;
  final Function()? onDelete;
  final Function()? onEdit;
  final Function()? onMarkAsSold;

  const CampingItemCardSeller({
    super.key,
    required this.item,
    this.onDelete,
    this.onEdit,
    this.onMarkAsSold,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CampingItemCardSellerViewModel(
        item: item,
        onDeleteCallback: onDelete,
        onEditCallback: () => _openEditPage(context),
        onMarkAsSoldCallback: onMarkAsSold,
      ),
      child: Consumer<CampingItemCardSellerViewModel>(
        builder: (context, viewModel, child) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
            elevation: 1,
            color: isDarkMode ? Colors.grey[850] : Colors.white, // Couleur de fond dynamique
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.black12,
              highlightColor: Colors.transparent,
              onTap: () => viewModel.navigateToDetail(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageStack(context, viewModel),
                  _buildItemDetails(viewModel, isDarkMode),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openEditPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCampingItemPage(
          itemToEdit: item,
          onItemAdded: onEdit,
        ),
      ),
    );
  }

  Stack _buildImageStack(BuildContext context, CampingItemCardSellerViewModel viewModel) {
    return Stack(
      children: [
        _buildItemImage(),
        _buildBadges(),
        _buildPopupMenu(context, viewModel),
      ],
    );
  }

  ClipRRect _buildItemImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey[200],
        child: Image.network(
          'https://res.cloudinary.com/dcs2edizr/image/upload/${item.images.isNotEmpty ? item.images[0] : 'default.jpg'}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  Positioned _buildBadges() {
    return Positioned(
      top: 8,
      left: 8,
      child: Row(
        children: [
          if (item.isForSale) _buildBadge('À vendre', Colors.blue),
          if (item.isForRent) _buildBadge('À louer', Colors.green),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Positioned _buildPopupMenu(BuildContext context, CampingItemCardSellerViewModel viewModel) {
    return Positioned(
      top: 0,
      right: 0,
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: Colors.grey[700]),
        onSelected: (value) => _handleMenuSelection(value, context, viewModel),
        itemBuilder: (context) => _buildMenuItems(),
      ),
    );
  }

  void _handleMenuSelection(String value, BuildContext context, CampingItemCardSellerViewModel viewModel) {
    switch (value) {
      case 'delete':
        viewModel.deleteItem(context);
        break;
      case 'edit':
        viewModel.editItem();
        break;
    }
  }

  List<PopupMenuItem<String>> _buildMenuItems() {
    return [
      const PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text('Modifier'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 20, color: Colors.red),
            SizedBox(width: 8),
            Text('Supprimer'),
          ],
        ),
      ),
    ];
  }

  Padding _buildItemDetails(CampingItemCardSellerViewModel viewModel, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.black, // Couleur dynamique
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildPriceInfo(),
          const SizedBox(height: 8),
          _buildLocationInfo(),
          const SizedBox(height: 4),
          _buildTimeInfo(viewModel),
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.isForSale && item.isForRent) ...[
          _buildPriceRow(Icons.sell, Colors.blue, '${item.price.toStringAsFixed(0)} TND'),
          const SizedBox(height: 4),
          _buildPriceRow(Icons.calendar_today, Colors.green, '${item.rentalPrice.toStringAsFixed(0)} TND/jour'),
        ] else if (item.isForSale) ...[
          _buildPriceRow(Icons.sell, Colors.blue, '${item.price.toStringAsFixed(0)} TND'),
        ] else if (item.isForRent) ...[
          _buildPriceRow(Icons.calendar_today, Colors.green, '${item.rentalPrice.toStringAsFixed(0)} TND/jour'),
        ],
      ],
    );
  }

  Widget _buildPriceRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            item.location.title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(CampingItemCardSellerViewModel viewModel) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          viewModel.formatTimeAgo(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
