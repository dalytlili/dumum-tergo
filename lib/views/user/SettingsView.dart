import 'package:flutter/material.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/user/SettingsViewModel.dart';

class SettingsView extends StatelessWidget {
  final SettingsViewModel viewModel = SettingsViewModel();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.text;
    final iconColor = Theme.of(context).iconTheme.color ?? AppColors.text;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nouveau champ pour modifier le profil
            _buildSettingOption(
              context,
              icon: Icons.person,
              title: 'Modifier le profil',
              onTap: () => viewModel.editProfile(context),
            ),

            _buildSettingOption(
              context,
              icon: Icons.lock,
              title: 'Changer le mot de passe',
              onTap: () => viewModel.changePassword(context),
            ),
            _buildSettingOption(
              context,
              icon: Icons.language,
              title: 'Changer la langue',
              onTap: () => viewModel.changeLanguage(context),
            ),
            _buildSettingOption(
              context,
              icon: Icons.privacy_tip,
              title: 'Politique de confidentialité',
              onTap: () => viewModel.showPrivacyPolicy(context),
            ),
            _buildSettingOption(
              context,
              icon: Icons.contact_support,
              title: 'Nous contacter',
              onTap: () => viewModel.contactUs(context),
            ),
            _buildSettingOption( 
              context,
              icon: Icons.delete,
              title: 'Supprimer le compte',
              color: AppColors.error,
              onTap: () => viewModel.deleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.text;
    final iconColor = color ?? Theme.of(context).iconTheme.color ?? AppColors.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).cardTheme.color,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textLight,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
