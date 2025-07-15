import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserComplaintsPage extends StatefulWidget {
  const UserComplaintsPage({Key? key}) : super(key: key);

  @override
  _UserComplaintsPageState createState() => _UserComplaintsPageState();
}

class _UserComplaintsPageState extends State<UserComplaintsPage> {
  final storage = FlutterSecureStorage();
  List<dynamic> complaints = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/complaints/user-complaints'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          complaints = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load complaints');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur de chargement: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réclamations'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchComplaints,
          ),
        ],
      ),
      body: _buildBody(isDarkMode),
   
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchComplaints,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_problem, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Aucune réclamation trouvée'),
            const SizedBox(height: 8),
            Text(
              'Cliquez sur le bouton + pour créer une réclamation',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        return _buildComplaintCard(complaint, isDarkMode);
      },
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint, bool isDarkMode) {
    final dateFormat = DateFormat('dd MMM yyyy - HH:mm');
    final createdAt = DateTime.parse(complaint['createdAt']);
    final vendor = complaint['vendor'] ?? {};

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      complaint['title'] ?? 'Pas de titre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 80),
                  child: Chip(
                    label: SizedBox(
                      width: 70,
                      child: Text(
                        complaint['status'] == 'pending' ? 'En attente' : 'Résolue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: complaint['status'] == 'pending'
                              ? Colors.orange[800]
                              : Colors.green[800],
                        ),
                      ),
                    ),
                    backgroundColor: complaint['status'] == 'pending'
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                    side: BorderSide(
                      color: complaint['status'] == 'pending'
                          ? Colors.orange.withOpacity(0.5)
                          : Colors.green.withOpacity(0.5),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complaint['description'] ?? 'Pas de description',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 12),
            if (vendor['businessName'] != null)
              Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vendeur: ${vendor['businessName']}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            if (vendor['email'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      vendor['email'],
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
           
              ],
            ),
          ],
        ),
      ),
    );
  }
}