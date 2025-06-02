import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/user/SideMenuViewModel.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import 'SettingsView.dart'; // Assurez-vous que SettingsView est importé

class SideMenuView extends StatelessWidget {
  const SideMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();
    final sideMenuViewModel = Provider.of<SideMenuViewModel>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: themeViewModel.isDarkMode ? Colors.grey[700]! : AppColors.primary,
          width: 0, // Bordure invisible (largeur 0)
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(70), // Coin supérieur droit arrondi à 70
          bottomRight: Radius.circular(70), // Coin inférieur droit arrondi à 70
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(70), // Coin supérieur droit arrondi à 70
          bottomRight: Radius.circular(70), // Coin inférieur droit arrondi à 70
        ),
        child: Drawer(
          width: 280, // Largeur du menu définie à 280 pixels
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // En-tête du menu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeViewModel.isDarkMode ? Colors.grey[900] : AppColors.primary,
                ),
                child: Consumer<SideMenuViewModel>(
                  builder: (context, viewModel, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min, // Ajuste la hauteur du contenu
                      crossAxisAlignment: CrossAxisAlignment.center, // Centrage horizontal
                      mainAxisAlignment: MainAxisAlignment.center, // Centrage vertical
                      children: [
                        const SizedBox(height: 30), // Espacement

                        // Bouton Retour
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context); // Ferme le menu latéral
                            },
                          ),
                        ),
                        const SizedBox(height: 10), // Espacement

                        // Photo de l'utilisateur centrée
                        Center(
                          child: FutureBuilder(
                            future: storage.read(key: 'userImage'),
                            builder: (context, snapshot) {
                              final imagePath = snapshot.data;
                              return CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(
                                  'https://res.cloudinary.com/dcs2edizr/image/upload/$imagePath',
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10), // Espacement

                        // Nom de l'utilisateur centré
                        Center(
                          child: FutureBuilder(
                            future: storage.read(key: 'userName'), // Supposant que le nom est stocké avec la clé 'userName'
                            builder: (context, snapshot) {
                              final userName = snapshot.data ?? 'Utilisateur'; // Par défaut 'Utilisateur' si le nom n'est pas trouvé
                              return Text(
                                userName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Éléments du menu
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Mes réservations'),
                onTap: () {
                  Navigator.pushNamed(context, '/Reservation-Page');
                },
              ),ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text('Mes favoris'),
                onTap: () {
                  Navigator.pushNamed(context, '/Favorite-Page');
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign),
                title: const Text('IA Camping'),
                onTap: () {
                  // Naviguer vers la page IA Camping
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('À propos'),
                onTap: () {
                  // Naviguer vers la page À propos
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Paramètres'),
                onTap: () {
                  Navigator.pushNamed(context, '/SettingsView');
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Aide & Support'),
                onTap: () {
                  // Naviguer vers la page Aide & Support
                },
              ),
              Consumer<SideMenuViewModel>(
                builder: (context, viewModel, child) {
                  return ListTile(
                    leading: viewModel.isLoading 
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.logout),
                    title: viewModel.isLoading
                        ? const Text('Déconnexion...')
                        : const Text('Déconnexion'),
                    onTap: () {
                      if (!viewModel.isLoading) {
                        _showLogoutDialog(context);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fonction pour afficher une boîte de dialogue de confirmation de déconnexion
  void _showLogoutDialog(BuildContext context) {
    final sideMenuViewModel = Provider.of<SideMenuViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<SideMenuViewModel>(
          builder: (context, viewModel, child) {
            return AlertDialog(
              title: const Text('Déconnexion'),
              content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
              actions: [
                if (viewModel.isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Ferme la boîte de dialogue
                    },
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final token = await sideMenuViewModel.getToken();
                      if (token != null) {
                        await sideMenuViewModel.logoutUser(context, token);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Token non trouvé')),
                        );
                      }
                    },
                    child: const Text('Déconnexion'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}