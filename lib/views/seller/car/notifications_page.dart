import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/seller/car/car-reservations-page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'reservation_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback? onNotificationsRead;
  final VoidCallback? onBack;
  
  const NotificationsPage({
    Key? key,
    this.onNotificationsRead,
    this.onBack,
  }) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;
  bool _hasNewNotifications = false;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _loadNotifications();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Charger plus de notifications si nécessaire
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? token = await storage.read(key: 'seller_token');

      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/notifications/vendor'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _notifications = data.cast<Map<String, dynamic>>();
          _isLoading = false;
          _hasNewNotifications = _notifications.any((n) => n['readAt'] == null);
          
          // Appeler le callback si des notifications non lues existent
          if (_hasNewNotifications && widget.onNotificationsRead != null) {
            widget.onNotificationsRead!();
          }
        });
      } else {
        throw Exception('Erreur lors du chargement des notifications: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des notifications...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Erreur: $_error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune notification disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              onPressed: _loadNotifications,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: Theme.of(context).primaryColor,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return _buildNotificationItem(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isUnread = notification['read'] ;
    final data = notification['data'] ?? {};
    final car = data['car'] ?? {};
    final user = data['user'] ?? {};
    final createdAt = notification['createdAt'] != null 
        ? DateTime.parse(notification['createdAt']) 
        : DateTime.now();

  final userImage = user['image'] != null
    ? (user['image'].toString().startsWith('https')
        ? user['image']
        : "https://res.cloudinary.com/dcs2edizr/image/upload/${user['image']}")
    : null;

    return InkWell(
     onTap: () async {
  // Marquer comme lu via l'API
  try {
    String? token = await storage.read(key: 'seller_token');
    if (token == null) {
      throw Exception('Token non trouvé');
    }

    final response = await http.put(
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/notifications/vendor/${notification['_id']}/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Mettre à jour l'état local
      setState(() {
        notification['readAt'] = DateTime.now().toIso8601String();
      });
    }
  } catch (e) {
    print('Erreur lors du marquage de la notification comme lue: $e');
  }
  
  if (notification['type'] == 'new_reservation') {
    final reservationData = notification['data'];
    
    // Naviguer vers la page de liste avec filtre sur cette réservation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarReservationsPage(
          onReservationSelected: (reservation) {
            // Naviguer vers les détails
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReservationDetailPage(
                  reservation: reservation,
                  onBack: () {
                    // Retourner à la page d'accueil
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            );
          },
          initialReservationId: data['reservationId'],
        ),
      ),
    );
  }
},
      child: Container(
        color: !isUnread ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Remplacer le container avec icône par un CircleAvatar avec l'image utilisateur
            CircleAvatar(
              radius: 24,
              backgroundColor: _getNotificationColor(notification['type']).withOpacity(0.2),
              backgroundImage: userImage != null 
                  ? NetworkImage(userImage) 
                  : null,
              child: userImage == null
                  ? Icon(
                      _getNotificationIcon(notification['type']),
                      color: _getNotificationColor(notification['type']),
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                         _getNotificationTitle(notification['type']),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isUnread ? AppColors.primary : Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (isUnread == false)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (user['name'] != null)
                    Text(
                      'De: ${user['name']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  if (car['brand'] != null && car['model'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${car['brand']} ${car['model']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  if (data['startDate'] != null && data['endDate'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatDate(data['startDate'])} - ${_formatDate(data['endDate'])}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        timeago.format(createdAt, locale: 'fr'),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'reservation_request':
        return Colors.blue;
      case 'reservation_confirmed':
        return Colors.green;
      case 'reservation_cancelled':
        return Colors.red;
      case 'payment_received':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'reservation_request':
        return Icons.car_rental;
      case 'reservation_confirmed':
        return Icons.check_circle;
      case 'reservation_cancelled':
        return Icons.cancel;
      case 'payment_received':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTitle(String? type) {
    switch (type) {
      case 'reservation_request':
        return 'Nouvelle demande de réservation';
      case 'reservation_confirmed':
        return 'Réservation confirmée';
      case 'reservation_cancelled':
        return 'Réservation annulée';
      case 'payment_received':
        return 'Paiement reçu';
      default:
        return 'Notification';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}