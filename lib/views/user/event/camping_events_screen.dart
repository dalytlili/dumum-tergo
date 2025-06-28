import 'dart:math';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart' show storage;
import 'package:dumum_tergo/views/user/event/camping_event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CampingEventsScreen extends StatefulWidget {
  const CampingEventsScreen({Key? key}) : super(key: key);

  @override
  State<CampingEventsScreen> createState() => _CampingEventsScreenState();
}

class _CampingEventsScreenState extends State<CampingEventsScreen> {
  List<dynamic> _campingEvents = [];
  List<dynamic> _nearbyEvents = [];
  List<dynamic> _filteredEvents = [];
  bool _isLoading = true;
  bool _locationEnabled = false;
  Position? _currentPosition;
  DateTime? _selectedDate;
  List<DateTime> _weekDates = [];
  Map<String, int> _eventsCountByDate = {};
  double _distanceFilter = 100.0; // Valeur par défaut de 100 km
  final TextEditingController _distanceController = TextEditingController();

 @override
void initState() {
  super.initState();
  _distanceController.text = _distanceFilter.toStringAsFixed(0);
  _initializeWeekDates();
  
  initializeDateFormatting('fr_FR', null).then((_) {
    fetchCampingEvents().then((_) {
      // Après avoir chargé les événements, déterminer la position
      _determinePosition().then((_) {
        // Une fois la position obtenue, filtrer les événements proches
        _filterNearbyEvents();
      });
    });
  });
}

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  void _initializeWeekDates() {
    final now = DateTime.now();
    _weekDates = List.generate(7, (index) => now.add(Duration(days: index)));
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationEnabled = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationEnabled = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationEnabled = false;
      });
      return;
    }

    setState(() {
      _locationEnabled = true;
    });
    _currentPosition = await Geolocator.getCurrentPosition();
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _sortEventsByDate() {
    _campingEvents.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });
  }

void _countEventsByDate() {
  _eventsCountByDate = {};
  final dateFormat = DateFormat('yyyy-MM-dd');

  for (var date in _weekDates) {
    final dateStr = dateFormat.format(date);
    _eventsCountByDate[dateStr] = 0;
  }

  for (var event in _campingEvents) {
    try {
      final eventDate = DateTime.parse(event['date']);
      final eventDateStr = dateFormat.format(eventDate);
      
      if (_eventsCountByDate.containsKey(eventDateStr)) {
        _eventsCountByDate[eventDateStr] = _eventsCountByDate[eventDateStr]! + 1;
      }
    } catch (e) {
      print('Error parsing event date: $e');
    }
  }
}

  void _filterEventsByDate(DateTime? date) {
    setState(() {
      _selectedDate = date;
      
      if (date == null) {
        _filteredEvents = List.from(_campingEvents);
      } else {
        final dateFormat = DateFormat('yyyy-MM-dd');
        final dateStr = dateFormat.format(date);
        
        _filteredEvents = _campingEvents.where((event) {
          try {
            final eventDate = DateTime.parse(event['date']);
            return dateFormat.format(eventDate) == dateStr;
          } catch (e) {
            return false;
          }
        }).toList();
      }
    });
  }

Future<void> _updateDistanceFilter(double newDistance) async {
  setState(() {
    _distanceFilter = newDistance;
    _distanceController.text = newDistance.toStringAsFixed(0);
  });
  
  // Recalculer les événements à proximité
  await _filterNearbyEvents();
}

  Future<void> _filterNearbyEvents() async {
    if (_currentPosition == null) return;
    
    setState(() {
      _nearbyEvents = _campingEvents.where((event) {
        if (event['location']?['coordinates'] == null) return false;
        final coords = event['location']['coordinates'];
        final distance = _calculateDistance(
          _currentPosition!.latitude, 
          _currentPosition!.longitude, 
          coords[1], 
          coords[0]
        );
        return distance <= _distanceFilter;
      }).toList();
    });
  }
void _showDistanceFilterBottomSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent, // pour coins arrondis + overlay propre
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barre de glissement
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                Text(
                  'Filtrer par distance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${_distanceFilter.toStringAsFixed(0)} km',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: _distanceFilter,
                  min: 1,
                  max: 500,
                  divisions: 49,
                  label: _distanceFilter.toStringAsFixed(0),
                  onChanged: (value) {
                    setModalState(() {
                      _distanceFilter = value;
                    });
                  },
                  activeColor: AppColors.primary,
                  inactiveColor: Colors.grey.shade300,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _updateDistanceFilter(_distanceFilter);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                      ),
                      child: const Text('Appliquer', style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  Future<void> fetchCampingEvents() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/sortiecamping'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final allEvents = json.decode(response.body);
        
        allEvents.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['date']);
            final dateB = DateTime.parse(b['date']);
            return dateA.compareTo(dateB);
          } catch (e) {
            return 0;
          }
        });

        await _filterNearbyEvents();

        setState(() {
          _campingEvents = allEvents;
          _filteredEvents = List.from(allEvents);
          _isLoading = false;
        });
        
        _countEventsByDate();
      } else {
        throw Exception('Erreur lors du chargement des événements');
      }
    } catch (e) {
      print("Erreur: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }


  Widget _buildDateSelector() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _weekDates.length,
        itemBuilder: (context, index) {
          final date = _weekDates[index];
          final dateFormat = DateFormat('yyyy-MM-dd');
          final dateStr = dateFormat.format(date);
          final dayName = DateFormat('E', 'fr_FR').format(date);
          final dayNumber = date.day;
          final eventCount = _eventsCountByDate[dateStr] ?? 0;
          final isSelected = _selectedDate != null && 
              dateFormat.format(_selectedDate!) == dateStr;

          return GestureDetector(
            onTap: () {
              _filterEventsByDate(isSelected ? null : date);
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
           decoration: BoxDecoration(
  color: isSelected 
      ? AppColors.primary 
      : Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey.shade800 
          : Colors.white,
  borderRadius: BorderRadius.circular(10),
  border: Border.all(
    color: isSelected 
        ? AppColors.primary 
        : Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey.shade600 
            : Colors.grey.shade300,
  ),
),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  if (eventCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        eventCount.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(dynamic event, {bool isHorizontal = false}) {
    final imageUrl = (event['images'] != null && event['images'].isNotEmpty)
        ? 'https://res.cloudinary.com/dcs2edizr/image/upload/${event['images'][0]}'
        : 'https://via.placeholder.com/150';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampingEventDetailScreen(eventId: event['id']),
          ),
        );
      },
      child: Container(
        width: isHorizontal ? 220 : null,
        margin: isHorizontal 
            ? const EdgeInsets.only(left: 16, right: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
          elevation: 1,
          shadowColor: Colors.grey.withOpacity(0.1),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade50,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade50,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['lieu']?.toUpperCase() ?? 'LIEU INCONNU',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                                .format(DateTime.parse(event['date'])),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.people_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event['participants']?.length ?? '0'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (isHorizontal && event['location']?['coordinates'] != null && _currentPosition != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_calculateDistance(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                                event['location']['coordinates'][1],
                                event['location']['coordinates'][0]
                              ).toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchCampingEvents,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Événements par date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDateSelector(),
                        ],
                      ),
                    ),
                  ),

                  if (!_locationEnabled)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_off, color: Colors.orange[800]),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Activez la localisation pour voir les événements près de vous',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                 if (_locationEnabled && _currentPosition != null && _selectedDate == null)
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'À proximité (${_distanceFilter.toStringAsFixed(0)} km)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            onPressed: _showDistanceFilterBottomSheet,
            tooltip: 'Filtrer par distance',
          ),
        ],
      ),
    ),
  ),
if (_locationEnabled && _currentPosition != null && _selectedDate == null)
  SliverToBoxAdapter(
    child: _nearbyEvents.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Aucun événement à proximité dans un rayon de ${_distanceFilter.toStringAsFixed(0)} km',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        : SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyEvents.length,
              itemBuilder: (context, index) {
                return _buildEventCard(_nearbyEvents[index], isHorizontal: true);
              },
            ),
          ),
  ),

                  SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      _selectedDate == null 
          ? 'Tous les événements' 
          : 'Événements du ${DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate!)}',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),
if (_filteredEvents.isEmpty)
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _selectedDate == null
                ? 'Aucun événement disponible'
                : 'Aucun événement pour cette date',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    ),
  )
else
  SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        return _buildEventCard(_filteredEvents[index]);
      },
      childCount: _filteredEvents.length,
    ),
  ),
                ],
              ),
            ),
    );
  }
}