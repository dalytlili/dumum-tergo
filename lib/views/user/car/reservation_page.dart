import 'package:cached_network_image/cached_network_image.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/constants/api_constants.dart';
import 'package:dumum_tergo/models/reservation_model.dart';
import 'package:dumum_tergo/services/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReservationPage extends StatefulWidget {
  final String? authToken;

  const ReservationPage({super.key, this.authToken});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  late Future<List<Reservation>> futureReservations;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    futureReservations = _loadReservations();
  }

  Future<List<Reservation>> _loadReservations() async {
    try {
      final data = await ReservationService().getUserReservations();
      final reservations = data.map((json) => Reservation.fromJson(json)).toList();
      reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reservations;
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  Future<void> _refreshReservations() async {
    setState(() {
      futureReservations = _loadReservations();
    });
  }

  Future<void> _createComplaint(String vendorId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final token = await storage.read(key: 'token');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => ComplaintDialog(),
    );

    if (result != null) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:9098/api/complaints'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'vendorId': vendorId,
            'title': result['title'],
            'description': result['description'],
          }),
        );

        if (response.statusCode == 201) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Réclamation créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to create complaint');
        }
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
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
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Commencez par réserver une voiture',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
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
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final reservation = snapshot.data![index];
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ReservationCard(
                    key: ValueKey(reservation.id),
                    reservation: reservation,
                    onCancelled: _refreshReservations,
                    onCreateComplaint: () => _createComplaint(reservation.vendor.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ReservationCard extends StatefulWidget {
  final Reservation reservation;
  final Function()? onCancelled;
  final Function()? onCreateComplaint;

  const ReservationCard({
    super.key, 
    required this.reservation,
    this.onCancelled,
    this.onCreateComplaint,
  });

  @override
  State<ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<ReservationCard> {
  bool _isCancelling = false;

  Future<void> _cancelReservation() async {
    final theme = Theme.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'annulation'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette réservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Oui', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      final success = await ReservationService().cancelReservation(widget.reservation.id);
      if (success && widget.onCancelled != null) {
        widget.onCancelled!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  String getTranslatedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'cancelled': return 'Annulée';
      case 'rejected': return 'Rejetée';
      default: return status;
    }
  }

  Color getStatusColor(String status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'pending': return theme.colorScheme.secondary;
      case 'confirmed': return theme.colorScheme.primary;
      case 'cancelled':
      case 'rejected': return theme.colorScheme.error;
      default: return theme.disabledColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = widget.reservation.endDate.difference(widget.reservation.startDate).inDays;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final priceFormat = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
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
                  if (widget.reservation.car.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: 'https://res.cloudinary.com/dcs2edizr/image/upload/${widget.reservation.car.images[0]}',
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.dividerColor,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error, color: theme.colorScheme.error),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.car_rental, color: theme.disabledColor),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.reservation.car.brand} ${widget.reservation.car.model}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                              IconButton(
                                icon: Icon(Icons.more_vert, size: 20),
                                onPressed: () => _showComplaintMenu(context),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Loueur: ${widget.reservation.vendor.businessName}',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(widget.reservation.status, context).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: getStatusColor(widget.reservation.status, context),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      getTranslatedStatus(widget.reservation.status).toUpperCase(),
                      style: TextStyle(
                        color: getStatusColor(widget.reservation.status, context),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.location_on_outlined, 
                text: widget.reservation.location,
                theme: theme,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: '${dateFormat.format(widget.reservation.startDate)} - ${dateFormat.format(widget.reservation.endDate)}',
                      theme: theme,
                    ),
                  ),
                  Chip(
                    label: Text('$duration jours'),
                    labelStyle: theme.textTheme.bodySmall,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.wallet,
                text: 'Prix total: ${priceFormat.format(widget.reservation.totalPrice)}',
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.access_time,
                text: 'Créée le: ${dateFormat.format(widget.reservation.createdAt)}',
                theme: theme,
              ),
              const SizedBox(height: 16),
              if (widget.reservation.status.toLowerCase() == 'pending')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      onPressed: _isCancelling ? null : _cancelReservation,
                      child: _isCancelling
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Annuler la réservation'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComplaintMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.report_problem, color: Colors.orange),
              title: Text('Signaler un problème'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onCreateComplaint != null) {
                  widget.onCreateComplaint!();
                }
              },
            ),
        const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon, 
    required String text,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class ComplaintDialog extends StatefulWidget {
  @override
  _ComplaintDialogState createState() => _ComplaintDialogState();
}

class _ComplaintDialogState extends State<ComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nouvelle réclamation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Titre de la réclamation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Décrivez brièvement le problème',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.outline.withOpacity(0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode 
                      ? colors.surfaceVariant.withOpacity(0.5)
                      : colors.surfaceVariant.withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: TextStyle(fontSize: 15),
                validator: (value) => value?.isEmpty ?? true 
                    ? 'Veuillez saisir un titre' 
                    : null,
              ),
              SizedBox(height: 20),
              Text(
                'Description détaillée',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Décrivez le problème en détails...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.outline.withOpacity(0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode 
                      ? colors.surfaceVariant.withOpacity(0.5)
                      : colors.surfaceVariant.withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                maxLines: 5,
                style: TextStyle(fontSize: 15),
                validator: (value) => value?.isEmpty ?? true 
                    ? 'Veuillez saisir une description' 
                    : null,
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        Navigator.pop(context, {
                          'title': _titleController.text,
                          'description': _descriptionController.text,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Envoyer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}