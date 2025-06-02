import 'dart:convert';

import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:dumum_tergo/services/api_service.dart';
import 'package:dumum_tergo/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:dumum_tergo/views/user/experiences/user_profil.dart'; // Importez le UserProfileScreen

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final token = await storage.read(key: 'token');
      if (token != null) {
        currentUserId = await _getUserIdFromToken(token);
      }
    } catch (e) {
      debugPrint('Error getting user ID: $e');
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

      return jsonMap['user']?['_id']?.toString() ?? 
             jsonMap['userId']?.toString() ??
             jsonMap['id']?.toString();
    } catch (e) {
      debugPrint('Token decoding error: $e');
      return null;
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/search?name=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        final users = data.map((json) => User.fromJson(json)).toList();

        setState(() {
          _searchResults = users;
          _isLoading = false;
        });
      } else {
        throw Exception('Échec du chargement des utilisateurs');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher des utilisateurs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Entrez un nom...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                                        user.image.startsWith('https') 
                                          ? user.image 
                                          : 'https://res.cloudinary.com/dcs2edizr/image/upload/${user.image}',
                                          
                                      ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        onTap: () {
                          if (currentUserId != null && currentUserId != user.id) {
                              print("Utilisateur cliqué: ${user.id}"); 

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(userId: user.id),
                              ),
                            );
                          }
                          // Si c'est le même utilisateur, ne rien faire ou naviguer vers le profil de l'utilisateur connecté
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}