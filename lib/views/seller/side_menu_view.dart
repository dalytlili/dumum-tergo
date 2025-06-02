import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/user/SideMenuViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
//import 'SettingsView.dart'; // Ensure SettingsView is imported

class SideMenuView extends StatelessWidget {
  const SideMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();
    final sideMenuViewModel = Provider.of<SideMenuViewModel>(context, listen: false);

    // Fetch user data when the menu is loaded
    sideMenuViewModel.fetchUserData();

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
                child: Consumer<SideMenuViewModel>(
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
                leading: const Icon(Icons.history),
                title: const Text('Mes réservations'),
                onTap: () {
                                 Navigator.pushNamed(context, '/Reservation-Page');

                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign),
                title: const Text('IA Camping'),
                onTap: () {
                  // Navigate to IA Camping page
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Us'),
                onTap: () {
                  // Navigate to About Us page
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pushNamed(context, '/SettingsView');
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  // Navigate to Help & Support page
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  // Logic to logout
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show a logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    final sideMenuViewModel = Provider.of<SideMenuViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final token = await sideMenuViewModel.getToken();
                if (token != null) {
                await sideMenuViewModel.logoutUser(context, token);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token not found')),
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}