import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VendorComplaintsPage extends StatefulWidget {
  const VendorComplaintsPage({Key? key}) : super(key: key);

  @override
  _VendorComplaintsPageState createState() => _VendorComplaintsPageState();
}

class _VendorComplaintsPageState extends State<VendorComplaintsPage> {
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
      final token = await storage.read(key: 'seller_token');
      final response = await http.get(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/complaints/vendeur'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          complaints = data['data'] ?? [];
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
            Text(
              errorMessage!,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
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
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune réclamation trouvée',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez aucune réclamation pour le moment',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchComplaints,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: complaints.length,
        itemBuilder: (context, index) {
          return _buildComplaintCard(complaints[index], isDarkMode);
        },
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint, bool isDarkMode) {
    final dateFormat = DateFormat('dd MMM yyyy - HH:mm');
    final createdAt = DateTime.parse(complaint['createdAt']);
    final user = complaint['user'];

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
                      complaint['title'],
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
              complaint['description'],
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Client: ${user['name']}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  user['mobile'],
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  user['email'],
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
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