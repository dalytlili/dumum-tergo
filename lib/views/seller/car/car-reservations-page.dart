import 'package:dumum_tergo/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reservation_detail_page.dart';
import 'notifications_page.dart';
import 'package:dumum_tergo/services/notification_service.dart';
import 'package:flutter/services.dart';

class CarReservationsPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onReservationSelected;
  final String? initialReservationId;

  const CarReservationsPage({
    Key? key, 
    required this.onReservationSelected,
    this.initialReservationId,
  }) : super(key: key);

  @override
  _CarReservationsPageState createState() => _CarReservationsPageState();
}

class _CarReservationsPageState extends State<CarReservationsPage> {
  final storage = const FlutterSecureStorage();
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> reservations = [];
  List<dynamic> filteredReservations = [];
  bool isLoading = true;
  bool isRefreshing = false;
  bool _showSearchBar = true;
  double _scrollPosition = 0;
  String? errorMessage;
  String searchQuery = '';
  String selectedStatus = 'all';
  Widget? _overlayContent;
  int _unreadNotifications = 0;
  bool _hasMore = true;
  int _currentPage = 1;

  final List<String> statusOptions = [
    'all',
    'pending',
    'accepted',
    'completed',
    'rejected',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchReservations().then((_) {
      if (widget.initialReservationId != null) {
        _navigateToInitialReservation();
      }
    });
    _initializeNotifications();
  }

  void _scrollListener() {
    final currentPosition = _scrollController.position.pixels;
    if (currentPosition > _scrollPosition && currentPosition > 100) {
      if (_showSearchBar) {
        setState(() {
          _showSearchBar = false;
        });
      }
    } else if (currentPosition < _scrollPosition && _scrollPosition > 100) {
      if (!_showSearchBar) {
        setState(() {
          _showSearchBar = true;
        });
      }
    }
    _scrollPosition = currentPosition;
  }

Future<void> _fetchReservations({bool reset = false}) async {
    try {
      if (reset) {
        setState(() {
          _currentPage = 1;
          _hasMore = true;
          isRefreshing = true;
          errorMessage = null; // Réinitialise l'erreur lors du rafraîchissement
        });
      } else {
        setState(() {
          isLoading = true;
        });
      }

      final token = await storage.read(key: 'seller_token');
      if (token == null) throw Exception('Aucun token trouvé');

      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/reservation/vendor?page=$_currentPage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          if (reset) {
            reservations = data;
            filteredReservations = data;
          } else {
            reservations.addAll(data);
            filteredReservations.addAll(data);
          }
          
          if (data.length < 10) {
            _hasMore = false;
          }
          
          isLoading = false;
          isRefreshing = false;
        });
        
        _filterReservations();
      } else if (response.statusCode == 403) {
        // Cas spécifique pour l'erreur 403 (abonnement)
        setState(() {
          errorMessage = 'Votre abonnement n\'est pas actif. Veuillez souscrire à un abonnement !';
          isLoading = false;
          isRefreshing = false;
        });
      } else {
        // Pour les autres erreurs HTTP
        throw Exception('Échec du chargement: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        // On ne surcharge pas le message si c'est déjà une 403 gérée
        if (!e.toString().contains('403')) {
          errorMessage = 'Erreur lors du chargement des réservations: ${e.toString().replaceFirst('Exception: ', '')}';
        }
        isLoading = false;
        isRefreshing = false;
      });
      
     // if (kDebugMode) print('Erreur _fetchReservations: $e');
    }
  }

  Future<void> _loadMoreReservations() async {
    if (isLoading || !_hasMore) return;
    
    setState(() {
      _currentPage++;
      isLoading = true;
    });
    
    await _fetchReservations();
  }

  void _navigateToInitialReservation() {
    final initialReservation = reservations.firstWhere(
      (r) => r['_id'] == widget.initialReservationId,
      orElse: () => null,
    );
    
    if (initialReservation != null) {
      setState(() {
        selectedStatus = 'all';
        searchQuery = initialReservation['car']['brand'] + ' ' + initialReservation['car']['model'];
        _filterReservations();
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onReservationSelected(initialReservation);
      });
    }
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    _notificationService.notificationsStream.listen((notifications) {
      if (mounted) {
        setState(() {
          _unreadNotifications = notifications.where((n) => !n['read']).length;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterReservations() {
    setState(() {
      filteredReservations = reservations.where((reservation) {
        final matchesSearch = searchQuery.isEmpty ||
            reservation['car']['brand'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
            reservation['car']['model'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
            reservation['driverDetails']['firstName'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
            reservation['driverDetails']['lastName'].toString().toLowerCase().contains(searchQuery.toLowerCase());

        final matchesStatus = selectedStatus == 'all' || reservation['status'] == selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
      
      filteredReservations.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: _overlayContent == null 
            ? Text('Liste des réservations', 
               )
            : null,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: isDarkMode 
            ? SystemUiOverlayStyle.light 
            : SystemUiOverlayStyle.dark,
        actions: _overlayContent == null 
            ? [
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_outlined, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NotificationsPage()),
                        );
                      },
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            _unreadNotifications.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _fetchReservations(reset: true);
            },
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (_showSearchBar)
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    pinned: true,
                    floating: true,
                    expandedHeight: 145.0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                        
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Rechercher une réservation...',
                                hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                                _filterReservations();
                              },
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: statusOptions.map((status) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(
                                        status == 'all' ? 'Tous' : _getStatusLabel(status),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: selectedStatus == status 
                                              ? Colors.white 
                                              : (isDarkMode ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                      selected: selectedStatus == status,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          selectedStatus = status;
                                        });
                                        _filterReservations();
                                      },
                                      backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                      selectedColor: AppColors.primary,
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                    child: _buildReservationsList(),
                  ),
                ),
                
                if (isLoading && !isRefreshing && reservations.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_overlayContent != null)
            Positioned.fill(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: _overlayContent,
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'accepted': return 'Acceptée';
      case 'completed': return 'Terminée';
      case 'rejected': return 'Rejetée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  Widget _buildReservationsList() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    if (isLoading && reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    } else if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 20),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _fetchReservations(reset: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (filteredReservations.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.car_rental, 
            size: 80, 
          ),
          const SizedBox(height: 20),
          Text(
            searchQuery.isNotEmpty || selectedStatus != 'all'
                ? 'Aucune réservation ne correspond à vos critères'
                : 'Aucune réservation trouvée',
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (searchQuery.isNotEmpty || selectedStatus != 'all')
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  selectedStatus = 'all';
                  _searchController.clear();
                  _filterReservations();
                });
              },
              child: Text(
                'Réinitialiser les filtres',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _fetchReservations(reset: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Actualiser',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: filteredReservations.length,
            itemBuilder: (context, index) {
              final reservation = filteredReservations[index];
              return _buildReservationCard(reservation, isDarkMode);
            },
          ),
          if (isLoading && !isRefreshing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildReservationCard(dynamic reservation, bool isDarkMode) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final startDate = dateFormat.format(DateTime.parse(reservation['startDate']));
    final endDate = dateFormat.format(DateTime.parse(reservation['endDate']));
    final createdAt = DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(reservation['createdAt']));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            widget.onReservationSelected(reservation);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 100,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: reservation['car']['images'] != null &&
                                reservation['car']['images'].isNotEmpty
                            ? Image.network(
                                'https://res.cloudinary.com/dcs2edizr/image/upload/${reservation['car']['images'][0]}',
                                width: 100,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(
                                    Icons.car_rental,
                                    size: 40,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.car_rental,
                                  size: 40,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${reservation['car']['brand']} ${reservation['car']['model']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${reservation['car']['registrationNumber']}',
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
                const SizedBox(height: 16),
                Divider(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildInfoItem(Icons.calendar_today_outlined, '$startDate - $endDate', isDarkMode),
                      const SizedBox(width: 20),
                      _buildInfoItem(Icons.location_on_outlined, reservation['location'], isDarkMode),
                      const SizedBox(width: 20),
                      _buildInfoItem(Icons.monetization_on_rounded, '${reservation['totalPrice']} DTN', isDarkMode),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Créé le $createdAt',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    _buildStatusChip(reservation['status']),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final Map<String, Map<String, dynamic>> statusConfig = {
      'pending': {
        'color': Colors.orange,
        'icon': Icons.access_time_outlined,
        'text': 'En attente',
      },
      'accepted': {
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
        'text': 'Acceptée',
      },
      'completed': {
        'color': Colors.blue,
        'icon': Icons.done_all_outlined,
        'text': 'Terminée',
      },
      'rejected': {
        'color': Colors.red,
        'icon': Icons.cancel_outlined,
        'text': 'Rejetée',
      },
      'cancelled': {
        'color': Colors.red,
        'icon': Icons.cancel_outlined,
        'text': 'Annulée',
      },
    };

    final config = statusConfig[status] ?? {
      'color': Colors.grey,
      'icon': Icons.help_outline,
      'text': status,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          config['icon'] as IconData,
          size: 16,
          color: config['color'] as Color,
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (config['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (config['color'] as Color).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            config['text'] as String,
            style: TextStyle(
              color: config['color'] as Color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 18, 
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}