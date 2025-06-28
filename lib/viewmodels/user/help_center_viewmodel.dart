import 'package:flutter/material.dart';

class HelpSection {
  final IconData icon;
  final String title;
  final String content;
  bool isExpanded;

  HelpSection({
    required this.icon,
    required this.title,
    required this.content,
    this.isExpanded = false,
  });
}

class HelpCenterViewModel extends ChangeNotifier {
  final List<HelpSection> _sections = [
    HelpSection(
      icon: Icons.account_circle,
      title: 'Problèmes de compte',
      content: 'Si vous rencontrez des problèmes avec votre compte...',
    ),
    HelpSection(
      icon: Icons.payment,
      title: 'Paiements et facturation',
      content: 'Informations sur les méthodes de paiement acceptées...',
    ),
    HelpSection(
      icon: Icons.help_outline,
      title: 'FAQ Générale',
      content: 'Réponses aux questions les plus fréquemment posées...',
    ),
  ];

  List<HelpSection> get sections => _sections;

  void toggleSection(int index) {
    _sections[index].isExpanded = !_sections[index].isExpanded;
    notifyListeners();
  }
}