
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/seller/SideMenuViewModelseller.dart';
import 'package:dumum_tergo/views/ContactUsScreen.dart';
import 'package:dumum_tergo/views/HelpCenterScreen.dart';
import 'package:dumum_tergo/views/seller/Vendor-Complaints-Page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
//import 'SettingsView.dart'; // Ensure SettingsView is imported
import 'package:dumum_tergo/services/logout_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SideMenuView extends StatelessWidget {
  const SideMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();
    final sideMenuViewModel = Provider.of<SideMenuViewModelSeller>(context, listen: false);
    final LogoutService _logoutService = LogoutService();
    final FlutterSecureStorage _storage = const FlutterSecureStorage();

    // Schedule the fetch after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sideMenuViewModel.fetchProfileData();
    });

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: themeViewModel.isDarkMode ? Colors.grey[700]! : AppColors.primary,
          width: 0, // Invisible border (width 0)
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(70), // Top right corner rounded to 70
          bottomRight: Radius.circular(70), // Bottom right corner rounded to 70
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(70), // Top right corner rounded to 70
          bottomRight: Radius.circular(70), // Bottom right corner rounded to 70
        ),
        child: Drawer(
          width: 280, // Menu width set to 280 pixels
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // Drawer Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeViewModel.isDarkMode ? Colors.grey[900] : AppColors.primary,
                ),
                child: Consumer<SideMenuViewModelSeller>(
                  builder: (context, viewModel, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min, // Adjust content height
                      crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
                      mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                      children: [
                        const SizedBox(height: 30), // Spacing

                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context); // Close the side menu
                            },
                          ),
                        ),
                        const SizedBox(height: 10), // Spacing

                        // User Photo centered
                    Center(
child: CircleAvatar(
  radius: 40, // Augmenté pour une meilleure visibilité
  backgroundImage: viewModel.profileImageUrl.isNotEmpty
      ? (viewModel.profileImageUrl.startsWith('https://dumum-tergo-backend.onrender.com')
          // Vérification si l'URL est exactement "http://127.0.0.1:9098"
          ? (viewModel.profileImageUrl == 'https://dumum-tergo-backend.onrender.com'
              ? const AssetImage('assets/images/images.png')
              : NetworkImage(viewModel.profileImageUrl)) // Si l'URL est valide, utiliser l'image depuis l'URL
          : (viewModel.profileImageUrl.startsWith('http')
              ? NetworkImage(viewModel.profileImageUrl) // Image en ligne
              : AssetImage(viewModel.profileImageUrl) as ImageProvider) // Image locale
      )
      : const AssetImage('assets/images/images.png') as ImageProvider, // Image par défaut
),

),
                        const SizedBox(height: 10), // Spacing

                        // User Name centered
                        Center(
                          child: Text(
                            viewModel.name, // Display name
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Menu Items
            
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Nous contacter'),
                onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ContactUsScreen(),
    ),
  ), 
              ),
           ListTile(
  leading: const Icon(Icons.report_problem),
  title: const Text('Mes Réclamations'),
  onTap: () {
    Navigator.pop(context); // Ferme le menu
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VendorComplaintsPage(),
      ),
    );
  },
),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Centre d\'aide'),
        
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HelpCenterScreen(),
    ),
  ),              ),
      
           
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Déconnexion'),
                onTap: () {
                  // Logic to logout
                  _showLogoutConfirmationDialog(context, _logoutService, _storage);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

void _showLogoutConfirmationDialog(BuildContext context, LogoutService logoutService, FlutterSecureStorage storage) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final sideMenuViewModel = Provider.of<SideMenuViewModelSeller>(context, listen: false);
  bool isLoading = false; // Local state for loading indicator

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
            title: Text(
              'Déconnexion',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Êtes-vous sûr de vouloir vous déconnecter ?',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                if (isLoading) 
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              if (!isLoading) // Hide cancel button when loading
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Annuler',
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                  ),
                ),
              TextButton(
                onPressed: isLoading 
                    ? null // Disable button when loading
                    : () async {
                        setState(() => isLoading = true);
                        try {
                          final token = await storage.read(key: 'seller_token');
                          if (token != null) {
                            // 1. Appeler le service de déconnexion
                            await logoutService.logoutSeller(token);
                            
                            // 2. Supprimer tout le stockage
                            await sideMenuViewModel.clearStorage();
                            
                            // 3. Rediriger vers l'écran de bienvenue
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/welcome', 
                              (route) => false
                            );
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
                          );
                        }
                      },
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.red,
                          ),
                        ),
                      )
                    : const Text(
                        'Déconnexion', 
                        style: TextStyle(color: Colors.red),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}
}