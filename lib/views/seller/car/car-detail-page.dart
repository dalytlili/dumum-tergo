import 'package:dumum_tergo/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CarDetailPage extends StatefulWidget {
  final Map<String, dynamic> car;
  final VoidCallback? onCarDeleted;
  final VoidCallback onBack;

  const CarDetailPage({
    Key? key,
    required this.car,
    this.onCarDeleted,
    required this.onBack,
  }) : super(key: key);

  @override
  _CarDetailPageState createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  final storage = const FlutterSecureStorage();
  bool isDeleting = false;

  Future<void> deleteCar(BuildContext context) async {
    setState(() {
      isDeleting = true;
    });

    try {
      final token = await storage.read(key: 'seller_token');

      final response = await http.delete(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/cars/cars/${widget.car['_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        widget.onCarDeleted?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voiture supprimée avec succès'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onBack();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${json.decode(response.body)['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            'Confirmer la suppression',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
          content: Text(
            'Voulez-vous vraiment supprimer cette voiture et toutes ses réservations?',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Annuler',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: isDeleting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
              onPressed: isDeleting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      deleteCar(context);
                    },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? theme.colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label $value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChips(List<dynamic> dates) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dates.map<Widget>((date) {
        try {
          String formattedDate = 'Date invalide';

          if (date is Map && date['from'] != null && date['to'] != null) {
            final fromDate = DateTime.parse(date['from']);
            final toDate = DateTime.parse(date['to']);
            formattedDate =
                '${dateFormat.format(fromDate)} - ${dateFormat.format(toDate)}';
          }

          return Chip(
            label: Text(formattedDate),
            backgroundColor: theme.brightness == Brightness.dark 
                ? Colors.orange.withOpacity(0.2)
                : Colors.orange[50],
            labelStyle: TextStyle(
              color: theme.brightness == Brightness.dark 
                  ? Colors.orange[200]
                  : Colors.orange),
            side: BorderSide(
              color: theme.brightness == Brightness.dark 
                  ? Colors.orange.withOpacity(0.5)
                  : Colors.orange[100]!),
          );
        } catch (e) {
          return Chip(
            label: const Text('Format invalide'),
            backgroundColor: theme.brightness == Brightness.dark 
                ? Colors.red.withOpacity(0.2)
                : Colors.red[50],
            labelStyle: TextStyle(
              color: theme.brightness == Brightness.dark 
                  ? Colors.red[200]
                  : Colors.red),
          );
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    String createdAt = 'Date inconnue';

    if (widget.car['createdAt'] != null) {
      try {
        if (widget.car['createdAt'] is String) {
          createdAt = dateFormat.format(DateTime.parse(widget.car['createdAt']));
        } else if (widget.car['createdAt'] is Map &&
            widget.car['createdAt']['\$date'] != null) {
          createdAt = dateFormat
              .format(DateTime.parse(widget.car['createdAt']['\$date']));
        } else if (widget.car['createdAt'] is DateTime) {
          createdAt = dateFormat.format(widget.car['createdAt']);
        }
      } catch (e) {
        createdAt = 'Format de date invalide';
      }
    }

    bool hasUnavailableDates = widget.car['unavailableDates'] != null &&
        widget.car['unavailableDates'] is List &&
        widget.car['unavailableDates'].isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails de voiture',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.brightness == Brightness.dark 
            ? Colors.grey[900] 
            : Colors.white,
        iconTheme: IconThemeData(
          color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
        systemOverlayStyle: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isDeleting ? null : () => _confirmDelete(context),
        backgroundColor: Colors.red,
        child: isDeleting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.delete, color: Colors.white),
        tooltip: 'Supprimer la voiture',
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.car['images'] != null && widget.car['images'] is List)
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.cardColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (widget.car['images'] as List).length,
                    itemBuilder: (context, index) {
                      String imageUrl =
                          "https://res.cloudinary.com/dcs2edizr/image/upload/${widget.car['images'][index]}";
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Card(
              color: theme.cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 8),
                        Text(
                          "${widget.car['pricePerDay']} TND/jour",
                          style: TextStyle(
                            fontSize: 22,
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: theme.dividerColor),
                    const SizedBox(height: 16),
                    _buildInfoRow('Location:', widget.car['location']['title'], Icons.location_pin),
                    _buildInfoRow('Année:', widget.car['year'].toString(), Icons.calendar_today),
                    _buildInfoRow('Immatriculation:', widget.car['registrationNumber'], Icons.confirmation_number),
                    _buildInfoRow('Couleur:', widget.car['color'], Icons.palette),
                    _buildInfoRow('Places:', widget.car['seats'].toString(), Icons.people),
                    _buildInfoRow('Transmission:', widget.car['transmission'], Icons.speed),
                    _buildInfoRow('Kilométrage:', widget.car['mileagePolicy'], Icons.directions_car),
                    _buildInfoRow('Caution:', '${widget.car['deposit']} TND', Icons.monetization_on),
                    _buildInfoRow(
                        'Disponibilité:',
                        widget.car['isAvailable'] ? 'Disponible' : 'Non disponible',
                        widget.car['isAvailable'] ? Icons.check_circle : Icons.cancel,
                        color: widget.car['isAvailable'] ? Colors.green : Colors.red),
                    _buildInfoRow('Ajoutée le:', createdAt, Icons.access_time),
                  ],
                ),
              ),
            ),
            if (hasUnavailableDates) ...[
              const SizedBox(height: 20),
              ExpansionTile(
                title: Text(
                  'Dates indisponibles:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDateChips(widget.car['unavailableDates']),
                  ),
                ],
              )
            ],
            const SizedBox(height: 20),
            ExpansionTile(
              title: Text(
                'Équipements et caractéristiques:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (widget.car['features'] as List).map<Widget>((feature) {
                      return Chip(
                        label: Text(
                          feature,
                          style: TextStyle(color: theme.colorScheme.onSecondary),
                        ),
                        backgroundColor: theme.colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}