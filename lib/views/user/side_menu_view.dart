import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/user/SideMenuViewModel.dart';
import 'package:dumum_tergo/views/user/chat_interface.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import 'SettingsView.dart';

class SideMenuView extends StatefulWidget {
  const SideMenuView({super.key});

  @override
  State<SideMenuView> createState() => _SideMenuViewState();
}

class _SideMenuViewState extends State<SideMenuView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sideMenuViewModel = Provider.of<SideMenuViewModel>(context, listen: false);
      if (!sideMenuViewModel.isDataLoaded) {

        sideMenuViewModel.fetchUserData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: themeViewModel.isDarkMode ? Colors.grey[700]! : AppColors.primary,
          width: 0,
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(70),
          bottomRight: Radius.circular(70),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(70),
          bottomRight: Radius.circular(70),
        ),
        child: Drawer(
          width: 280,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeViewModel.isDarkMode ? Colors.grey[900] : AppColors.primary,
                ),
                child: Consumer<SideMenuViewModel>(
                  builder: (context, viewModel, child) {
                    // Afficher l'indicateur de chargement seulement lors du premier chargement
                    final showLoading = !viewModel.isDataLoaded && viewModel.isLoading;
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: showLoading
                              ? const SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 40,
                                  backgroundImage: _getProfileImage(viewModel),
                                ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: showLoading
                              ? const SizedBox()
                              : Text(
                                  viewModel.name.isNotEmpty ? viewModel.name : 'Utilisateur',
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
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Mes réservations'),
                onTap: () {
                  Navigator.pushNamed(context, '/Reservation-Page');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text('Mes favoris'),
                onTap: () {
                  Navigator.pushNamed(context, '/Favorite-Page');
                },
              ),
           ListTile(
  leading: const Icon(Icons.chat),
  title: const Text('Assistant Camping'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatCampingScreen()),
    );
  },
),
             
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Paramètres'),
                onTap: () {
                  Navigator.pushNamed(context, '/SettingsView');
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

  ImageProvider _getProfileImage(SideMenuViewModel viewModel) {
    if (viewModel.profileImageUrl.isEmpty) {
      return const AssetImage('assets/images/images.png');
    }


    if (viewModel.profileImageUrl.startsWith('http')) {
      return NetworkImage(viewModel.profileImageUrl);
    }

    return AssetImage(viewModel.profileImageUrl);
  }

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
                    onPressed: () => Navigator.pop(context),
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