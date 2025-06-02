import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/seller/car/search-location.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class AddCarRentalPage extends StatefulWidget {
  @override
  _AddCarRentalPageState createState() => _AddCarRentalPageState();
}

class _AddCarRentalPageState extends State<AddCarRentalPage> {
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _pricePerDayController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isExpanded = false;
  bool isLoadingMakes = false;
  bool isLoadingModels = false;
bool isSubmitting = false;
  List<String> years = [];
  List<Map<String, dynamic>> makes = [];
  List<Map<String, dynamic>> models = [];
  String? selectedYear;
  String? selectedMakeId;
  String? selectedModel;
  String? selectedTransmission = 'manuelle';
  String? selectedMileagePolicy = 'illimitée';
  List<XFile> _vehicleImages = [];
  List<String> selectedFeatures = [];

  final List<String> availableFeatures = [
    'Climatisation',
    'GPS',
    'Sièges chauffants',
    'Toit ouvrant',
    'Caméra de recul',
    'Régulateur de vitesse',
    'Bluetooth',
    'Airbags',
    'ABS',
    'ESP'
  ];

  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchYears();
  }

  Future<void> _fetchYears() async {
    final response = await http.get(Uri.parse('https://www.carqueryapi.com/api/0.3/?cmd=getYears'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body.replaceAll('?(', '').replaceAll(');', ''));
      setState(() {
        years = List<String>.generate(
          int.parse(data['Years']['max_year']) - int.parse(data['Years']['min_year']) + 1,
          (index) => (int.parse(data['Years']['min_year']) + index).toString(),
        ).reversed.toList();
      });
    }
  }

  Future<void> _fetchMakes(String year) async {
    setState(() {
      isLoadingMakes = true;
      makes = [];
      selectedMakeId = null;
      models = [];
      selectedModel = null;
    });

    final response = await http.get(Uri.parse('https://www.carqueryapi.com/api/0.3/?cmd=getMakes&year=$year'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body.replaceAll('?(', '').replaceAll(');', ''));
      setState(() {
        makes = List<Map<String, dynamic>>.from(data['Makes']);
      });
    }

    setState(() {
      isLoadingMakes = false;
    });
  }

  Future<void> _fetchModels(String makeId, String year) async {
    setState(() {
      isLoadingModels = true;
      models = [];
      selectedModel = null;
    });

    final response = await http.get(Uri.parse('https://www.carqueryapi.com/api/0.3/?cmd=getModels&make=$makeId&year=$year'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body.replaceAll('?(', '').replaceAll(');', ''));
      setState(() {
        models = List<Map<String, dynamic>>.from(data['Models']);
      });
    }

    setState(() {
      isLoadingModels = false;
    });
  }

  String _formatMatricule(String input) {
    input = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (input.length > 7) {
      input = input.substring(0, 7);
    }

    String formatted = '';
    if (input.length >= 3) {
      formatted = input.substring(0, 3) + 'Tu';
      if (input.length > 3) {
        formatted += input.substring(3);
      }
    } else {
      formatted = input;
    }

    return formatted;
  }

  void _onRegistrationNumberChanged(String value) {
    final formattedValue = _formatMatricule(value);
    if (formattedValue != _registrationNumberController.text) {
      _registrationNumberController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedImages = await picker.pickMultiImage();
    if (pickedImages.isNotEmpty) {
      setState(() {
        _vehicleImages.addAll(pickedImages);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_vehicleImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez ajouter au moins une image')),
      );
      return;
    }
   setState(() {
      isSubmitting = true; // Activer l'indicateur de chargement
    });
    const url = 'https://dumum-tergo-backend.onrender.com/api/cars';
    final token = await storage.read(key: 'seller_token');

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields.addAll({
        'brand': _brandController.text,
        'model': _modelController.text,
        'year': _yearController.text,
        'registrationNumber': _registrationNumberController.text,
        'color': _colorController.text,
        'seats': _seatsController.text,
        'pricePerDay': _pricePerDayController.text,
        'transmission': selectedTransmission ?? 'manuelle',
        'mileagePolicy': selectedMileagePolicy ?? 'illimitée',
        'location': _locationController.text,
        'deposit': _depositController.text,
        'description': _descriptionController.text,
        'features': jsonEncode(selectedFeatures),
      });

      for (var i = 0; i < _vehicleImages.length; i++) {
        final image = _vehicleImages[i];
        final file = File(image.path);
        
        try {
          if (!await file.exists()) {
            debugPrint('Fichier introuvable: ${file.path}');
            continue;
          }

          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            debugPrint('Fichier trop volumineux: ${file.path}');
            continue;
          }

          final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
          final contentType = mimeType.split('/');

          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            file.path,
            filename: 'car_${DateTime.now().millisecondsSinceEpoch}_$i.${file.path.split('.').last}',
            contentType: MediaType(contentType[0], contentType[1]),
          );

          request.files.add(multipartFile);
          debugPrint('Image ajoutée: ${file.path}');
        } catch (e) {
          debugPrint('Erreur lors du traitement de l\'image ${file.path}: $e');
        }
      }

      if (request.files.isEmpty) {
        throw Exception('Aucune image valide à envoyer');
      }

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Réponse complète: $responseBody');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voiture créée avec succès!')),
        );
        Navigator.of(context).pop(true);
      } else {
        final error = jsonDecode(responseBody);
        throw Exception(error['message'] ?? 'Erreur inconnue du serveur');
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le serveur ne répond pas')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
      debugPrint('Erreur complète: $e');
    }finally {
      if (mounted) {
        setState(() {
          isSubmitting = false; // Désactiver l'indicateur de chargement
        });
      }
    }
  }

  void _resetForm() {
    _brandController.clear();
    _modelController.clear();
    _yearController.clear();
    _registrationNumberController.clear();
    _colorController.clear();
    _seatsController.clear();
    _pricePerDayController.clear();
    _locationController.clear();
    _depositController.clear();
    _descriptionController.clear();
    setState(() {
      _vehicleImages.clear();
      selectedYear = null;
      selectedMakeId = null;
      selectedModel = null;
      selectedFeatures.clear();
    });
  }

  Widget _buildStepIndicator() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentStep >= 0 ? AppColors.primary : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Détails',
                  style: TextStyle(
                    color: _currentStep >= 0 ? AppColors.primary : (isDarkMode ? Colors.grey[400] : Colors.grey),
                    fontWeight: _currentStep == 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentStep >= 1 ? AppColors.primary : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tarification',
                  style: TextStyle(
                    color: _currentStep >= 1 ? AppColors.primary : (isDarkMode ? Colors.grey[400] : Colors.grey),
                    fontWeight: _currentStep == 1 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, {String? hintText, Widget? suffixIcon}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: isDarkMode ? Colors.grey[800]! : Colors.grey[50]!,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildVehicleDetailsStep() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850]! : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Détails du véhicule'),
          DropdownButtonFormField<String>(
            decoration: _buildInputDecoration('Année'),
            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            value: selectedYear,
            items: years.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(year),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedYear = value;
                _yearController.text = value!;
              });
              _fetchMakes(value!);
            },
            validator: (value) => value == null ? 'Veuillez sélectionner une année' : null,
          ),
          SizedBox(height: 20),
          if (isLoadingMakes)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Chargement des marques...",
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          DropdownButtonFormField<String>(
            decoration: _buildInputDecoration('Marque'),
            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            value: selectedMakeId,
            items: makes.map((make) {
              return DropdownMenuItem<String>(
                value: make['make_id'] as String,
                child: Text(make['make_display']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedMakeId = value;
                _brandController.text = makes.firstWhere((make) => make['make_id'] == value)['make_display'];
                selectedModel = null;
                _modelController.clear();
                if (selectedYear != null) {
                  _fetchModels(value!, selectedYear!);
                }
              });
            },
            validator: (value) => value == null ? 'Veuillez sélectionner une marque' : null,
          ),
          SizedBox(height: 20),
          if (isLoadingModels)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Chargement des modèles...",
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          DropdownButtonFormField<String>(
            decoration: _buildInputDecoration('Modèle'),
            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            value: selectedModel,
            items: models.map((model) {
              return DropdownMenuItem<String>(
                value: model['model_name'] as String,
                child: Text(model['model_name']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedModel = value;
                _modelController.text = value!;
              });
            },
            validator: (value) => value == null ? 'Veuillez sélectionner un modèle' : null,
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _registrationNumberController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: _buildInputDecoration(
              'Numéro d\'immatriculation*',
              hintText: 'Ex: 123Tu4567',
            ),
            onChanged: _onRegistrationNumberChanged,
            validator: (value) => value == null || value.isEmpty
                ? 'Veuillez entrer un numéro d\'immatriculation'
                : null,
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _colorController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: _buildInputDecoration('Couleur*'),
            validator: (value) => value == null || value.isEmpty
                ? 'Veuillez entrer une couleur'
                : null,
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _seatsController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            keyboardType: TextInputType.number,
            decoration: _buildInputDecoration('Nombre de sièges*'),
            validator: (value) => value == null || value.isEmpty
                ? 'Veuillez entrer le nombre de sièges'
                : null,
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: _buildInputDecoration('Transmission*'),
            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            value: selectedTransmission,
            items: [
              DropdownMenuItem(value: 'automatique', child: Text('Automatique')),
              DropdownMenuItem(value: 'manuelle', child: Text('Manuelle')),
            ],
            onChanged: (value) {
              setState(() {
                selectedTransmission = value;
              });
            },
            validator: (value) => value == null ? 'Veuillez sélectionner une transmission' : null,
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: _buildInputDecoration('Politique de Kilométrage*'),
            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            value: selectedMileagePolicy,
            items: [
              DropdownMenuItem(value: 'limitée', child: Text('Limitée')),
              DropdownMenuItem(value: 'illimitée', child: Text('Illimitée')),
            ],
            onChanged: (value) {
              setState(() {
                selectedMileagePolicy = value;
              });
            },
            validator: (value) => value == null ? 'Veuillez sélectionner une politique de kilométrage' : null,
          ),
          SizedBox(height: 24),
          _buildSectionTitle('Caractéristiques'),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: availableFeatures.map((feature) {
              return FilterChip(
                label: Text(feature),
                selected: selectedFeatures.contains(feature),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedFeatures.add(feature);
                    } else {
                      selectedFeatures.remove(feature);
                    }
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                backgroundColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                labelStyle: TextStyle(
                  color: selectedFeatures.contains(feature) 
                      ? AppColors.primary 
                      : (isDarkMode ? Colors.white : Colors.grey[800]),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: selectedFeatures.contains(feature) 
                        ? AppColors.primary 
                        : (isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24),
          _buildSectionTitle('Photos du véhicule'),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _pickImages,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                backgroundColor: AppColors.primary,
                shadowColor: Colors.black.withOpacity(0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Ajouter des Photos du Véhicule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_vehicleImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${_vehicleImages.length} photo(s) sélectionnée(s)',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: 20),
          _vehicleImages.isEmpty
              ?Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      'Aucune photo sélectionnée',
      style: TextStyle(
        fontSize: 16,
        color: isDarkMode ? Colors.grey[400] : Colors.grey,
      ),
      textAlign: TextAlign.center,
    ),
  ),
)

      
              : GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _vehicleImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.file(
                              File(_vehicleImages[index].path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800]! : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                              icon: Icon(Icons.close, color: Colors.red, size: 20),
                              onPressed: () {
                                setState(() {
                                  _vehicleImages.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
    ),
        ],)
      );
  
  }

  Widget _buildTarificationLocationStep() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850]! : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Tarification et localisation'),
          TextFormField(
            controller: _pricePerDayController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: _buildInputDecoration(
              'Prix par jour (TND)*',
              suffixIcon: Icon(Icons.attach_money, color: AppColors.primary),
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Veuillez entrer le prix'
                : null,
          ),
          SizedBox(height: 20),
          SearchLocationField(controller: _locationController),
          SizedBox(height: 20),
          TextFormField(
            controller: _depositController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: _buildInputDecoration(
              'Dépôt de garantie (TND)*',
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Veuillez entrer un dépôt de garantie'
                : null,
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _descriptionController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            maxLines: 3,
            decoration: _buildInputDecoration(
              'Description',
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Veuillez entrer une description'
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        title: Text(
          _currentStep == 0 ? 'Détails du véhicule' : 'Tarification et localisation',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _currentStep == 0 
                        ? _buildVehicleDetailsStep() 
                        : _buildTarificationLocationStep(),
                    SizedBox(height: 24),
                    Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    if (_currentStep > 0)
      ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _currentStep--;
          });
          _scrollToTop();
        },
        icon: Icon(Icons.arrow_back),
        label: Text('Retour'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          foregroundColor: isDarkMode ? Colors.white : Colors.black87,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    Expanded(child: Container()),
    ElevatedButton(
      onPressed: isSubmitting
          ? null
          : () {
              if (_currentStep == 0) {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _currentStep++;
                  });
                  _scrollToTop();
                }
              } else {
                _submitForm();
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isSubmitting
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_currentStep == 0 ? Icons.arrow_forward : Icons.check),
                SizedBox(width: 8),
                Text(
                  _currentStep == 0 ? 'Suivant' : 'Ajouter Voiture',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
            ),
          ],
        ),
      ),
    );
  }
}