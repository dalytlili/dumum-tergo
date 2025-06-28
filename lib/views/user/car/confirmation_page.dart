import 'package:country_picker/country_picker.dart';
import 'package:dumum_tergo/services/reservation_service.dart';
import 'package:dumum_tergo/views/user/car/reservation_success_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/constants/countries.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> car;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String pickupLocation;
  final double totalPrice;
  final int additionalDrivers;
  final int childSeats;

  const ConfirmationPage({
    Key? key,
    required this.car,
    required this.pickupLocation,
    required this.totalPrice,
    required this.pickupDate,
    required this.returnDate,
    required this.additionalDrivers,
    required this.childSeats,
  }) : super(key: key);

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController dateNaissanceController = TextEditingController();
  bool _isLoading = false;
  String _documentType = 'cin'; // 'cin' ou 'passport'
  File? _passportImage;
  String email = "";
  String telephone = "";

  Country selectedCountry = Country.parse("TN");
  bool isDateValid = true;

  // Images
  File? _permisRectoImage;
  File? _permisVersoImage;
  File? _cinRectoImage;
  File? _cinVersoImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmation de réservation"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec étapes
            _buildStepsHeader(),
            const SizedBox(height: 24),
            
            // Carte d'information
            _buildInfoCard(),
            const SizedBox(height: 32),
            
            // Formulaire
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Informations conducteur
                  _buildSectionTitle(
                    title: "Informations sur le conducteur principal",
                    subtitle: "Conformes au permis de conduire",
                  ),
                  
                  // Champ Email
                  _buildEmailField(),
                  const SizedBox(height: 20),
                  
                  // Champ Téléphone
                  _buildPhoneField(),
                  const SizedBox(height: 20),
                  
                  // Section Documents
                  _buildDocumentsSection(),
                  const SizedBox(height: 20),
                  
                  // Bouton de confirmation
                  _buildConfirmationButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsHeader() {
    return Column(
      children: [
        const Text(
          'Étape 3/3',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Confirmez votre réservation',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
              ),
            ),),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
              ),
            ),),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
               ) ),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildInfoCard() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              "Votre véhicule est disponible",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "Réservez maintenant pour garantir votre véhicule "
          "${widget.car['brand']} ${widget.car['model']} "
          "à ${widget.pickupLocation}",
          style: TextStyle(
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
       Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Début",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: DateFormat('EEE d MMM', 'fr_FR').format(widget.pickupDate) + '\n',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: DateFormat('HH:mm', 'fr_FR').format(widget.pickupDate),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          textAlign: TextAlign.start,
        ),
      ],
    ),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fin",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: DateFormat('EEE d MMM', 'fr_FR').format(widget.returnDate) + '\n',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: DateFormat('HH:mm', 'fr_FR').format(widget.returnDate),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          textAlign: TextAlign.start,
        ),
      ],
    ),
    Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "Total",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          "${widget.totalPrice.toStringAsFixed(2)} TND",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  ],
),

      ],
    ),
  );
}

  Widget _buildSectionTitle({required String title, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Adresse e-mail *",
        labelStyle: TextStyle(color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2),
        ),
        hintText: "exemple@email.com",
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: const Icon(Icons.email_outlined),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Veuillez entrer votre e-mail";
        }
        final emailRegex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );
        if (!emailRegex.hasMatch(value)) {
          return "Veuillez entrer une adresse e-mail valide";
        }
        return null;
      },
      onSaved: (value) => email = value!,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: phoneNumberController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: "Numéro de téléphone *",
        labelStyle: TextStyle(color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2),
        ),
        prefixIcon: InkWell(
          onTap: () {
            showCountryPicker(
              context: context,
              showPhoneCode: true,
              countryListTheme: CountryListThemeData(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelect: (Country country) {
                setState(() {
                  selectedCountry = country;
                });
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedCountry.flagEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${selectedCountry.phoneCode}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre numéro de téléphone';
        }
        if (!RegExp(r'^\d+$').hasMatch(value)) {
          return 'Veuillez entrer un numéro valide';
        }
        return null;
      },
      onSaved: (value) => telephone = value!,
    );
  }
Widget _buildDocumentTypeSelector() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Type de pièce d'identité *",
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: const Text('CIN'),
              value: 'cin',
              groupValue: _documentType,
              onChanged: (String? value) {
                setState(() {
                  _documentType = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: const Text('Passeport'),
              value: 'passport',
              groupValue: _documentType,
              onChanged: (String? value) {
                setState(() {
                  _documentType = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ],
      ),
    ],
  );
}
Widget _buildDocumentsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle(
        title: "Documents requis",
        subtitle: "Veuillez télécharger les documents suivants",
      ),
      
      // Choix du type de document
      _buildDocumentTypeSelector(),
      const SizedBox(height: 16),
      
      // Permis recto/verso (toujours requis)
      Row(
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildDocumentUpload(
                title: "Permis (Recto)",
                imageFile: _permisRectoImage,
                imageType: 'permis_recto',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _buildDocumentUpload(
                title: "Permis (Verso)",
                imageFile: _permisVersoImage,
                imageType: 'permis_verso',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Section conditionnelle selon le type de document
      if (_documentType == 'cin')
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _buildDocumentUpload(
                  title: "CIN (Recto)",
                  imageFile: _cinRectoImage,
                  imageType: 'cin_recto',
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _buildDocumentUpload(
                  title: "CIN (Verso)",
                  imageFile: _cinVersoImage,
                  imageType: 'cin_verso',
                ),
              ),
            ),
          ],
        )
      else
        _buildDocumentUpload(
          title: "Passeport",
          imageFile: _passportImage,
          imageType: 'passport',
        ),
      
      // Validation des documents
      if (_permisRectoImage == null || _permisVersoImage == null || 
          (_documentType == 'cin' && (_cinRectoImage == null || _cinVersoImage == null)) ||
          (_documentType == 'passport' && _passportImage == null))
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "* Veuillez télécharger tous les documents requis",
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 12,
            ),
          ),
        ),
    ],
  );
}

Widget _buildDocumentUpload({
  required String title,
  required File? imageFile,
  required String imageType,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => _showImageSourceDialog(imageType),
        child: Container(
          height: 120,
          width: double.infinity, // Prend toute la largeur disponible
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(imageFile, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Télécharger',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ],
  );
}
  Widget _buildConfirmationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "CONFIRMER LA RÉSERVATION",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Future<void> _showImageSourceDialog(String imageType) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, imageType: imageType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, imageType: imageType);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, {required String imageType}) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    setState(() {
      final file = File(pickedFile.path);
      switch (imageType) {
        case 'permis_recto':
          _permisRectoImage = file;
          break;
        case 'permis_verso':
          _permisVersoImage = file;
          break;
        case 'cin_recto':
          _cinRectoImage = file;
          break;
        case 'cin_verso':
          _cinVersoImage = file;
          break;
        case 'passport':
          _passportImage = file;
          break;
      }
    });
  }
}


Future<void> _submitReservation() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;
  if (!isDateValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veuillez sélectionner une date de naissance valide'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Vérification des images
  if (_permisRectoImage == null || _permisVersoImage == null || 
      (_documentType == 'cin' && (_cinRectoImage == null || _cinVersoImage == null)) ||
      (_documentType == 'passport' && _passportImage == null)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veuillez télécharger tous les documents requis'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);
  _formKey.currentState!.save();

  try {
    final reservationData = await ReservationService().createReservation(
      carId: widget.car['_id'],
      startDate: widget.pickupDate,
      endDate: widget.returnDate,
      childSeats: widget.childSeats,
      additionalDrivers: widget.additionalDrivers,
      location: widget.pickupLocation,
      driverEmail: email,
      driverPhoneNumber: '+${selectedCountry.phoneCode}${phoneNumberController.text}',
      permisRectoImage: _permisRectoImage!,
      permisVersoImage: _permisVersoImage!,
      cinRectoImage: _documentType == 'cin' ? _cinRectoImage : null,
      cinVersoImage: _documentType == 'cin' ? _cinVersoImage : null,
      passportImage: _documentType == 'passport' ? _passportImage : null,
    );

    if (!mounted) return;
    
    final combinedData = {
      ...reservationData,
      'car': widget.car,
      'totalPrice': widget.totalPrice,
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationSuccessPage(
          reservationData: combinedData,
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
}