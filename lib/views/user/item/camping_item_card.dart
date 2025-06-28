import 'package:dumum_tergo/models/camping_item.dart';
import 'package:dumum_tergo/views/user/item/camping_item_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CampingItemCard extends StatelessWidget {
  final CampingItem item;
  final VoidCallback? onTap;

  const CampingItemCard({
    Key? key,
    required this.item,
    this.onTap,
  }) : super(key: key);

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min';
    if (difference.inHours < 24) return '${difference.inHours} h';
    if (difference.inDays < 7) return '${difference.inDays} j';
    
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = theme.hintColor;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.1) : Colors.grey.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.all(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CampingItemDetailScreen(item: item),
            ),
          );
        },
        child: Stack(
          children: [
            // Card background
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    spreadRadius: 0.5,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image with modern cut
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      height: 120, // Optimized for grid
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Image.network(
                            'https://res.cloudinary.com/dcs2edizr/image/upload/${item.images.isNotEmpty ? item.images[0] : 'default.jpg'}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 30,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                          // Gradient overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    cardColor.withOpacity(0.4),
                                    cardColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          item.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Price (compact version)
                        _buildCompactPrice(context),
                        
                        const SizedBox(height: 8),
                        
                        // Location and date
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                               item.location.title,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: secondaryTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeAgo(item.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryTextColor,
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

            // Top badges
            Positioned(
              top: 8,
              left: 8,
              child: Wrap(
                spacing: 4,
                direction: Axis.vertical,
                children: [
                  if (item.isForSale)
                    _buildSmallBadge(
                      context,
                      'Vente',
                      Icons.sell,
                      Colors.blue,
                    ),
                  if (item.isForRent)
                    _buildSmallBadge(
                      context,
                      'Location',
                      Icons.calendar_today,
                      Colors.green,
                    ),
                ],
              ),
            ),

            // Vendor avatar - Ajouté ici
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cardColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    'https://res.cloudinary.com/dcs2edizr/image/upload/${item.vendor.image ?? 'default.jpg'}',
                  ),
                  onBackgroundImageError: (_, __) {},
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: item.vendor.image == null
                      ? Text(
                          item.vendor.businessName.substring(0, 1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(BuildContext context, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPrice(BuildContext context) {
    final theme = Theme.of(context);
    
    if (item.isForSale && item.isForRent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceChip(
            '${item.price.toStringAsFixed(0)} TND',
            Colors.blue,
          ),
          const SizedBox(height: 4),
          _buildPriceChip(
            '${item.rentalPrice.toStringAsFixed(0)} TND/j',
            Colors.green,
          ),
        ],
      );
    } else if (item.isForSale) {
      return _buildPriceChip(
        '${item.price.toStringAsFixed(0)} TND',
        Colors.blue,
      );
    } else if (item.isForRent) {
      return _buildPriceChip(
        '${item.rentalPrice.toStringAsFixed(0)} TND/j',
        Colors.green,
      );
    }
    return const SizedBox();
  }

  Widget _buildPriceChip(String price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        price,
 
      ),
    );
  }
}