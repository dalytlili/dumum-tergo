import 'dart:convert';

import 'package:dumum_tergo/models/camping_item.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:dumum_tergo/views/user/car/full_screen_image_gallery.dart';
import 'package:dumum_tergo/views/user/car/responsibility_page.dart';
import 'package:flutter/material.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:http/http.dart' as http;

class CarReservationDetails extends StatefulWidget {
  final Map<String, dynamic> car;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String pickupLocation;

  const CarReservationDetails({
    Key? key,
    required this.car,
    required this.pickupLocation,
    required this.pickupDate,
    required this.returnDate,
  }) : super(key: key);

  @override
  _CarReservationDetailsState createState() => _CarReservationDetailsState();
}

class _CarReservationDetailsState extends State<CarReservationDetails> {
  int _additionalDriverQuantity = 0;
  int _childSeatQuantity = 0;
  double _additionalOptionsPrice = 0;
  int currentPage = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showBottomBar = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final currentPosition = _scrollController.position.pixels;
    if (currentPosition > _lastScrollPosition && currentPosition > 100) {
      // Scrolling down
      if (_showBottomBar) {
        setState(() {
          _showBottomBar = false;
        });
      }
    } else if (currentPosition < _lastScrollPosition) {
      // Scrolling up
      if (!_showBottomBar) {
        setState(() {
          _showBottomBar = true;
        });
      }
    }
    _lastScrollPosition = currentPosition;
  }

  int _calculateRentalDays() {
    final duration = widget.returnDate.difference(widget.pickupDate);
    return duration.inDays;
  }

  double _calculateTotalPrice() {
    final days = _calculateRentalDays();
    final pricePerDay = double.parse(widget.car['pricePerDay'].toString());
    return (days * pricePerDay) + _additionalOptionsPrice;
  }

  @override
  Widget build(BuildContext context) {
    const String baseUrl = "https://res.cloudinary.com/dcs2edizr/image/upload/";
    
    List<String> images = (widget.car['images'] as List<dynamic>?)
        ?.map((image) => "$baseUrl$image")
        .toList() ?? [];
    
    final PageController pageController = PageController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre offre'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepsHeader(),
                  const SizedBox(height: 24),
                
                  // Détails du véhicule
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails du véhicule',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (images.isNotEmpty)
                          StatefulBuilder(
                            builder: (context, setState) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImageGallery(
                                        images: images,
                                        initialIndex: currentPage,
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 200,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Theme.of(context).hoverColor,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: PageView.builder(
                                          controller: pageController,
                                          itemCount: images.length,
                                          onPageChanged: (index) {
                                            setState(() {
                                              currentPage = index;
                                            });
                                          },
                                          itemBuilder: (context, index) {
                                            return Image.network(
                                              images[index],
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
                                              errorBuilder: (context, error, stackTrace) {
                                                return Center(
                                                  child: Icon(Icons.error, ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(images.length, (index) {
                                          return AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            width: currentPage == index ? 12 : 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: currentPage == index
                                                  ? Theme.of(context).primaryColor
                                                  : Theme.of(context).disabledColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        Text(
                          '${widget.car['brand']} ${widget.car['model']} (${widget.car['year']})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.car['color']} • ${widget.car['registrationNumber']}',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildFeatureRow('${widget.car['seats']} sièges', icon: Icons.airline_seat_recline_normal),
                        _buildFeatureRow('${widget.car['transmission']}', icon: Icons.settings),
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _buildFeatureRow(
      widget.car['mileagePolicy'] == 'limitée' 
        ? 'Kilométrage: ${widget.car['mileageLimit']} km/jour (limité)'
        : 'Kilométrage: illimité',
      icon: Icons.speed
    ),
    if (widget.car['mileagePolicy'] == 'limitée')
      Padding(
        padding: const EdgeInsets.only(left: 32.0, top: 4.0, bottom: 8.0),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            children: [
              TextSpan(text: 'En cas de dépassement: '),
              TextSpan(
                text: '1 TND par km supplémentaire',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    // ... autres caractéristiques
  ],
),                      Text(
                          'caractéristiques:',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                        ),
                        ...widget.car['features'].map<Widget>((feature) => 
                          _buildFeatureItem(feature, useDash: true)
                        ).toList(),
                        
                        const SizedBox(height: 16),
                        Divider(color: Theme.of(context).dividerColor),
                        const SizedBox(height: 8),
                        
                        Text(
                          widget.car['location'] ?? 'Emplacement non spécifié',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(
                                'https://res.cloudinary.com/dcs2edizr/image/upload/${widget.car['vendor']['image'] ?? 'default.jpg'}',
                              ),
                              onBackgroundImageError: (_, __) {},
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.car['vendor']['businessName'] ?? 'Vendor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Ajoutez des options, complétez votre voyage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option Conducteur supplémentaire
               

                  const SizedBox(height: 16),

                  // Option Siège enfant
                  _buildOptionCard(
                    title: 'Siège enfant',
                    price: '30 TND pièce par location',
                    description: 'Recommandé pour les enfants pesant 9-18 kg (env. 1-3 ans)',
                    quantity: _childSeatQuantity,
                    onIncrement: () {
                      if (_childSeatQuantity < 2) {
                        setState(() {
                          _childSeatQuantity++;
                          _additionalOptionsPrice += 30;
                        });
                      }
                    },
                    onDecrement: () {
                      if (_childSeatQuantity > 0) {
                        setState(() {
                          _childSeatQuantity--;
                          _additionalOptionsPrice -= 30;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Nous transmettrons vos demandes d\'options à ${widget.car['vendor']['businessName'] ?? 'Vendor'} et vous les paierez lors de la prise en charge. '
                    'La disponibilité et les tarifs des options ne peuvent pas être garantis avant votre arrivée.',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),

                ],
              ),
            ),
          ),
          
          // Partie fixe en bas avec animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showBottomBar ? null : 0,
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20.0),
              ),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Durée de location: ${_calculateRentalDays()} jours',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Prix par jour : ${widget.car['pricePerDay']} TND',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Prix total: ${_calculateTotalPrice().toStringAsFixed(2)} TND',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResponsibilityPage(
                              car: widget.car,          
                              pickupLocation: widget.pickupLocation,
                              pickupDate: widget.pickupDate,
                              returnDate: widget.returnDate,
                              totalPrice: _calculateTotalPrice(),
                              additionalDrivers: _additionalDriverQuantity,
                              childSeats: _childSeatQuantity,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Continuer la réservation',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepsHeader() {
    return Column(
      children: [
        Text(
          'Étape 1/3',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre offre',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
             Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
              )),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
             )),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
               ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String price,
    required String description,
    required int quantity,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Price + Quantity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quantity Selector
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: Theme.of(context).iconTheme.color),
                        onPressed: quantity > 0 ? onDecrement : null,
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '$quantity',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: Theme.of(context).iconTheme.color),
                        onPressed: quantity < 2 ? onIncrement : null,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String feature, {bool useDash = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          useDash
              ? Text(' • ', style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold))
              : Icon(Icons.check_circle_outline,
                  size: 18, 
                  color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            text, 
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}