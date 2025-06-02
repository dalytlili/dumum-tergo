import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

class EditExperienceScreen extends StatefulWidget {
  final Map<String, dynamic> experience;
  final Function(Map<String, dynamic>) onExperienceUpdated;

  const EditExperienceScreen({
    Key? key,
    required this.experience,
    required this.onExperienceUpdated,
  }) : super(key: key);

  @override
  _EditExperienceScreenState createState() => _EditExperienceScreenState();
}

class _EditExperienceScreenState extends State<EditExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  final storage = const FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.experience['description'] ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateExperience() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication required')),
          );
        }
        return;
      }

      final response = await http.put(
        Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences/${widget.experience['_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'description': _descriptionController.text,
        }),
      );

      if (response.statusCode == 200) {
        final updatedExperience = {
          ...widget.experience,
          'description': _descriptionController.text,
        };
        widget.onExperienceUpdated(updatedExperience);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Experience updated successfully')),
          );
        }
      } else {
        final errorMessage = response.statusCode == 404 
            ? 'Experience not found'
            : 'Failed to update experience (${response.statusCode})';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _getImageUrl() {
    final images = widget.experience['images'];
    if (images == null) return null;
    
    if (images is String) {
      return images.isNotEmpty ? images : null;
    } else if (images is List) {
      if (images.isEmpty) return null;
      final firstImage = images.first;
      if (firstImage is String) {
        return firstImage;
      } else if (firstImage is Map) {
        return firstImage['url']?.toString();
      }
    } else if (images is Map) {
      return images['url']?.toString();
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'expérience'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateExperience,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: Colors.grey.shade300,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey.shade300,
                            child: const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        if (value.length > 1000) {
                          return 'Description trop longue (max 1000 caractères)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}