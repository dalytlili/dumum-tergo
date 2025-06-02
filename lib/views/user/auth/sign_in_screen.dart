import 'package:dumum_tergo/services/login_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '../../../viewmodels/user/SignInViewModel.dart';
import '../../../constants/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignInViewModel(
        loginService: LoginService(client: http.Client()),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Se connecter'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<SignInViewModel>(
              builder: (context, viewModel, child) {
                // Afficher le bottom sheet guide au premier lancement
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkFirstLaunch(context, viewModel);
                });

                final maxWidth = MediaQuery.of(context).size.width;

                return Form(
                  key: viewModel.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Connectez-vous avec votre e-mail ou numéro de téléphone',
                        style: TextStyle(
                          fontSize: maxWidth > 600 ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 42),
                      TextFormField(
                        controller: viewModel.emailController,
                        keyboardType: viewModel.isPhoneMode
                            ? TextInputType.phone
                            : TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: viewModel.isPhoneMode
                              ? 'Numéro de téléphone'
                              : 'E-mail',
                          prefixIcon: viewModel.isPhoneMode
                              ? InkWell(
                                  onTap: () {
                                    showCountryPicker(
                                      context: context,
                                      showPhoneCode: true,
                                      onSelect: (Country country) {
                                        viewModel.setSelectedCountry(country);
                                      },
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          viewModel.selectedCountry.flagEmoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '+${viewModel.selectedCountry.phoneCode}',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white70
                                                    : Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white70
                                              : Colors.grey[700],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(viewModel.isPhoneMode
                                ? Icons.email
                                : Icons.phone),
                            onPressed: viewModel.togglePhoneMode,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return viewModel.isPhoneMode
                                ? 'Veuillez entrer votre numéro'
                                : 'Veuillez entrer votre email';
                          }

                          if (viewModel.isPhoneMode) {
                            if (!RegExp(r'^\d+$').hasMatch(value)) {
                              return 'Veuillez entrer un numéro valide';
                            }
                          } else {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Veuillez entrer un email valide';
                            }
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: viewModel.passwordController,
                        obscureText: !viewModel.isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Entrez votre mot de passe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              viewModel.isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: viewModel.togglePasswordVisibility,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/forgot-password');
                        },
                        child: Text(
                          'Mot de passe oublié?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () => viewModel.loginUser(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: viewModel.isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Connexion',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade400)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'ou',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: maxWidth > 600 ? 16 : 14,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade400)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSocialButton(
                        'Inscrivez-vous avec Gmail',
                        'assets/images/google_icon.png',
                        onPressed: () async {
                          await viewModel.loginWithGoogle(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSocialButton(
                        'Inscrivez-vous avec Facebook',
                        'assets/images/facebook_icon.png',
                        onPressed: () async {
                          await viewModel.loginWithFacebook(context);
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Vous n\'avez pas de compte ?',
                            style: TextStyle(
                              fontSize: maxWidth > 600 ? 16 : 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                          child: Text(
  'Créer un compte',
  style: TextStyle(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
    fontSize: 14, // Taille de police réduite pour petits écrans
  ),
),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _checkFirstLaunch(BuildContext context, SignInViewModel viewModel) async {
    final hasSeenGuide = await storage.read(key: 'hasSeenPhoneGuide');
    if (hasSeenGuide == null || hasSeenGuide != 'true') {
      _showBottomSheet(context, viewModel);
      await storage.write(key: 'hasSeenPhoneGuide', value: 'true');
    }
  }

void _showBottomSheet(BuildContext context, SignInViewModel viewModel) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Comment utiliser le champ téléphone',
                style: TextStyle(
                  fontSize: 20, // Réduit de 22 à 20
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Suivez ces étapes simples pour vous connecter avec votre numéro de téléphone',
                style: TextStyle(
                  fontSize: 14, // Réduit de 16 à 14
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              // Étapes visuelles
              Column(
                children: [
                  // Étape 1
                  _buildVisualStep(
                    context,
                    stepNumber: 1,
                    icon: Icons.phone,
                    title: 'Cliquez sur l\'icône téléphone',
                    description: 'Pour basculer vers le mode de connexion par téléphone',
                    imageWidget: Container(
                      padding: const EdgeInsets.all(8), // Réduit de 12 à 8
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.phone,
                        size: 32, // Réduit de 40 à 32
                        color: AppColors.primary,
                      ),
                    ),
                    isClickable: false,
                  ),
                  
                  const SizedBox(height: 16), // Réduit de 24 à 16
                  
                  // Étape 2
                  _buildVisualStep(
                    context,
                    stepNumber: 2,
                    icon: Icons.flag,
                    title: 'Pays sélectionné par défaut',
                    description: 'La Tunisie est présélectionnée pour vous',
                    imageWidget: Container(
                      padding: const EdgeInsets.all(8), // Réduit de 12 à 8
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🇹🇳',
                            style: const TextStyle(fontSize: 20), // Réduit de 24 à 20
                          ),
                          const SizedBox(width: 8), // Réduit de 12 à 8
                          Text(
                            '+216',
                            style: TextStyle(
                              fontSize: 16, // Réduit de 18 à 16
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    isClickable: false,
                  ),
                  
                  const SizedBox(height: 16), // Réduit de 24 à 16
                  
                  // Étape 3
                  _buildVisualStep(
                    context,
                    stepNumber: 3,
                    icon: Icons.edit,
                    title: 'Entrez votre numéro',
                    description: 'Saisissez votre numéro de téléphone tunisien sans le préfixe',
                    imageWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12), // Réduit de 16 à 12
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      child: IgnorePointer(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '23123456',
                            border: InputBorder.none,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 8), // Réduit de 12 à 8
                              child: Text(
                                '+216',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ),
                    isClickable: false,
                  ),
                ],
              ),
              
              const SizedBox(height: 24), // Réduit de 32 à 24
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14), // Réduit de 16 à 14
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'OK, j\'ai compris',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15, // Réduit de 16 à 15
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8), // Réduit de 16 à 8
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildVisualStep(
  BuildContext context, {
  required int stepNumber,
  required IconData icon,
  required String title,
  required String description,
  required Widget imageWidget,
  bool isClickable = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, // Réduit de 28 à 24
            height: 24, // Réduit de 28 à 24
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Réduit de 16 à 14
                ),
              ),
            ),
          ),
          const SizedBox(width: 8), // Réduit de 12 à 8
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16, // Réduit de 18 à 16
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13, // Réduit de 14 à 13
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8), // Réduit de 12 à 8
      Opacity(
        opacity: isClickable ? 1.0 : 0.8,
        child: imageWidget,
      ),
    ],
  );
}
  Widget _buildSocialButton(
    String text,
    String iconPath, {
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}