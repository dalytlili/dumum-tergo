import 'dart:convert';
import 'dart:io';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart' show storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart'; // Pour MediaType


class AddExperienceScreen extends StatefulWidget {
  const AddExperienceScreen({Key? key}) : super(key: key);

  @override
  _AddExperienceScreenState createState() => _AddExperienceScreenState();
}

class _AddExperienceScreenState extends State<AddExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  List<File> _images = [];
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

Future<void> _submitExperience() async {
  if (!_formKey.currentState!.validate()) return;

  if (_images.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajoutez au moins une photo')),
    );
    return;
  }

  setState(() => _isLoading = true);
  final token = await storage.read(key: 'token');

  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://dumum-tergo-backend.onrender.com/api/experiences'), // Utilisez 10.0.2.2 pour Android emulator
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['description'] = _descriptionController.text;

    // Ajout des images avec le bon content-type
    for (var image in _images) {
      var file = await http.MultipartFile.fromPath(
        'images', 
        image.path,
        contentType: MediaType('image', path.extension(image.path).replaceFirst('.', '')),
      );
      request.files.add(file);
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 201) {
// Après avoir réussi à créer l'expérience
Navigator.pop(context, true);    } else {
      final decoded = json.decode(responseData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${decoded['message'] ?? 'Erreur inconnue (${response.statusCode})'}')),
      );
    }
  } on http.ClientException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur de connexion: ${e.message}')),
    );
  } on SocketException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pas de connexion internet: ${e.message}')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: ${e.toString()}')),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nouvelle publication',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _submitExperience,
            child: const Text('Publier',
                style: TextStyle(color: AppColors.primary, fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section description
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              hintText: 'Décrivez votre expérience...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            maxLines: 5,
                            style: const TextStyle(fontSize: 16),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez écrire une description';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section photos
                    Text('Photos',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Ajoutez jusqu\'à 10 photos',
                        style: TextStyle(color: Colors.grey.shade600)),

                    const SizedBox(height: 16),

                    // Grille de photos
                  GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 1,
  ),
  itemCount: _images.length + (_images.length < 10 ? 1 : 0),
  itemBuilder: (context, index) {
    // If we should show the "Add" button
    if (index == _images.length && _images.length < 10) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, size: 30, color: Colors.grey),
              SizedBox(height: 4),
              Text('Ajouter', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    
    // Otherwise show the image
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _images[index],
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _images.removeAt(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  },
),

                    const SizedBox(height: 32),

                    // Bouton de publication
                   
                  ],
                ),
              ),
            ),
    );
  }
}