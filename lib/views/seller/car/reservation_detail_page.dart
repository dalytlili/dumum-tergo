import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ReservationDetailPage extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final VoidCallback onBack;

  const ReservationDetailPage({
    Key? key,
    required this.reservation,
    required this.onBack,
  }) : super(key: key);

  @override
  _ReservationDetailPageState createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  bool _isUpdatingStatus = false;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    const String baseUrl = "https://res.cloudinary.com/dcs2edizr/image/upload/";
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    List<String> carImages = (widget.reservation['car']['images'] is List)
        ? (widget.reservation['car']['images'] as List)
            .map((image) => "$baseUrl$image")
            .toList()
        : [];

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Détails de réservation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        systemOverlayStyle: isDarkMode 
            ? SystemUiOverlayStyle.light 
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec statut
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildStatusHeader(widget.reservation['status'] ?? 'unknown', isDarkMode),
                  SizedBox(height: 16),
                  Text(
                    'Créé le: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(widget.reservation['createdAt']))}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Informations principales
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Informations du véhicule', isDarkMode),
                  SizedBox(height: 12),
                  _buildCarInfoCard(widget.reservation, carImages, isDarkMode),
                  SizedBox(height: 24),
                  _buildSectionTitle('Informations du conducteur', isDarkMode),
                  SizedBox(height: 12),
                  _buildDriverInfoCard(widget.reservation, isDarkMode),
                  SizedBox(height: 24),
                  _buildSectionTitle('Informations du client', isDarkMode),
                  SizedBox(height: 12),
                  _buildClientInfoCard(widget.reservation, isDarkMode),
                  SizedBox(height: 24),
                  _buildSectionTitle('Détails de la réservation', isDarkMode),
                  SizedBox(height: 12),
                  _buildReservationDetailsCard(widget.reservation, isDarkMode),
                  SizedBox(height: 24),
                  _buildSectionTitle('Options supplémentaires', isDarkMode),
                  SizedBox(height: 12),
                  _buildAdditionalOptionsCard(widget.reservation, isDarkMode),
                  SizedBox(height: 24),
                  _buildSectionTitle('Paiement', isDarkMode),
                  SizedBox(height: 12),
                  _buildPaymentCard(widget.reservation, isDarkMode),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(context, widget.reservation, isDarkMode),
    );
  }

  Widget _buildStatusHeader(String status, bool isDarkMode) {
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'En attente';
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Acceptée';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Terminée';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejetée';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusText = 'Annulée';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(isDarkMode ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 12, color: statusColor),
          SizedBox(width: 8),
          Text(
            statusText.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildCarInfoCard(Map<String, dynamic> reservation, List<String> carImages, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 200,
              width: 400,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
              child: carImages.isNotEmpty
                  ? Image.network(
                      carImages[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.car_rental, 
                            size: 60, 
                            color: isDarkMode ? Colors.grey[400] : Colors.grey,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.car_rental, 
                        size: 60, 
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reservation['car']['brand'] ?? 'N/A'} ${reservation['car']['model'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                  Icons.confirmation_number, 
                  'Immatriculation', 
                  reservation['car']['registrationNumber'] ?? 'N/A',
                  isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard(Map<String, dynamic> reservation, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withOpacity(isDarkMode ? 0.2 : 0.1),
                child: Icon(
                  Icons.person, 
                  size: 30, 
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reservation['driverDetails']['firstName'] ?? 'N/A'} ${reservation['driverDetails']['lastName'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      reservation['driverDetails']['email'] ?? 'N/A',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (reservation['driverDetails']['phoneNumber'] != null) {
                _makePhoneCall(reservation['driverDetails']['phoneNumber']);
              }
            },
            child: _buildInfoRow(
              Icons.phone, 
              'Téléphone', 
              reservation['driverDetails']['phoneNumber'] ?? 'N/A', 
              isDarkMode,
            ),
          ),
          _buildInfoRow(Icons.cake, 'Date de naissance', _formatDate(reservation['driverDetails']['birthDate']), isDarkMode),
          _buildInfoRow(Icons.location_on, 'Pays', reservation['driverDetails']['country'] ?? 'N/A', isDarkMode),
          _buildInfoRow(Icons.card_membership, 'Permis de conduire', reservation['driverDetails']['driverLicense'] ?? 'Non fourni', isDarkMode),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
  try {
    // Nettoyer le numéro de téléphone
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanedNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Numéro de téléphone invalide')),
      );
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanedNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'effectuer l\'appel')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de l\'appel: ${e.toString()}')),
    );
  }
}

 Widget _buildClientInfoCard(Map<String, dynamic> reservation, bool isDarkMode) {
    final userImage = reservation['user']['image'] != null
        ? (reservation['user']['image'].toString().startsWith('https')
            ? reservation['user']['image']
            : "https://res.cloudinary.com/dcs2edizr/image/upload/${reservation['user']['image']}")
        : null;
    final userName = reservation['user']['name'] ?? 'N/A';
    final initials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n[0]).take(2).join()
        : '';

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(isDarkMode ? 0.3 : 0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(isDarkMode ? 0.2 : 0.1),
                  foregroundImage: userImage != null ? NetworkImage(userImage) : null,
                  child: userImage == null
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID Client: ${reservation['user']['_id'] ?? 'N/A'}',
                      style: TextStyle(
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
    );
  }

  Widget _buildReservationDetailsCard(Map<String, dynamic> reservation, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.calendar_today, 
            'Dates', 
            '${_formatDateTime(reservation['startDate'])} - ${_formatDateTime(reservation['endDate'])}',
            isDarkMode,
          ),
          _buildInfoRow(
            Icons.timer, 
            'Durée', 
            _calculateDuration(reservation['startDate'], reservation['endDate']),
            isDarkMode,
          ),
          _buildInfoRow(
            Icons.location_pin, 
            'Lieu de prise en charge', 
            reservation['location'] ?? 'N/A',
            isDarkMode,
          ),
          _buildInfoRow(
            Icons.euro, 
            'Prix total', 
            '${reservation['totalPrice']} /DTN',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalOptionsCard(Map<String, dynamic> reservation, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.child_care, 
            'Sièges enfants', 
            reservation['childSeats']?.toString() ?? '0',
            isDarkMode,
          ),
          _buildInfoRow(
            Icons.people_alt, 
            'Conducteurs supplémentaires', 
            reservation['additionalDrivers']?.toString() ?? '0',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> reservation, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.payment, 
            'Méthode de paiement', 
            reservation['paymentMethod'] ?? 'N/A',
            isDarkMode,
          ),
          _buildInfoRow(
            Icons.paid, 
            'Statut du paiement', 
            reservation['paymentStatus'] ?? 'N/A',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> reservation, bool isDarkMode) {
    if (reservation['status'] != 'pending') {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isUpdatingStatus ? null : () => _updateReservationStatus(context, 'accepted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUpdatingStatus
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Accepter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isUpdatingStatus ? null : () => _updateReservationStatus(context, 'rejected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUpdatingStatus
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Rejeter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReservationStatus(BuildContext context, String status) async {
    if (_isUpdatingStatus) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final url = Uri.parse('https://dumum-tergo-backend.onrender.com/api/reservation/${widget.reservation['_id']}');
    final token = await storage.read(key: 'seller_token');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'status': status.toLowerCase()
        }),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour avec succès'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        widget.onBack();
      } else {
        final errorData = jsonDecode(response.body);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur: ${errorData['message'] ?? errorData['error'] ?? 'Erreur inconnue'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      initializeDateFormatting('fr_FR', null);
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(date);
    } catch (e) {
      return dateTimeString;
    }
  }

  String _calculateDuration(String startDate, String endDate) {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final difference = end.difference(start);
      final days = difference.inDays;
      final hours = difference.inHours.remainder(24);
      
      if (days > 0 && hours > 0) {
        return '$days jours et $hours heures';
      } else if (days > 0) {
        return '$days jours';
      } else {
        return '$hours heures';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}