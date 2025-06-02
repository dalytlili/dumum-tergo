import 'package:dumum_tergo/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchLocationField extends StatefulWidget {
  final TextEditingController controller;

  SearchLocationField({required this.controller});

  @override
  _SearchLocationFieldState createState() => _SearchLocationFieldState();
}

class _SearchLocationFieldState extends State<SearchLocationField> {
  List<Map<String, String>> filteredLocations = [];
  bool isLoading = false;
  String errorMessage = "";

  // Méthode pour récupérer les lieux
  Future<void> _fetchLocations(String query) async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/cars/searchLocations?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          filteredLocations = data.map((location) {
            return {
              "title": location['title'] as String? ?? "Lieu inconnu",
              "subtitle": location['subtitle'] as String? ?? "",
              "icon": location['icon'] as String? ?? "📍",
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Erreur lors de la récupération des lieux.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Impossible de se connecter au serveur.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: widget.controller,
            onChanged: (query) {
              if (query.isNotEmpty) {
                _fetchLocations(query);
              } else {
                setState(() {
                  filteredLocations = [];
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Localisation*',
              hintText: "Rechercher un lieu...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // Affichage de la liste des lieux en bas du champ de texte
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: Text(errorMessage, style: TextStyle(color: Colors.red))),
          ),
        if (filteredLocations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,  // Permet de ne pas occuper tout l'espace
                itemCount: filteredLocations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.location_on, color: AppColors.primary),
                    title: Text(filteredLocations[index]["title"]!),
                    subtitle: Text(filteredLocations[index]["subtitle"]!),
                        onTap: () {
                      // Mettre à jour le champ de texte avec la valeur sélectionnée
                      widget.controller.text = filteredLocations[index]["title"]!;
                      setState(() {
                        filteredLocations = []; // Optionnel: vider la liste après sélection
                      });
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}