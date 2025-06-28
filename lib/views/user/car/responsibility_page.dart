import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/user/car/confirmation_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ResponsibilityPage extends StatefulWidget {
  final Map<String, dynamic> car;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String pickupLocation;
  final double totalPrice;
  final int additionalDrivers;
  final int childSeats;
  
  ResponsibilityPage({
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
  _ResponsibilityPageState createState() => _ResponsibilityPageState();
}

class _ResponsibilityPageState extends State<ResponsibilityPage> {
  bool isCautionAccepted = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) {
      if (mounted) setState(() {});
    });
  }

  String formatDate(DateTime date) {
    return DateFormat('EEE d MMM · HH:mm', 'fr_FR').format(date);
  }

  Widget _buildStepsHeader() {
    return Column(
      children: [
        const Text(
          'Étape 2/3',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Responsabilité et Caution',
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
              )),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
             )),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
               ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Responsabilité et Caution"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepsHeader(),
              const SizedBox(height: 24),
              
              Text(
                "En louant ce véhicule, vous acceptez d'être responsable de tout dommage qui pourrait survenir pendant la période de location. Une caution sera également exigée pour couvrir toute éventualité.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              
              // Caution
              CheckboxListTile(
                title: Text("Caution de ${widget.car['deposit']} TND (non remboursable en cas de dommage)"),
                value: isCautionAccepted,
                onChanged: (bool? value) {
                  setState(() {
                    isCautionAccepted = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              
              // Responsabilité du client
              Text(
                "Responsabilité du client : Vous serez tenu responsable de tout dommage causé au véhicule pendant la période de location.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              
              // Résumé de la réservation avec nouveau design
              Text("Résumé de votre réservation :", 
                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 16),
              
              // Nouveau design avec points et ligne
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colonne des points et ligne
                    Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 40,
                          color: Colors.grey,
                          margin: EdgeInsets.symmetric(vertical: 4),
                        ),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(width: 16),
                    
                    // Colonne des dates et lieux
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDate(widget.pickupDate),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.pickupLocation,
                            style: TextStyle(color: Colors.grey),
                          ),
                          
                          SizedBox(height: 24),
                          
                          Text(
                            formatDate(widget.returnDate),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.pickupLocation,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 40, thickness: 1),
              
              // Détail du tarif
              Text("Détail du tarif de la location", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Location"),
                  Text(
                    '${widget.totalPrice.toStringAsFixed(2)} TND',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Caution"),
                  Text(
                    '${widget.car['deposit']} TND',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total à payer",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(widget.totalPrice + widget.car['deposit']).toStringAsFixed(2)} TND',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Bouton de confirmation
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton(
                  onPressed: isCautionAccepted
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ConfirmationPage(
                              car: widget.car,
                              pickupDate: widget.pickupDate,
                              returnDate: widget.returnDate,
                              additionalDrivers: widget.additionalDrivers,
                              childSeats: widget.childSeats,
                              pickupLocation: widget.pickupLocation,
                              totalPrice: widget.totalPrice,
                            )),
                          );
                        }
                      : null,
                  child: Text("Confirmer la réservation"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}