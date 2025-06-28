import 'package:dumum_tergo/views/user/car/full_screen_image_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dumum_tergo/constants/colors.dart';
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
  final double _cardElevation = 3.0;
  final double _cardBorderRadius = 12.0;

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
      appBar: AppBar(
        title: Text(
          'Détails de réservation',
     
        ),
        centerTitle: true,
        elevation: 0,
      
        systemOverlayStyle: isDarkMode 
            ? SystemUiOverlayStyle.light 
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: 24),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // En-tête avec statut
            _buildStatusHeaderSection(isDarkMode),
            SizedBox(height: 20),
            
            // Informations principales
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Informations du véhicule', isDarkMode),
                  SizedBox(height: 12),
                  _buildCarInfoCard(widget.reservation, carImages, isDarkMode),
                  SizedBox(height: 20),
                  
                  _buildSectionTitle('Informations du conducteur', isDarkMode),
                  SizedBox(height: 12),
                  _buildDriverInfoCard(widget.reservation, isDarkMode),
                  SizedBox(height: 20),
                  
                  _buildSectionTitle('Documents du conducteur', isDarkMode),
                  SizedBox(height: 12),
                  _buildDocumentsCard(widget.reservation, isDarkMode),
                  SizedBox(height: 20),
                  
                  _buildSectionTitle('Informations du client', isDarkMode),
                  SizedBox(height: 12),
                  _buildClientInfoCard(widget.reservation, isDarkMode),
                  SizedBox(height: 20),
                  
                  _buildSectionTitle('Détails de la réservation', isDarkMode),
                  SizedBox(height: 12),
                  _buildReservationDetailsCard(widget.reservation, isDarkMode),
                  SizedBox(height: 20),
                  
                  _buildSectionTitle('Options supplémentaires', isDarkMode),
                  SizedBox(height: 12),
                  _buildAdditionalOptionsCard(widget.reservation, isDarkMode),
                  SizedBox(height: 20),
                  
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(context, widget.reservation, isDarkMode),
    );
  }

  // Nouvelle méthode pour afficher les documents
 Widget _buildDocumentsCard(Map<String, dynamic> reservation, bool isDarkMode) {
  final documents = reservation['documents'] ?? {};
  
  return Card(
    elevation: _cardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_cardBorderRadius),
    ),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (documents['permisRecto'] != null)
            _buildDocumentItem(
              'Permis de conduire (Recto)',
              documents['permisRecto'],
              isDarkMode,
            ),
          if (documents['permisVerso'] != null)
            _buildDocumentItem(
              'Permis de conduire (Verso)',
              documents['permisVerso'],
              isDarkMode,
            ),
          if (documents['passport'] != null)
            _buildDocumentItem(
              'Passeport',
              documents['passport'],
              isDarkMode,
            ),
          if (documents['cinRecto'] != null)
            _buildDocumentItem(
              'CIN (Recto)',
              documents['cinRecto'],
              isDarkMode,
            ),
          if (documents['cinVerso'] != null)
            _buildDocumentItem(
              'CIN (Verso)',
              documents['cinVerso'],
              isDarkMode,
            ),
          if (documents.isEmpty)
            Text(
              'Aucun document fourni',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _buildDocumentItem(String title, String url, bool isDarkMode) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openFullScreenGallery(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(
                minHeight: 150,
                maxHeight: 150, // Hauteur maximale pour éviter que l'image ne soit trop grande
              ),
              width: double.infinity, // Prend toute la largeur disponible
              decoration: BoxDecoration(
                border: Border.all(
                  //color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

void _openFullScreenGallery(String imageUrl) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FullScreenImageGallery(
        images: [imageUrl],
        initialIndex: 0,
      ),
    ),
  );
}



  // Modifier la méthode _buildClientInfoCard pour supprimer le nom et prénom
  Widget _buildClientInfoCard(Map<String, dynamic> reservation, bool isDarkMode) {
    final userImage = reservation['user']['image'] != null
        ? (reservation['user']['image'].toString().startsWith('https')
            ? reservation['user']['image']
            : "https://res.cloudinary.com/dcs2edizr/image/upload/${reservation['user']['image']}")
        : null;

    return Card(
      elevation: _cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
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
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(isDarkMode ? 0.2 : 0.1),
                foregroundImage: userImage != null ? NetworkImage(userImage) : null,
                child: userImage == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: AppColors.primary,
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
                    'ID Client: ${reservation['user']['_id']?.substring(0, 8) ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Compte vérifié',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (le reste du code reste inchangé)
  Widget _buildStatusHeaderSection(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),)
        ],
      ),
      child: Column(
        children: [
          _buildStatusChip(widget.reservation['status'] ?? 'unknown', isDarkMode),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                icon: Icons.calendar_today_rounded,
                label: 'Créé le',
                value: DateFormat('dd MMM yyyy HH:mm').format(
                  DateTime.parse(widget.reservation['createdAt'])),
                isDarkMode: isDarkMode,
              ),
              _buildInfoItem(
                icon: Icons.confirmation_number_rounded,
                label: 'N° Réservation',
                value: widget.reservation['_id']?.substring(0, 8) ?? 'N/A',
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isDarkMode) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'En attente';
        statusIcon = Icons.access_time_rounded;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Acceptée';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Terminée';
        statusIcon = Icons.done_all_rounded;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejetée';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusText = 'Annulée';
        statusIcon = Icons.block_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 18, color: statusColor),
          SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black87,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCarInfoCard(Map<String, dynamic> reservation, List<String> carImages, bool isDarkMode) {
    return Card(
      elevation: _cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(_cardBorderRadius)),
            child: Container(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (carImages.isNotEmpty)
                    Image.network(
                      carImages[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildCarPlaceholder(isDarkMode);
                      },
                    )
                  else
                    _buildCarPlaceholder(isDarkMode),
                  
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${reservation['car']['category'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Immatriculation',
                  value: reservation['car']['registrationNumber'] ?? 'N/A',
                  isDarkMode: isDarkMode,
                ),
    
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarPlaceholder(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.car_rental_rounded, 
            size: 50, 
            color: isDarkMode ? Colors.grey[400] : Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'Image non disponible',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard(Map<String, dynamic> reservation, bool isDarkMode) {
    return Card(
      elevation: _cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: Padding(
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
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person_rounded, 
                      size: 28, 
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conducteur principal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        reservation['driverDetails']['email'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.phone_rounded, color: AppColors.primary),
                  onPressed: () {
                    if (reservation['driverDetails']['phoneNumber'] != null) {
                      _makePhoneCall(reservation['driverDetails']['phoneNumber']);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.phone_rounded,
              label: 'Téléphone',
              value: reservation['driverDetails']['phoneNumber'] ?? 'N/A',
              isDarkMode: isDarkMode,
              isPhone: true,
            ),
            _buildDetailRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: reservation['driverDetails']['email'] ?? 'N/A',
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationDetailsCard(Map<String, dynamic> reservation, bool isDarkMode) {
    return Card(
      elevation: _cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildDetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Dates',
              value: '${DateFormat('dd MMM yyyy HH:mm').format(
                  DateTime.parse(widget.reservation['startDate']))} - ${DateFormat('dd MMM yyyy HH:mm').format(
                  DateTime.parse(widget.reservation['endDate']))}',
              isDarkMode: isDarkMode,
            ),
            _buildDetailRow(
              icon: Icons.timer_rounded,
              label: 'Durée',
              value: _calculateDuration(reservation['startDate'], reservation['endDate']),
              isDarkMode: isDarkMode,
            ),
            _buildDetailRow(
              icon: Icons.location_on_rounded,
              label: 'Lieu de prise en charge',
              value: reservation['location'] ?? 'N/A',
              isDarkMode: isDarkMode,
            ),
            _buildDetailRow(
              icon: Icons.monetization_on_rounded,
              label: 'Prix total',
              value: '${reservation['totalPrice']} DTN',
              isDarkMode: isDarkMode,
              isPrice: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalOptionsCard(Map<String, dynamic> reservation, bool isDarkMode) {
    return Card(
      elevation: _cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              icon: Icons.child_care_rounded,
              label: 'Sièges enfants',
              value: reservation['childSeats']?.toString() ?? '0',
              isDarkMode: isDarkMode,
            ),
         
          ],
        ),
      ),
    );
  }



  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
    bool isPhone = false,
    bool isPrice = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                if (isPhone)
                  GestureDetector(
                    onTap: () => _makePhoneCall(value),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (isPrice)
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, -2),)
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isUpdatingStatus ? null : () => _updateReservationStatus(context, 'rejected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.red, width: 1.5),
                ),
                elevation: 0,
              ),
              child: _isUpdatingStatus
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Rejeter',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isUpdatingStatus ? null : () => _updateReservationStatus(context, 'accepted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Accepter',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      if (cleanedNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Numéro de téléphone invalide'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          ),
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
          SnackBar(
            content: Text('Impossible d\'effectuer l\'appel'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'appel: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.green,
          ),
        );
        widget.onBack();
      } else {
        final errorData = jsonDecode(response.body);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur: ${errorData['message'] ?? errorData['error'] ?? 'Erreur inconnue'}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
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