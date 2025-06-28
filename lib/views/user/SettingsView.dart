import 'package:dumum_tergo/views/ContactUsScreen.dart';
import 'package:dumum_tergo/views/HelpCenterScreen.dart';
import 'package:dumum_tergo/views/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/user/SettingsViewModel.dart';

class SettingsView extends StatelessWidget {
  final SettingsViewModel viewModel = SettingsViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Compte
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text(
                  'COMPTE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              _buildSettingOption(
                context,
                icon: Icons.person_outline, 
                color: AppColors.primary,
                title: 'Modifier le profil',
                onTap: () => viewModel.editProfile(context),
              ),
              _buildSettingOption(
                context,
                icon: Icons.lock_outline, 
                color: AppColors.primary,
                title: 'Changer le mot de passe',
                onTap: () => viewModel.changePassword(context),
              ),

              // Section Application
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text(
                  'APPLICATION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              _buildSettingOption(
                context,
                icon: Icons.language_outlined, 
                color: AppColors.primary,
                title: 'Changer la langue',
                onTap: () => viewModel.changeLanguage(context),
              ),

              // Section Aide
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text(
                  'AIDE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
         _buildSettingOption(
  context,
  icon: Icons.privacy_tip_outlined, 
  color: AppColors.primary,
  title: 'Politique de confidentialité',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PrivacyPolicyScreen(),
    ),
  ),
),
              _buildSettingOption(
                context,
                icon: Icons.help_outline, 
                color: AppColors.primary,
                title: 'Centre d\'aide',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HelpCenterScreen(),
    ),
  ),              ),
              _buildSettingOption(
                context,
                icon: Icons.contact_support_outlined, 
                color: AppColors.primary,
                title: 'Nous contacter',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ContactUsScreen(),
    ),
  ),              ),

              // Section Danger
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text(
                  'DANGER',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              _buildSettingOption(
                context,
                icon: Icons.delete_outline,
                title: 'Supprimer le compte',
                color: AppColors.error,
                onTap: () => viewModel.deleteAccount(context),
              ),
              const SizedBox(height: 20), // Espace supplémentaire en bas
            ],
          ),
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: Theme.of(context).cardTheme.color,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color ?? Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
        ),
        onTap: onTap,
      ),
    );
  }
}