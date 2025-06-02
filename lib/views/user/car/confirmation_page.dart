import 'package:country_picker/country_picker.dart';
import 'package:dumum_tergo/services/reservation_service.dart';
import 'package:dumum_tergo/views/user/car/reservation_success_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/constants/countries.dart';

class ConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> car;
 final DateTime pickupDate;
  final DateTime returnDate;
  final String pickupLocation;
  final double totalPrice; // Nouveau paramètre
 final int additionalDrivers; // Ajoutez cette ligne
  final int childSeats;

  const ConfirmationPage({
    Key? key,
   required this.car,
            required this.pickupLocation,
    required this.totalPrice, // Ajout du paramètre

    required this.pickupDate,
    required this.returnDate,
        required this.additionalDrivers, // Ajoutez cette ligne
    required this.childSeats,
  }) : super(key: key);

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController dateNaissanceController = TextEditingController();
  bool _isLoading = false; // Ajoutez cette variable

  String email = "";
  String prenom = "";
  String nom = "";
  String pays = "Tunisie";
  Country selectedCountry = Country.parse("TN");
  String? selectedDay;
  String? selectedMonth;
  String? selectedYear;
  bool isDateValid = true;

  String formatDate(DateTime date) {
    return DateFormat('EEE d MMM · HH:mm', 'fr_FR').format(date);
  }
 // Listes pour les dropdowns
  final List<String> days = List.generate(31, (index) => (index + 1).toString());
 final List<String> months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];
  final List<String> years = List.generate(100, (index) => (DateTime.now().year - 17 - index).toString());

  // Validation de la date
  void _validateDate() {
    setState(() {
      isDateValid = selectedDay != null && selectedMonth != null && selectedYear != null;
    });
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

  setState(() => _isLoading = true);
  _formKey.currentState!.save();

  try {
    final monthIndex = months.indexOf(selectedMonth!) + 1;
    final formattedBirthDate = '${selectedYear}-${monthIndex.toString().padLeft(2, '0')}-${selectedDay!.padLeft(2, '0')}';

    final reservationData = await ReservationService().createReservation(
      carId: widget.car['_id'],
      startDate: widget.pickupDate,
      endDate: widget.returnDate,
      childSeats: widget.childSeats,
      additionalDrivers: widget.additionalDrivers,
      location: widget.pickupLocation,
      driverEmail: email,
      driverFirstName: prenom,
      driverLastName: nom,
      driverBirthDate: formattedBirthDate,
      driverPhoneNumber: '+${selectedCountry.phoneCode}${phoneNumberController.text}',
      driverCountry: pays,
    );

    if (!mounted) return;
    
    // Créer un objet combiné contenant à la fois les données de réservation et la voiture
    final combinedData = {
      ...reservationData,
      'car': widget.car, // Ajoutez l'objet car complet
      'totalPrice': widget.totalPrice, // Ajoutez le prix total
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationSuccessPage(
          reservationData: combinedData, // Envoyez les données combinées
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
  @override
  Widget build(BuildContext context) {
    String telephone;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmation"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Confirmation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Prochaine étape : Confirmer la réservation'),
            const SizedBox(height: 24),

                         Row(
  children: [
    Expanded(
      child: Column(
        children: [
          Container(height: 2, color: AppColors.primary),
          const SizedBox(height: 4),
        ],
      ),
    ),
    Expanded(
      child: Column(
        children: [
          Container(height: 2, color: AppColors.primary),
          const SizedBox(height: 4),
        ],
      ),
    ),
    Expanded(
      child: Column(
        children: [
          Container(height: 2, color: AppColors.primary),
          const SizedBox(height: 4),
        ],
      ),
    ),
  ],
),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Préparez-vous à vivre une nouvelle aventure...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Réservez dès maintenant, votre voiture vous attend déjà !",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Informations sur le conducteur principal",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Conformes au permis de conduire",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Email
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Adresse e-mail *",
                      border: OutlineInputBorder(),
                      hintText: "Nous pourrons ainsi vous envoyer l'e-mail de confirmation",
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
                  ),
                  const SizedBox(height: 15),

                  // Prénom
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Prénom *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Veuillez entrer votre prénom";
                      }
                      return null;
                    },
                    onSaved: (value) => prenom = value!,
                  ),
                  const SizedBox(height: 15),

                  // Nom
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Nom *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Veuillez entrer votre nom";
                      }
                      return null;
                    },
                    onSaved: (value) => nom = value!,
                  ),
                  const SizedBox(height: 15),

                  // Date de naissance
                  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Date de naissance *",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                
                 Row(
  children: [
    Expanded(
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        hint: const Text('Jour'),
        value: selectedDay,
        items: days.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
        onChanged: (value) {
          setState(() {
            selectedDay = value;
            _validateDate();
          });
        },
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      flex: 2,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        hint: const Text('Mois'),
        value: selectedMonth,
        items: months.map((month) => DropdownMenuItem(value: month, child: Text(month))).toList(),
        onChanged: (value) {
          setState(() {
            selectedMonth = value;
            _validateDate();
          });
        },
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        hint: const Text('Année'),
        value: selectedYear,
        items: years.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
        onChanged: (value) {
          setState(() {
            selectedYear = value;
            _validateDate();
          });
        },
      ),
    ),
  ],

                ),
                if (!isDateValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Veuillez sélectionner une date complète",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
                  const SizedBox(height: 15),

                  // Numéro de téléphone avec country picker
                  TextFormField(
                    controller: phoneNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Numéro de téléphone',
                      prefixIcon: InkWell(
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            showPhoneCode: true,
                            onSelect: (Country country) {
                              setState(() {
                                selectedCountry = country;
                              });
                            },
                          );
                        },
                        child: Padding(
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
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white70
                                      : Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
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
                  ),
                  const SizedBox(height: 15),

                  // Pays de résidence
                  PopupMenuButton<String>(
                    itemBuilder: (BuildContext context) {
                      return countries.map((String value) {
                        return PopupMenuItem<String>(
                          value: value,
                          child: SizedBox(
                            width: 200,
                            child: Text(value),
                          ),
                        );
                      }).toList();
                    },
                    onSelected: (value) => setState(() {
                      pays = value;
                    }),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Pays de résidence *",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(pays),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bouton de soumission
             ElevatedButton(
        onPressed: _isLoading ? null : _submitReservation,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Confirmer la réservation"),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
                                    const SizedBox(height: 20),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}