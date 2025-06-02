import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../viewmodels/user/privacy_policy_viewmodel.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrivacyPolicyViewModel(),
      child: const _PrivacyPolicyScreenContent(),
    );
  }
}

class _PrivacyPolicyScreenContent extends StatelessWidget {
  const _PrivacyPolicyScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PrivacyPolicyViewModel>();
    final maxWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de Confidentialité'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Politique de Confidentialité',
              style: TextStyle(
                fontSize: maxWidth > 600 ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dernière mise à jour : Février 2024',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            _buildPrivacyPolicySections(viewModel),
            const SizedBox(height: 24),
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicySections(PrivacyPolicyViewModel viewModel) {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        viewModel.toggleSection(index);
      },
      children: viewModel.sections.map<ExpansionPanel>((section) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(
                section.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              section.content,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
          isExpanded: section.isExpanded,
        );
      }).toList(),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nous Contacter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        _buildContactInfo(
          icon: Icons.email,
          title: 'Email',
          subtitle: 'mohammedali.tlili@esprit.tn',
        ),
        const SizedBox(height: 8),
        _buildContactInfo(
          icon: Icons.phone,
          title: 'Téléphone',
          subtitle: '+216 55 947 170',
        ),
      ],
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(subtitle),
    );
  }
}
