import 'package:cached_network_image/cached_network_image.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/constants/api_constants.dart'; // <-- Ajouté
import 'package:dumum_tergo/models/reservation_model.dart';
import 'package:dumum_tergo/services/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationPage extends StatefulWidget {
  final String? authToken;

  const ReservationPage({super.key, this.authToken});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  late Future<List<Reservation>> futureReservations;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    futureReservations = _loadReservations();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        !_isLoadingMore) {
      _loadMoreReservations();
    }
  }

  Future<void> _loadMoreReservations() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreData = await ReservationService().getUserReservations();
      final currentData = await futureReservations;

      setState(() {
        futureReservations = Future.value([
          ...currentData,
          ...moreData.map((json) => Reservation.fromJson(json)).toList()
        ]);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<List<Reservation>> _loadReservations() async {
    try {
      final data = await ReservationService().getUserReservations();
      return data.map((json) => Reservation.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  Future<void> _refreshReservations() async {
    setState(() {
      futureReservations = _loadReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réservations'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReservations,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReservations,
        child: FutureBuilder<List<Reservation>>(
          future: futureReservations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshReservations,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                
                    const SizedBox(height: 20),
                    Text(
                      'Aucune réservation trouvée',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Commencez par réserver une voiture',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Naviguer vers la page de recherche
                      },
                      child: const Text('Chercher une voiture'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: snapshot.data!.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == snapshot.data!.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final reservation = snapshot.data![index];
                return ReservationCard(reservation: reservation);
              },
            );
          },
        ),
      ),
    );
  }
}

class ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const ReservationCard({super.key, required this.reservation});

  String getTranslatedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'cancelled':
        return 'Annulée';
      case 'rejected':
        return 'Rejetée';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = reservation.endDate.difference(reservation.startDate).inDays;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final priceFormat = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 2);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Naviguer vers les détails de la réservation
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reservation.car.images.isNotEmpty)
                 Builder(
  builder: (context) {
    // Affiche l'URL dans la console lorsque le widget est construit
    if (reservation.car.images.isNotEmpty) {
      final imageUrl = 'https://res.cloudinary.com/dcs2edizr/image/upload/${reservation.car.images[0]}';
      debugPrint('Chargement de l\'image: $imageUrl');
    } else {
      debugPrint('Aucune image disponible pour cette voiture');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
  'https://res.cloudinary.com/dcs2edizr/image/upload/${reservation.car.images[0]}',
  width: 80,
  height: 60,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    debugPrint('Erreur: $error');
    return const Icon(Icons.broken_image);
  },
)

    );
  },
)
                  else
                    Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.car_rental, color: Colors.grey),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reservation.car.brand} ${reservation.car.model}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Loueur: ${reservation.vendor.businessName}',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(reservation.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: getStatusColor(reservation.status),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      getTranslatedStatus(reservation.status).toUpperCase(),
                      style: TextStyle(
                        color: getStatusColor(reservation.status),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(icon: Icons.location_on_outlined, text: reservation.location),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      text:
                          '${dateFormat.format(reservation.startDate)} - ${dateFormat.format(reservation.endDate)}',
                    ),
                  ),
                  Chip(
                    label: Text('$duration jours'),
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.attach_money_outlined,
                text: 'Prix total: ${priceFormat.format(reservation.totalPrice)}',
              ),
              const SizedBox(height: 16),
              // Tu peux ajouter d’autres infos ici si besoin (conducteur, etc.)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
