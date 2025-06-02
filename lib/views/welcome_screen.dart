import 'package:flutter/material.dart';
import '../constants/colors.dart'; // Assurez-vous que ce fichier existe et contient vos couleurs

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final maxHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(), // Pas de dégradé pour garder les couleurs d'origine
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Image.asset(
                  isDarkMode 
                    ? 'assets/images/logo2.png' // Logo pour le mode sombre
                    : 'assets/images/logo.png', // Logo pour le mode clair
                  height: maxHeight * 0.3,
                ),
                const SizedBox(height: 32),
                Text(
                  'Bienvenue dans l\'aventure !',
                  style: TextStyle(
                    fontSize: maxWidth > 600 ? 32 : 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode 
                      ? Colors.white 
                      : Colors.grey[800], // Couleur d'origine
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Trouvez tout ce dont vous avez besoin pour un camping inoubliable.',
                  style: TextStyle(
                    fontSize: maxWidth > 600 ? 18 : 16,
                    color: isDarkMode 
                      ? Colors.white 
                      : Colors.grey[800], // Couleur d'origine
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/signin_seller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Couleur d'origine
                    foregroundColor: Colors.white, // Couleur d'origine
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.store, size: 24,
                      color: AppColors.background, // Couleur d'origine
                  ), // Icône pour le vendeur
                  label: Text(
                    'Je suis un Vendeur',
                    style: TextStyle(
                      fontSize: maxWidth > 600 ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/signin'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary, // Couleur d'origine
                    side: const BorderSide(color: AppColors.primary, width: 2), // Couleur d'origine
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.person, size: 24), // Icône pour l'utilisateur
                  label: Text(
                    'Je suis un Utilisateur',
                    style: TextStyle(
                      fontSize: maxWidth > 600 ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: maxHeight * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}