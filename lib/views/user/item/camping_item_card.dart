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
    if (difference.inMinutes < 60) return 'il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} j';
    
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = theme.hintColor;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.1);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ?? () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                CampingItemDetailScreen(item: item),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: Image.network(
                      'https://res.cloudinary.com/dcs2edizr/image/upload/${item.images.isNotEmpty ? item.images[0] : 'default.jpg'}',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
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
                          size: 40,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                ),

                // Badges
              Positioned(
  top: 2,
  left: 8,
  child: Column(
                    spacing: 4,
                    children: [
                      if (item.isForSale)
                        _buildBadge(
                          context,
                          'À vendre',
                          Icons.sell,
                          Colors.blue,
                        ),
                      if (item.isForRent)
                        _buildBadge(
                          context,
                          'À louer',
                          Icons.calendar_today,
                          Colors.green,
                        ),
                    ],
                  ),
                ),

                // Vendor avatar
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
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price section
                  _buildPriceSection(context),
                  
                  const SizedBox(height: 12),
                  
                  // Location and time row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
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
                      const Spacer(),
                  
                    ],
                  ),
                                    const SizedBox(height: 12),

                  Row(
                                        children: [
                        Icon(
                        Icons.access_time,
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
                                        ]
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    final theme = Theme.of(context);
    
    if (item.isForSale && item.isForRent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceRow(
            context,
            '${item.price.toStringAsFixed(0)} TND',
            Icons.sell,
            Colors.blue,
          ),
          const SizedBox(height: 4),
          _buildPriceRow(
            context,
            '${item.rentalPrice.toStringAsFixed(0)} TND/jour',
            Icons.calendar_today,
            Colors.green,
          ),
        ],
      );
    } else if (item.isForSale) {
      return _buildPriceRow(
        context,
        '${item.price.toStringAsFixed(0)} TND',
        Icons.sell,
        Colors.blue,
      );
    } else if (item.isForRent) {
      return _buildPriceRow(
        context,
        '${item.rentalPrice.toStringAsFixed(0)} TND/jour',
        Icons.calendar_today,
        Colors.green,
      );
    }
    return const SizedBox();
  }

  Widget _buildPriceRow(BuildContext context, String price, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          price,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}