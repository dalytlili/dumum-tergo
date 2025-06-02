import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationDetailsPage extends StatelessWidget {
  final Map<String, dynamic> reservationData;

  const ReservationDetailsPage({Key? key, required this.reservationData}) 
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reservationId = reservationData['reservationId'] ?? 'N/A';
    final car = reservationData['car'];
    final user = reservationData['user'];
    final startDate = reservationData['startDate'] != null
        ? DateTime.parse(reservationData['startDate'])
        : null;
    final endDate = reservationData['endDate'] != null
        ? DateTime.parse(reservationData['endDate'])
        : null;
    final status = reservationData['status'] ?? 'Inconnu';
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la réservation'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Informations générales
            _buildSectionHeader(theme, 'Informations générales'),
            _buildInfoCard(
              context,
              children: [
                _buildInfoRow('ID Réservation', reservationId),
                _buildInfoRow('Statut', status, 
                    statusColor: _getStatusColor(status)),
                if (startDate != null && endDate != null)
                  _buildInfoRow(
                    'Durée', 
                    '${dateFormat.format(startDate.toLocal())}\n'
                    'au ${dateFormat.format(endDate.toLocal())}',
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Section Voiture
            if (car != null) ...[
              _buildSectionHeader(theme, 'Véhicule'),
              _buildInfoCard(
                context,
                children: [
                  _buildInfoRow('Marque', car['brand'] ?? 'Marque inconnue'),
                  _buildInfoRow('Modèle', car['model'] ?? 'Modèle inconnu'),
                  if (car['licensePlate'] != null)
                    _buildInfoRow('Plaque d\'immatriculation', car['licensePlate']),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Section Client
            if (user != null) ...[
              _buildSectionHeader(theme, 'Client'),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user['image'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://dumum-tergo-backend.onrender.com${user['image']}',
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.person, size: 80),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'] ?? 'Nom inconnu',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (user['email'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(user['email']),
                              ),
                            if (user['phone'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(user['phone']),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color? _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reservation_accepted':
        return Colors.green;
      case 'en attente':
        return Colors.orange;
      case 'reservation_rejected':
        return Colors.red;
      default:
        return null;
    }
  }
}