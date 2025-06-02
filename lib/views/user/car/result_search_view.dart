import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/user/car/car_reservation_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dumum_tergo/viewmodels/user/result_search_viewmodel.dart';

class ResultSearchView extends StatelessWidget {
  final List<dynamic> initialResults;
 //final List<dynamic> initialResults;
  final String pickupLocation;
  final DateTime pickupDate;
  final DateTime returnDate;

  const ResultSearchView({
    Key? key, 
    required this.initialResults,
    required this.pickupLocation,
    required this.pickupDate,
    required this.returnDate,
  }) : super(key: key);
  //const ResultSearchView({Key? key, required this.initialResults}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResultSearchViewModel()..loadSearchResults(initialResults),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Résultats de recherche'),
          actions: [
         
          ],
        ),
        body: Consumer<ResultSearchViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationAndDate(context),
                 // const SizedBox(height: 16),
                 // _buildSortAndFilterBar(),
                  const SizedBox(height: 16),
          ..._buildCarResults(viewModel.searchResults, context), // Pass context here
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationAndDate(BuildContext context) {
  // Fonction pour formater la date en français
  String _formatDate(DateTime date) {
    final months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Fonction pour formater l'heure
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }

 return Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.primary),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Colonne pour les textes
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pickupLocation,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDate(pickupDate)}, ${_formatTime(pickupDate)} – \n'
            '${_formatDate(returnDate)}, ${_formatTime(returnDate)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
      
      // Bouton Modifier
   SizedBox(
  width: 120,
  child: TextButton(
    style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    onPressed: () {
      Navigator.pop(context);
    },
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.edit, color: AppColors.background, size: 18),
        const SizedBox(width: 8),
        Text(
          'Modifier',
          style: TextStyle(color: AppColors.background),
        ),
      ],
    ),
  ),
)
    ],
  ),
);
}


  List<Widget> _buildCarResults(List<dynamic> results, BuildContext context) {
  return results.map((car) => _buildCarCard(car, context)).toList();
}

Widget _buildCarCard(Map<String, dynamic> car, BuildContext context) {
  // Définir l'URL de base du serveur
  const String baseUrl = "https://res.cloudinary.com/dcs2edizr/image/upload/";

  // Construire la liste des URLs complètes
  List<String> images = (car['images'] as List<dynamic>?)
      ?.map((image) => "$baseUrl$image")
      .toList() ?? [];

  // Créer un controller pour gérer les pages
  final PageController pageController = PageController();
  int currentPage = 0;

  return StatefulBuilder(
    builder: (context, setState) {
      return Container(
          margin: const EdgeInsets.symmetric(vertical: 5), // Ajoute un espace entre les cadres

                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    
                  ),
                  
        child: SizedBox(

          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Slider des images avec URL complète
                if (images.isNotEmpty)
                  Stack(
                    children: [
                      Container(
                        height: 180,
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
                      // Indicateurs de page
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
                const SizedBox(height: 8),
                Text(
                  '${car['brand']} ${car['model']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildFeatureIcon(Icons.people, '${car['seats']} sièges'),
                    const SizedBox(width: 16),
                    _buildFeatureIcon(Icons.settings, '${car['transmission']}'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      car['location'] ?? 'Emplacement non défini',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.business, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      car['vendor']['businessName'] ?? 'Vendeur',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prix pour 3 jours :',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          '${car['pricePerDay'] * 3} TND',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(

                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                         Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CarReservationDetails(
      car: car,
      pickupLocation: pickupLocation,
      pickupDate: pickupDate,  // Pass pickupDate
      returnDate: returnDate,  // Pass returnDate
    ),
  ),
);

                        },
                        child: const Text('Réserver'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}





  Widget _buildFeatureIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
