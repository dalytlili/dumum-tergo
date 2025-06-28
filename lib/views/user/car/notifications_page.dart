import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/user/car/reservation_details_page.dart';
import 'package:dumum_tergo/views/user/experiences/ExperienceDetailView.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class NotificationsUserPage extends StatefulWidget {
  final VoidCallback? onNotificationsRead;
  final VoidCallback? onBack;
  final ValueChanged<int>? onUnreadCountChanged;

  const NotificationsUserPage({
    Key? key,
    this.onNotificationsRead,
    this.onBack,
    this.onUnreadCountChanged,
  }) : super(key: key);

  @override
  State<NotificationsUserPage> createState() => _NotificationsUserPageState();
}

class _NotificationsUserPageState extends State<NotificationsUserPage> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();
  bool _isOpeningDetails = false; // Ajoutez cette ligne

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _todayNotifications = [];
  List<Map<String, dynamic>> _earlierNotifications = [];
  bool _isLoading = true;
  String? _error;
  bool _hasNewNotifications = false;
  bool _showAllEarlier = false;
  final int _earlierLimit = 5;

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

  void _categorizeNotifications() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    _todayNotifications = _notifications.where((n) {
      final createdAt = n['createdAt'] != null ? DateTime.parse(n['createdAt']) : now;
      return createdAt.isAfter(todayStart);
    }).toList();

    _earlierNotifications = _notifications.where((n) {
      final createdAt = n['createdAt'] != null ? DateTime.parse(n['createdAt']) : now;
      return createdAt.isBefore(todayStart);
    }).toList();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? token = await storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/notifications/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _notifications = data.cast<Map<String, dynamic>>();
          _categorizeNotifications();
          _isLoading = false;
          _hasNewNotifications = _notifications.any((n) => n['readAt'] == null);
          
          if (_hasNewNotifications && widget.onNotificationsRead != null) {
            widget.onNotificationsRead!();
          }

          if (widget.onUnreadCountChanged != null) {
            widget.onUnreadCountChanged!(_notifications.where((n) => n['readAt'] == null).length);
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

  Future<void> _markAsRead(String notificationId) async {
    try {
      String? token = await storage.read(key: 'token');
      if (token == null) throw Exception('Token non trouvé');

      final response = await http.put(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/notifications/user/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['_id'] == notificationId);
          if (index != -1) {
            _notifications[index]['read'] = true;
            _categorizeNotifications();
          }
        });
      }
    } catch (e) {
      print('Erreur lors du marquage de la notification comme lue: $e');
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
            const Icon(Icons.notifications_off, size: 64, ),
            const SizedBox(height: 16),
            const Text(
              'Aucune notification disponible',
              style: TextStyle(fontSize: 18, ),
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
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Section "Aujourd'hui"
          if (_todayNotifications.isNotEmpty)
            SliverSectionHeader(title: 'Aujourd\'hui'),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildNotificationItem(_todayNotifications[index]);
              },
              childCount: _todayNotifications.length,
            ),
          ),

          // Section "Plus tôt"
          if (_earlierNotifications.isNotEmpty)
            SliverSectionHeader(title: 'Plus tôt'),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (!_showAllEarlier && index >= _earlierLimit) return null;
                return _buildNotificationItem(_earlierNotifications[index]);
              },
              childCount: _earlierNotifications.length,
            ),
          ),

          // Bouton "Afficher plus"
          if (_earlierNotifications.length > _earlierLimit && !_showAllEarlier)
            SliverToBoxAdapter(
              child: Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllEarlier = true;
                    });
                  },
                  child: Text(
                    'Afficher plus (${_earlierNotifications.length - _earlierLimit})',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
Widget _buildNotificationItem(Map<String, dynamic> notification) {
  final isRead = notification['read'] == true;
  final data = notification['data'] ?? {};
  final likedBy = data['likedBy'] ?? {};
  final commentedBy = data['commentedBy'] ?? {};
  final createdAt = notification['createdAt'] != null 
      ? DateTime.parse(notification['createdAt']) 
      : DateTime.now();

  // Image de l'utilisateur qui a liké ou commenté
  final userImage = (likedBy['image'] ?? commentedBy['image']) != null
      ? "${likedBy['image'] ?? commentedBy['image']}"
      : null;

  return InkWell(
    onTap: () async {
      await _markAsRead(notification['_id']);
      _handleNotificationTap(notification);
    },
    child: Container(
      decoration: BoxDecoration(
        color: isRead 
            ? Colors.transparent 
            : Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de statut de lecture
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: isRead ? Colors.transparent : Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          
          // Avatar de l'utilisateur ou icône par défaut
          if (userImage != null && (notification['type'] == 'experience_like' || notification['type'] == 'experience_comment'))
            CircleAvatar(
              radius: 20,
            backgroundImage: NetworkImage(
                     userImage.startsWith('https') 
                        ? userImage
                        : 'https://res.cloudinary.com/dcs2edizr/image/upload/${userImage}',
                    ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification['type']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getNotificationIcon(notification['type']),
                  color: _getNotificationColor(notification['type']),
                  size: 20,
                ),
              ),
            ),
          
          const SizedBox(width: 12),
          
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getNotificationTitle(notification['type']),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isRead 
                              ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
                
                // Message spécifique pour les likes
                if (notification['type'] == 'experience_like' && likedBy['name'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${likedBy['name']} a aimé votre expérience',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                
                // Message spécifique pour les commentaires
                if (notification['type'] == 'experience_comment' && commentedBy['name'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${commentedBy['name']} a commenté votre expérience',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                
                // Message pour d'autres types de notifications
                if (notification['type'] != 'experience_like' && 
                    notification['type'] != 'experience_comment' && 
                    notification['message'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notification['message'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                
                const SizedBox(height: 4),
                Text(
                  timeago.format(createdAt, locale: 'fr'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
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

Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
  final data = notification['data'] ?? {};
  final type = notification['type']?.toString() ?? '';

  if (data.isEmpty || type.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification invalide')),
    );
    return;
  }

  setState(() {
    _isOpeningDetails = true;
  });

  try {
    switch (type) {
      case 'reservation_accepted':
      case 'reservation_rejected':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationDetailsPage(reservationData: data),
          ),
        );
        break;
        
      case 'experience_like':
      case 'experience_comment': // Même traitement pour les likes et commentaires
        if (data['experienceId'] != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExperienceDetailView(
                experienceId: data['experienceId'],
                onExperienceDeleted: () {
                  _loadNotifications(); 
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Données de l\'expérience incomplètes')),
          );
        }
        break;
        
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Type de notification non pris en charge: $type')),
        );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors du traitement: ${e.toString()}')),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isOpeningDetails = false;
      });
    }
  }
}

IconData _getNotificationIcon(String? type) {
  switch (type) {
    case 'reservation_request':
      return Icons.car_rental;
    case 'reservation_accepted':
      return Icons.check_circle;
    case 'reservation_rejected':
      return Icons.cancel;
    case 'payment_received':
      return Icons.payment;
    case 'experience_like':
      return Icons.favorite;
      case 'experience_comment':
      return Icons.favorite;
    default:
      return Icons.notifications;
  }
}

Color _getNotificationColor(String? type) {
  switch (type) {
    case 'reservation_request':
      return Colors.blue;
    case 'reservation_accepted':
      return Colors.green;
    case 'reservation_rejected':
      return Colors.red;
    case 'payment_received':
      return Colors.purple;
    case 'experience_like':
      return Colors.pink;
       case 'experience_comment':
      return Colors.pink;
    default:
      return Theme.of(context).primaryColor;
  }
}

  String _getNotificationTitle(String? type) {
    switch (type) {
      case 'reservation_request':
        return 'Nouvelle demande de réservation';
      case 'reservation_accepted':
        return 'Réservation confirmée';
      case 'reservation_rejected':
        return 'Réservation annulée';
              case 'experience_like':
        return 'Nouveau j\'aime';
        case 'experience_comment':
        return 'Nouveau commenatire';
      case 'payment_received':
        return 'Paiement reçu';
      default:
        return 'Notification';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

class SliverSectionHeader extends StatelessWidget {
  final String title;

  const SliverSectionHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}