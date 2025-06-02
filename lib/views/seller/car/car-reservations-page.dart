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
  List<dynamic> reservations = [];
  List<dynamic> filteredReservations = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  String selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  Widget? _overlayContent;
  int _unreadNotifications = 0;

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
    _fetchReservations().then((_) {
      if (widget.initialReservationId != null) {
        _navigateToInitialReservation();
      }
    });
    _initializeNotifications();
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

  Future<void> _fetchReservations() async {
    try {
      final token = await storage.read(key: 'seller_token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/reservation/vendor'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        data.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));      
        setState(() {
          reservations = data;
          filteredReservations = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load reservations: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: _overlayContent == null ? AppBar(
        title: const Text('Liste des réservations'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        systemOverlayStyle: isDarkMode 
            ? SystemUiOverlayStyle.light 
            : SystemUiOverlayStyle.dark,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  setState(() {
                    _overlayContent = NotificationsPage(
                      onNotificationsRead: () {
                        setState(() {
                          _unreadNotifications = 0;
                        });
                      },
                      onBack: () {
                        setState(() {
                          _overlayContent = null;
                        });
                      },
                    );
                  });
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 23,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ) : null,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une réservation...',
                        hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
                        prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
                            child: FilterChip(
                              label: Text(
                                status == 'all' ? 'Tous' : status.toUpperCase(),
                                style: TextStyle(
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
                              checkmarkColor: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                  child: _buildReservationsList(),
                ),
              ),
            ],
          ),
          if (_overlayContent != null)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: _overlayContent,
            ),
        ],
      ),
    );
  }

  Widget _buildReservationsList() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    } else if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.red,
                fontSize: 16,
              ),
            ),
            Text(
              errorMessage!,
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
        ),
      );
    } else if (filteredReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.car_rental, 
              size: 60, 
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty || selectedStatus != 'all'
                  ? 'Aucune réservation ne correspond à vos critères'
                  : 'Aucune réservation trouvée',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _fetchReservations,
        color: AppColors.primary,
        child: ListView.builder(
          itemCount: filteredReservations.length,
          itemBuilder: (context, index) {
            final reservation = filteredReservations[index];
            return _buildReservationCard(reservation, isDarkMode);
          },
        ),
      );
    }
  }

  Widget _buildReservationCard(dynamic reservation, bool isDarkMode) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final startDate = dateFormat.format(DateTime.parse(reservation['startDate']));
    final endDate = dateFormat.format(DateTime.parse(reservation['endDate']));
    final createdAt = DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(reservation['createdAt']));

    return GestureDetector(
      onTap: () {
        widget.onReservationSelected(reservation);
      },
      child: Card(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: reservation['car']['images'] != null && reservation['car']['images'].isNotEmpty
                        ? Image.network(
                            'https://res.cloudinary.com/dcs2edizr/image/upload/${reservation['car']['images'][0]}',
                            width: 90,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 90,
                              height: 70,
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              child: Icon(
                                Icons.car_rental, 
                                size: 40, 
                                color: isDarkMode ? Colors.grey[400] : Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            width: 90,
                            height: 70,
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            child: Icon(
                              Icons.car_rental, 
                              size: 40, 
                              color: isDarkMode ? Colors.grey[400] : Colors.grey,
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
                        const SizedBox(height: 4),
                        Text(
                          '${reservation['car']['registrationNumber']} ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reservation['driverDetails']['firstName']} ${reservation['driverDetails']['lastName']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(reservation['status']),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[200], height: 1),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildInfoItem(Icons.calendar_today, '$startDate - $endDate', isDarkMode),
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.location_on, reservation['location'], isDarkMode),
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.euro, '${reservation['totalPrice']} / DTN', isDarkMode),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[200], height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Créé le: $createdAt',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right, 
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                    onPressed: () {
                      widget.onReservationSelected(reservation);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'accepted':
      case 'completed':
        chipColor = Colors.green;
        break;
      case 'rejected':
      case 'cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(isDarkMode ? 0.3 : 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, bool isDarkMode) {
    return Column(
      children: [
        Icon(
          icon, 
          size: 20, 
          color: AppColors.primary,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}