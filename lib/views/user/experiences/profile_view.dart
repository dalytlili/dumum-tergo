import 'package:cached_network_image/cached_network_image.dart';
import 'package:dumum_tergo/views/user/experiences/ExperienceDetailView.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dumum_tergo/constants/colors.dart';
import '../../../viewmodels/user/profile_viewmodel.dart';
import '../../../viewmodels/theme_viewmodel.dart'; // Importez le ThemeViewModel

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context, listen: true);
    final isDarkMode = themeViewModel.isDarkMode;

    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel()..fetchProfileData(),
      child: Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
        body: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.white : AppColors.primary,
                  ),
                ),
              );
            } else {
              return RefreshIndicator(
                color: isDarkMode ? Colors.white : AppColors.primary,
                onRefresh: () async {
                  await viewModel.fetchProfileData();
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileHeader(viewModel, isDarkMode),
                      _buildExperiencesSection(viewModel, isDarkMode),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildExperiencesSection(ProfileViewModel viewModel, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expériences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.text,
            ),
          ),
          SizedBox(height: 8),
          if (viewModel.experiences.isEmpty)
            Text(
              'Aucune expérience à afficher!!',
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : AppColors.text),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: viewModel.experiences.length,
              itemBuilder: (context, index) {
                return _buildPostItem(context, viewModel.experiences[index], isDarkMode);
              },
            ),
        ],
      ),
    );
  }

Widget _buildPostItem(BuildContext context, Map<String, dynamic> experience, bool isDarkMode) {
  return GestureDetector(
    onTap: () async {
      // Ajout du log pour afficher les données de l'expérience
      print('Données de l\'expérience envoyées à ExperienceDetailView:');
      print(experience.toString());
      debugPrint('Détails de l\'expérience:', wrapWidth: 1024);
      debugPrint(experience.toString(), wrapWidth: 1024);
      
      final shouldRefresh = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ExperienceDetailView(
              experienceId: experience['_id'], // Passer seulement l'ID maintenant
          ),
        ),
      ) ?? false;

      if (shouldRefresh && context.mounted) {
        await Provider.of<ProfileViewModel>(context, listen: false).fetchProfileData();
      }
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: experience['images'] != null && experience['images'].isNotEmpty
          ? CachedNetworkImage(
              imageUrl: experience['images'][0] is String
                  ? experience['images'][0]
                  : experience['images'][0]['url'] ?? experience['images'][0]['imageUrl'] ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              errorWidget: (context, url, error) => Icon(Icons.error, color: isDarkMode ? Colors.white : Colors.black),
            )
          : Container(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              child: Center(
                child: Icon(
                  Icons.image,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ),
    ),
  );
}

  Widget _buildProfileHeader(ProfileViewModel viewModel, bool isDarkMode) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo de profil à gauche
              Container(
                margin: const EdgeInsets.only(right: 20),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  backgroundImage: viewModel.profileImageUrl.isNotEmpty
                      ? NetworkImage(viewModel.profileImageUrl)
                      : AssetImage('assets/images/default.png') as ImageProvider,
                ),
              ),
              
              // Informations utilisateur à droite
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            viewModel.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Statistiques en ligne
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('Expériences', viewModel.experiences.length.toString(), isDarkMode),
                        _buildStatItem('Abonnés', viewModel.followersCount.toString(), isDarkMode),
                        _buildStatItem('Abonnements', viewModel.followingCount.toString(), isDarkMode),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.4, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}