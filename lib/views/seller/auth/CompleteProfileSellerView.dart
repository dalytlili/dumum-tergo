import 'dart:io';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/seller/CompleteProfileSellerViewModel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CompleteProfileSellerView extends StatelessWidget {
  const CompleteProfileSellerView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CompleteProfileSellerViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Vendeur'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
 child: _buildProfileImage(viewModel),
          ),
               
                            const SizedBox(height: 16),

       Text(
              'Nom de l\'entreprise',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextFormField(
                      controller: viewModel.nameController,

              decoration: InputDecoration(
                hintText: 'Entrez le nom de votre entreprise',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
Text(
              'Email',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextFormField(
                      controller: viewModel.emailController,

              decoration: InputDecoration(
                hintText: 'Entrez le nom de votre Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextFormField(
                      controller: viewModel.descriptionController,

              decoration: InputDecoration(
                hintText: 'Entrez la description de votre entreprise',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Section Adresse
            Text(
              'Adresse',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextFormField(
                                    controller: viewModel.addressController,

              decoration: InputDecoration(
                hintText: 'Entrez votre adresse',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Boutons Annuler et Enregistrer
                  SizedBox(
  width: double.infinity, // Prend toute la largeur disponible
  child: ElevatedButton(
    onPressed: viewModel.isLoading
        ? null
        : () =>  viewModel.loginUser(context),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: viewModel.isLoading
        ? const CircularProgressIndicator(color: Colors.white)
        : const Text(
            'Connexion',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
  ),
)
              ],
        ),
      ),
    );
  }
    Widget _buildProfileImage(CompleteProfileSellerViewModel viewModel) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _getImage(viewModel.imageUrlController.text),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              viewModel.imageUrlController.text = pickedFile.path;
              viewModel.notifyListeners();
            }
          },
        ),
      ],
    );
  }
ImageProvider _getImage(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return NetworkImage(imageUrl); // Si c'est une URL
      } else {
        // Vérification si c'est un fichier local
        final file = File(imageUrl);
        if (file.existsSync()) {
          return FileImage(file); // Si c'est un fichier local valide
        } else {
          return const AssetImage('assets/images/default.png'); // Image par défaut si le fichier n'existe pas
        }
      }
    } else {
      return const AssetImage('assets/images/default.png'); // Image par défaut si l'URL est vide
    }
  }
}