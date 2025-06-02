import 'package:dumum_tergo/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchLocationPage extends StatefulWidget {
  @override
  _SearchLocationPageState createState() => _SearchLocationPageState();
}

class _SearchLocationPageState extends State<SearchLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> filteredLocations = [];
  bool isLoading = false;
  String errorMessage = "";

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Lieu de prise en charge', style: TextStyle( fontSize: 16)),
 leading: Row(
  children: [
    IconButton(
  icon: Icon(Icons.keyboard_arrow_down),
  onPressed: () => Navigator.pop(context),
),
  ],
),


      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
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
                hintText: "Rechercher un lieu...",
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            if (isLoading) 
              Center(child: CircularProgressIndicator()),

            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text(errorMessage, style: TextStyle(color: Colors.red))),
              ),

            Expanded(
              child: filteredLocations.isEmpty && !isLoading && errorMessage.isEmpty
                  ? Center(child: Text("Aucun lieu trouvé", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: filteredLocations.length,
                      itemBuilder: (context, index) {

                        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5), // Ajoute un espace entre les cadres

                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    
                  ),
                  
        child: ListTile(
  //tileColor: Colors.white, // Changez cette couleur selon vos besoins
  leading: CircleAvatar(
    backgroundColor: Colors.transparent,
    child:  Icon(Icons.location_on, color: AppColors.primary)
  ),
  title: Text(filteredLocations[index]["title"]!, style: TextStyle(fontWeight: FontWeight.bold)),
  // subtitle: Text(filteredLocations[index]["subtitle"]!),
  onTap: () {
    Navigator.pop(context, filteredLocations[index]["title"]);
  },
),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
