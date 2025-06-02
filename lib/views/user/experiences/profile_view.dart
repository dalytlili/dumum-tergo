import 'package:cached_network_image/cached_network_image.dart';
import 'package:dumum_tergo/views/user/experiences/ExperienceDetailView.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dumum_tergo/constants/colors.dart';
import '../../../viewmodels/user/profile_viewmodel.dart';

class ProfileView extends StatelessWidget {
    const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel()..fetchProfileData(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(child: CircularProgressIndicator());
            } else {
              return RefreshIndicator(
                onRefresh: () async {
                  await viewModel.fetchProfileData();
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileHeader(viewModel),
                      _buildExperiencesSection(viewModel),
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

  Widget _buildExperiencesSection(ProfileViewModel viewModel) {
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
            color: AppColors.text,
          ),
        ),
        SizedBox(height: 8),
        if (viewModel.experiences.isEmpty)
          Text(
            'Aucune expérience à afficher',
            style: TextStyle(color: AppColors.text),
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
              return _buildPostItem(context, viewModel.experiences[index]);
            },
          ),
      ],
    ),
  );
}


Widget _buildPostItem(BuildContext context, Map<String, dynamic> experience) {
  return GestureDetector(
onTap: () async {
  final shouldRefresh = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => ExperienceDetailView(
        experience: experience,
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
            color: Colors.black.withOpacity(0.1),
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
                color: Colors.grey[200],
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            )
          : Container(
              color: Colors.grey[200],
              child: Center(child: Icon(Icons.image, color: Colors.grey[400])),
            ),
    ),
  );
}

 Widget _buildProfileHeader(ProfileViewModel viewModel) {
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
                backgroundColor: Colors.grey[200],
                backgroundImage: viewModel.profileImageUrl.isNotEmpty
                    ? NetworkImage(viewModel.profileImageUrl)
                    : const AssetImage('assets/images/default_profile.png') as ImageProvider,
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
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
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
                      _buildStatItem('Expériences', viewModel.experiences.length.toString()),
                    _buildStatItem('Abonnés', viewModel.followersCount.toString()),
                      _buildStatItem('Abonnements', viewModel.followingCount.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 1),
    ],
  );
}

Widget _buildStatItem(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.grey[100],
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}








 
}