import 'package:dumum_tergo/views/ContactUsScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../viewmodels/user/help_center_viewmodel.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HelpCenterViewModel(),
      child: const _HelpCenterScreenContent(),
    );
  }
}

class _HelpCenterScreenContent extends StatelessWidget {
  const _HelpCenterScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HelpCenterViewModel>();
    final maxWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre d\'Aide'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment pouvons-nous vous aider ?',
              style: TextStyle(
                fontSize: maxWidth > 600 ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            _buildSearchField(),
            const SizedBox(height: 24),
            _buildHelpSections(viewModel),
            const SizedBox(height: 24),
            _buildContactPrompt(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher dans le centre d\'aide...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildHelpSections(HelpCenterViewModel viewModel) {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        viewModel.toggleSection(index);
      },
      children: viewModel.sections.map<ExpansionPanel>((section) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              leading: Icon(section.icon, color: AppColors.primary),
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
                height: 1.5,
              ),
            ),
          ),
          isExpanded: section.isExpanded,
        );
      }).toList(),
    );
  }

  Widget _buildContactPrompt(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous ne trouvez pas ce que vous cherchez ?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Notre équipe est disponible pour répondre à vos questions.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactUsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Nous Contacter',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}