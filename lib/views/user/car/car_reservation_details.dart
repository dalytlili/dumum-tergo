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
Future<Map<String, dynamic>> _fetchVendorRatings() async {
        final token = await storage.read(key: 'token');

  final response = await http.get(
    Uri.parse('https://dumum-tergo-backend.onrender.com/api/vendor/${widget.car['vendor']['vendorId']}/ratings'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Remplacez par votre token
    },
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load ratings');
  }
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
                  const SizedBox(height: 16),
                  const Text(
                    'Votre offre',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text('Suivant... Responsabilité et Caution'),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(height: 2, color: AppColors.primary),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(height: 2, color: Colors.grey),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(height: 2, color: Colors.grey),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                
                  // Détails du véhicule
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Détails du véhicule',
                          style: TextStyle(
                            color: AppColors.primary,
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
                                        color: Colors.grey[200],
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
                                                return const Center(
                                                  child: Icon(Icons.error, color: Colors.red),
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
                                                  : Colors.grey.withOpacity(0.5),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.car['color']} • ${widget.car['registrationNumber']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildFeatureRow('${widget.car['seats']} sièges', icon: Icons.airline_seat_recline_normal),
                        _buildFeatureRow('${widget.car['transmission']}', icon: Icons.settings),
                        _buildFeatureRow('Kilométrage ${widget.car['mileagePolicy']}', icon: Icons.speed),
                        Text(
                          'caractéristiques:',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        ...widget.car['features'].map<Widget>((feature) => 
                          _buildFeatureItem(feature, useDash: true)
                        ).toList(),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        
                        Text(
                          widget.car['location'] ?? 'Emplacement non spécifié',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                  const Text(
                    'Ajoutez des options, complétez votre voyage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option Conducteur supplémentaire
                  _buildOptionCard(
                    title: 'Conducteur supplémentaire',
                    price: '30 TND pièce par location',
                    description: 'Partagez la conduite et gardez l\'esprit tranquille sachant que quelqu\'un d\'autre est couvert si besoin.',
                    quantity: _additionalDriverQuantity,
                    onIncrement: () {
                      if (_additionalDriverQuantity < 2) {
                        setState(() {
                          _additionalDriverQuantity++;
                          _additionalOptionsPrice += 30;
                        });
                      }
                    },
                    onDecrement: () {
                      if (_additionalDriverQuantity > 0) {
                        setState(() {
                          _additionalDriverQuantity--;
                          _additionalOptionsPrice -= 30;
                        });
                      }
                    },
                  ),

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
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 80), // Espace supplémentaire pour éviter que le bouton ne cache le contenu
                ],
              ),
            ),
          ),
          
          // Partie fixe en bas avec animation
           AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  height: _showBottomBar ? null : 0,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white, // Fond blanc
    borderRadius: BorderRadius.vertical( // Bordures arrondies
      top: Radius.circular(20.0), // Arrondi seulement en haut
    ),
    border: Border.all(
      color: Colors.grey[300]!, // Couleur de bordure gris clair
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, -5),
      ),
    ],
  ),
  child: Column(
    children: [
      Text(
        'Durée de location: ${_calculateRentalDays()} jours',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[700], // Texte gris foncé
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Prix par jour : ${widget.car['pricePerDay']} TND',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[700], // Texte gris foncé
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Prix total: ${_calculateTotalPrice().toStringAsFixed(2)} TND',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black, // Texte noir
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
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(
                            color: Colors.grey[600],
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
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 0 ? onDecrement : null,
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
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
                  color: Colors.grey[600],
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
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold))
              : Icon(Icons.check_circle_outline,
                  size: 18, 
                  color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 16),
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
          if (icon != null) Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}