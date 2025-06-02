import 'dart:convert';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart' show storage;
import 'package:dumum_tergo/views/user/car/full_screen_image_gallery.dart';
import 'package:dumum_tergo/views/user/event/FullScreenMap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:latlong2/latlong.dart';

class CampingEventDetailScreen extends StatefulWidget {
  final String eventId;

  const CampingEventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  State<CampingEventDetailScreen> createState() => _CampingEventDetailScreenState();
}

class _CampingEventDetailScreenState extends State<CampingEventDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _event;
  bool _isLoading = true;
  bool _isParticipating = false;
  int _currentImageIndex = 0;
  final CarouselController _carouselController = CarouselController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Map<String, dynamic>? _weatherData;
  bool _isWeatherLoading = false;
  bool _isLoadingi = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    initializeDateFormatting('fr_FR', null).then((_) {
      fetchEventDetail().then((_) {
        // Charger automatiquement les données météo après avoir récupéré les détails de l'événement
        _fetchWeatherData();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    if (_event == null || _event!['location'] == null) return;

    setState(() {
      _isWeatherLoading = true;
    });

    try {
      final date = DateTime.parse(_event!['date']);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final lat = _event!['location']['coordinates'][1];
      final lon = _event!['location']['coordinates'][0];

      // Utilisation d'une API météo (exemple avec Open-Meteo)
      final response = await http.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast?'
          'latitude=$lat&longitude=$lon'
          '&daily=weathercode,temperature_2m_max,temperature_2m_min'
          '&timezone=auto'
          '&start_date=$dateStr'
          '&end_date=$dateStr',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['daily'] != null) {
          setState(() {
            _weatherData = {
              'max_temp': data['daily']['temperature_2m_max'][0],
              'min_temp': data['daily']['temperature_2m_min'][0],
              'weather_code': data['daily']['weathercode'][0],
            };
          });
        }
      }
    } catch (e) {
      print('Erreur météo: $e');
    } finally {
      setState(() {
        _isWeatherLoading = false;
      });
    }
  }
void _showParticipationOptions() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      String selectedOption = 'participant';
      final theme = Theme.of(context);

      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              // Utilise la couleur de fond des cartes de ton thème (cardTheme.color)
              color: theme.cardTheme.color ?? (theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    // Couleur adaptée au thème
                    color: theme.brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  "Participation",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                RadioListTile(
                  value: 'participant',
                  groupValue: selectedOption,
                  title: Text(
                    "Je participe déjà",
                    style: theme.textTheme.bodyMedium,
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedOption = value!;
                    });
                  },
                ),
                RadioListTile(
                  value: 'not_participating',
                  groupValue: selectedOption,
                  title: Text(
                    "Je ne participe plus",
                    style: theme.textTheme.bodyMedium,
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedOption = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (selectedOption == 'not_participating') {
                      toggleParticipation();
                    }
                  },
                  child: const Text("Confirmer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


  Future<void> fetchEventDetail() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/sortiecamping/evenement/${widget.eventId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final token = await storage.read(key: 'token');
        if (token == null) {
          throw Exception('Authentification requise');
        }

        final userId = await _getUserIdFromToken(token);
        if (userId == null) {
          print('Impossible d\'extraire l\'ID utilisateur du token');
          return;
        }   
      
        setState(() {
          _event = decoded['event'];
          _isParticipating = (_event!['participants'] as List).any((p) => p['_id'] == userId);
          _isLoading = false;
        });
      } else {
        throw Exception('Échec du chargement des détails de l\'événement');
      }
    } catch (e) {
      print("Erreur: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _getUserIdFromToken(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final jsonMap = jsonDecode(decoded);

      final user = jsonMap['user'];
      if (user != null && user['_id'] != null) {
        print("Erreur: ///////$user['_id']");
        return user['_id'].toString();
      }

      return jsonMap['userId']?.toString() ?? jsonMap['id']?.toString();
    } catch (e) {
      print('Erreur de décodage token: $e');
      return null;
    }
  }

  Future<String?> getUserIdFromToken(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final jsonMap = jsonDecode(decoded);

      print("Payload décodé : $jsonMap");

      final user = jsonMap['user'];
      if (user != null && user['_id'] != null) {
        return user['_id'].toString();
      }

      return jsonMap['userId']?.toString() ?? jsonMap['id']?.toString();
    } catch (e) {
      print('Erreur de décodage token: $e');
      return null;
    }
  }

 Future<void> toggleParticipation() async {
  setState(() {
    _isLoadingi = true; // Active l'indicateur de chargement
  });

  try {
    // Animation de clic
    await _animationController.forward();
    await _animationController.reverse();
    
    final token = await storage.read(key: 'token');
    if (token == null) {
      throw Exception('Authentification requise');
    }

    final userId = await _getUserIdFromToken(token);
    if (userId == null) {
      print('Impossible d\'extraire l\'ID utilisateur du token');
      return;
    }

    // On choisit l'URL et la méthode HTTP en fonction de l'état actuel
    final bool isCurrentlyParticipating = _isParticipating;
    final String endpoint = isCurrentlyParticipating 
      ? 'https://dumum-tergo-backend.onrender.com/api/sortiecamping/${widget.eventId}/annulerparticiper'
      : 'https://dumum-tergo-backend.onrender.com/api/sortiecamping/${widget.eventId}/participer';

    print("Envoi requête à: $endpoint");

    final response = isCurrentlyParticipating
      ? await http.delete(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'userId': userId}),
        )
      : await http.post(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'userId': userId}),
        );

    print("Réponse reçue: ${response.statusCode}");
    print("Corps de la réponse: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final participants = List.from(decoded['event']['participants'] ?? []);
      final isNowParticipating = participants.any((p) => p['_id'] == userId);
      
      setState(() {
        _event = decoded['event'];
        _isParticipating = isNowParticipating;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNowParticipating 
              ? 'Vous participez maintenant à cet événement!' 
              : 'Votre participation a été annulée'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final errorResponse = json.decode(response.body);
      final errorMessage = errorResponse['message'] ?? 'Erreur inconnue';
      throw Exception(errorMessage);
    }
  } on http.ClientException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Problème de connexion: ${e.message}'),
        duration: const Duration(seconds: 2),
      ),
    );
  } on Exception catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: ${e.toString()}'),
        duration: const Duration(seconds: 2),
      ),
    );
  } finally {
    setState(() {
      _isLoadingi = false; // Désactive l'indicateur de chargement
    });
  }
}
void _showAllParticipants() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // coins arrondis propres
    builder: (context) {
      final theme = Theme.of(context);

      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          // fond selon le thème (clair/sombre)
          color: theme.cardTheme.color ?? (theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Barre grise selon thème
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Text(
              'Participants',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: (_event!['participants'] as List).length,
                itemBuilder: (context, index) {
                  final participant = _event!['participants'][index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: participant['image'] != null
                          ? NetworkImage(
                              'https://res.cloudinary.com/dcs2edizr/image/upload/${participant['image']}',
                            )
                          : null,
                      child: participant['image'] == null
                          ? Text(
                              participant['name'] != null && participant['name'].isNotEmpty
                                  ? participant['name'][0]
                                  : '?',
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      participant['name'] ?? 'Participant',
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: participant['email'] != null
                        ? Text(
                            participant['email'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}


  Widget _buildWeatherIcon(int weatherCode) {
    // Mapping simplifié des codes météo WMO
    if (weatherCode == 0) return const Icon(Icons.wb_sunny, color: Colors.orange);
    if (weatherCode <= 3) return const Icon(Icons.cloud, color: Colors.grey);
    if (weatherCode <= 48) return const Icon(Icons.foggy, color: Colors.grey);
    if (weatherCode <= 67 || weatherCode == 80 || weatherCode == 81 || weatherCode == 82) 
      return const Icon(Icons.umbrella, color: Colors.blue);
    if (weatherCode <= 77) return const Icon(Icons.ac_unit, color: Colors.lightBlue);
    if (weatherCode <= 99) return const Icon(Icons.flash_on, color: Colors.yellow);
    return const Icon(Icons.help_outline);
  }

  String _getWeatherDescription(int weatherCode) {
    // Descriptions basées sur les codes WMO
    const weatherDescriptions = {
      0: 'Ciel dégagé',
      1: 'Principalement dégagé',
      2: 'Partiellement nuageux',
      3: 'Couvert',
      45: 'Brouillard',
      48: 'Brouillard givrant',
      51: 'Bruine légère',
      53: 'Bruine modérée',
      55: 'Bruine dense',
      56: 'Bruine verglaçante légère',
      57: 'Bruine verglaçante dense',
      61: 'Pluie légère',
      63: 'Pluie modérée',
      65: 'Pluie forte',
      66: 'Pluie verglaçante légère',
      67: 'Pluie verglaçante forte',
      71: 'Chute de neige légère',
      73: 'Chute de neige modérée',
      75: 'Chute de neige forte',
      77: 'Grains de neige',
      80: 'Averses de pluie légères',
      81: 'Averses de pluie modérées',
      82: 'Averses de pluie violentes',
      85: 'Averses de neige légères',
      86: 'Averses de neige fortes',
      95: 'Orage léger ou modéré',
      96: 'Orage avec grêle légère',
      99: 'Orage avec grêle forte',
    };
    return weatherDescriptions[weatherCode] ?? 'Conditions inconnues';
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
appBar: AppBar(
  //backgroundColor: Colors.white, // couleur de fond
  elevation: 4, // ombre sous l'app bar
  centerTitle: true,
  title: const Text(
    'Détails de l\'événement',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
    
    ),
  ),
 
),

    body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
          )
        : _event == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 50, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      "Aucun détail trouvé",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carrousel d'images
                    if ((_event!['images'] as List).isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CarouselSlider.builder(
                            itemCount: _event!['images'].length,
                            options: CarouselOptions(
                              height: 250,
                              enlargeCenterPage: true,
                              enableInfiniteScroll: false,
                              enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                              autoPlay: true,
                              viewportFraction: 0.9,
                               onPageChanged: (index, reason) {
        setState(() {
          _currentImageIndex = index;
        });
      },
                            ),
                            itemBuilder: (context, index, realIndex) {
                              return GestureDetector(
                                onTap: () {
                                  final List<String> imageUrls =
                                      (_event!['images'] as List)
                                          .map((img) =>
                                              'https://res.cloudinary.com/dcs2edizr/image/upload/$img')
                                          .cast<String>()
                                          .toList();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FullScreenImageGallery(
                                        images: imageUrls,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: 'image_$index',
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        'https://res.cloudinary.com/dcs2edizr/image/upload/${_event!['images'][index]}',
                                    imageBuilder: (context, imageProvider) =>
                                        Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).primaryColor),
                                    )),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error,
                                          color: Colors.red),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: (_event!['images'] as List)
                            .asMap()
                            .entries
                            .map((entry) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _currentImageIndex == entry.key ? 12 : 8,
                            height: 8,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(4),
                              color: _currentImageIndex == entry.key
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[400],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Titre et bouton de participation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
color: Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).canvasColor	 // Couleur pour Dark Mode
      : Colors.white,                          borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _event!['lieu'] ?? 'Lieu non spécifié',
                                  style:  TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
color: Theme.of(context).brightness == Brightness.dark
      ? Colors.white	 // Couleur pour Dark Mode
      : Colors.black87,                                    ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _event!['titre'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Bouton de participation
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                if (_isLoadingi) return;
                                if (_isParticipating) {
                                  _showParticipationOptions();
                                } else {
                                  toggleParticipation();
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isParticipating
                                        ? [
                                            Colors.greenAccent,
                                            Colors.green[400]!,
                                          ]
                                        : [
                                            Colors.blueAccent,
                                            Colors.blue[700]!,
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isParticipating
                                              ? Colors.green
                                              : Colors.blue)
                                          .withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isLoadingi)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    else ...[
                                      Icon(
                                        _isParticipating
                                            ? Icons.emoji_events
                                            : Icons.event_available,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      _isLoadingi
                                          ? "Chargement..."
                                          : (_isParticipating
                                              ? "Je participe !"
                                              : "S'inscrire"),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date et lieu
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
color: Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).canvasColor	 // Couleur pour Dark Mode
      : Colors.white,                         borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.calendar_today,
                                    size: 20, color: Colors.blue[700]),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                                        .format(
                                      DateTime.parse(_event!['date']),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.location_on,
                                    size: 20, color: Colors.red[700]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lieu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _event!['location']['address'] ??
                                          'Adresse non spécifiée',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
color: Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).canvasColor	 // Couleur pour Dark Mode
      : Colors.white,                         borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description,
                                  color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _event!['description'] ??
                                'Pas de description disponible',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Météo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue[100]!,
                            Colors.blue[50]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cloud,
                                  color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Météo prévue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isWeatherLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue),
                                  ),
                                )
                              : _weatherData != null
                                  ? Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            children: [
                                              _buildWeatherIcon(
                                                  _weatherData!['weather_code']),
                                              const SizedBox(height: 8),
                                              Text(
                                                _getWeatherDescription(
                                                    _weatherData![
                                                        'weather_code']),
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              const Text(
                                                'Max',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey),
                                              ),
                                              Text(
                                                '${_weatherData!['max_temp']?.toStringAsFixed(1) ?? 'N/A'}°C',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              const Text(
                                                'Min',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey),
                                              ),
                                              Text(
                                                '${_weatherData!['min_temp']?.toStringAsFixed(1) ?? 'N/A'}°C',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text(
                                            'Aucune donnée météo disponible',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Participants
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
color: Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).canvasColor	 // Couleur pour Dark Mode
      : Colors.white,                         borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people,
                                  color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Text(
                                'Participants',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  '${(_event!['participants'] as List).length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                backgroundColor:
                                    Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 2,
                              ),
                              const Spacer(),
                              if ((_event!['participants'] as List).isNotEmpty)
                                TextButton(
                                  onPressed: _showAllParticipants,
                                  child: Text(
                                    'Voir tout',
                                    style: TextStyle(
color: Theme.of(context).brightness == Brightness.dark
      ? Colors.white	 // Couleur pour Dark Mode
      : Colors.black87,                                       fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if ((_event!['participants'] as List).isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  "Aucun participant pour le moment",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 71,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    (_event!['participants'] as List).length,
                                itemBuilder: (context, index) {
                                  final participant =
                                      _event!['participants'][index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundColor: Colors.grey[200],
                                          backgroundImage:
                                              participant['image'] != null
                                                  ? NetworkImage(
                                                      'https://res.cloudinary.com/dcs2edizr/image/upload/${participant['image']}',
                                                    ) as ImageProvider
                                                  : null,
                                          child: participant['image'] == null
                                              ? Text(
                                                  participant['name'][0],
                                                  style: const TextStyle(
                                                      color: Colors.black54),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          participant['name'].split(' ')[0],
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Carte
                    Container(
                      padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
  color: Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).canvasColor	 // Couleur pour Dark Mode
      : Colors.white,    // Couleur pour Light Mode
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ],
),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.map,
                                  color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              const Text(
                                'Localisation',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FullScreenMap(
                                    position: LatLng(
                                      _event!['location']['coordinates'][1],
                                      _event!['location']['coordinates'][0],
                                    ),
                                    lieu: _event!['lieu'],
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: AbsorbPointer(
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(
                                        _event!['location']['coordinates'][1],
                                        _event!['location']['coordinates'][0],
                                      ),
                                      initialZoom: 14.0,
                                      interactionOptions:
                                          const InteractionOptions(
                                        flags: ~InteractiveFlag.all,
                                      ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.example.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            width: 40.0,
                                            height: 40.0,
                                            point: LatLng(
                                              _event!['location']
                                                  ['coordinates'][1],
                                              _event!['location']
                                                  ['coordinates'][0],
                                            ),
                                            child: const Icon(
                                              Icons.location_pin,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenMap(
                                      position: LatLng(
                                        _event!['location']['coordinates'][1],
                                        _event!['location']['coordinates'][0],
                                      ),
                                      lieu: _event!['lieu'],
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Voir en plein écran',
                                    style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
      ? Colors.white	 // Couleur pour Dark Mode
      : Colors.black, 
      
                                            fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.fullscreen,
                                    size: 18,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
  );
}

}