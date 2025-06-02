import 'package:flutter/foundation.dart';

class PrivacyPolicyViewModel extends ChangeNotifier {
  final List<PrivacyPolicySection> _sections = [
    PrivacyPolicySection(
      title: 'Collecte des Informations Personnelles',
      content: 'Nous collectons des informations personnelles lorsque vous vous inscrivez, notamment votre nom, email, numéro de téléphone et autres informations de contact.',
    ),
    PrivacyPolicySection(
      title: 'Utilisation des Données',
      content: 'Vos données sont utilisées pour améliorer nos services, personnaliser votre expérience et communiquer avec vous.',
    ),
    PrivacyPolicySection(
      title: 'Protection des Données',
      content: 'Nous mettons en place des mesures de sécurité avancées pour protéger vos informations personnelles contre tout accès non autorisé.',
    ),
    PrivacyPolicySection(
      title: 'Partage des Informations',
      content: 'Nous ne vendons ni ne partageons vos informations personnelles avec des tiers sans votre consentement explicite.',
    ),
    PrivacyPolicySection(
      title: 'Vos Droits',
      content: 'Vous avez le droit d\'accéder, de modifier, de supprimer vos données personnelles à tout moment.',
    ),
  ];

  List<PrivacyPolicySection> get sections => _sections;

  bool _isExpanded(int index) {
    return _sections[index].isExpanded;
  }

  void toggleSection(int index) {
    _sections[index].isExpanded = !_sections[index].isExpanded;
    notifyListeners();
  }
}

class PrivacyPolicySection {
  final String title;
  final String content;
  bool isExpanded;

  PrivacyPolicySection({
    required this.title,
    required this.content,
    this.isExpanded = false,
  });
}
