import 'package:dumum_tergo/viewmodels/user/PasswordViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';

class SetPasswordScreen extends StatefulWidget {
  @override
  _SetPasswordScreenState createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

 void _savePassword(PasswordViewModel viewModel) async {
  if (_formKey.currentState!.validate()) {
    await viewModel.setPassword(viewModel.passwordController.text, viewModel.confirmPasswordController.text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mot de passe enregistré avec succès !"))
    );

    // ✅ Rediriger l'utilisateur après succès
    Navigator.pushReplacementNamed(context, '/signin');
  }
}


@override
Widget build(BuildContext context) {
  // Récupérer userId des arguments de la route
  final String? userId = ModalRoute.of(context)?.settings.arguments as String?;

  // Vérifier si userId est null et gérer le cas
  if (userId == null) {
    return Scaffold(
      appBar: AppBar(title: const Text("Erreur")),
      body: Center(
        child: Text("Erreur : ID utilisateur manquant."),
      ),
    );
  }

  return ChangeNotifierProvider(
    create: (_) => PasswordViewModel(userId: userId), // Passer userId au ViewModel
    child: Consumer<PasswordViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Définir un nouveau mot de passe'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Changer le mot de passe',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildPasswordField(viewModel),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(viewModel),
                    const SizedBox(height: 24),
                    _buildSignUpButton(viewModel),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}


  Widget _buildPasswordField(PasswordViewModel viewModel) {
    return TextFormField(
      controller: viewModel.passwordController,
      obscureText: !viewModel.isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Mot de passe',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            viewModel.isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: viewModel.togglePasswordVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer un mot de passe';
        }
        if (value.length < 8) {
          return 'Le mot de passe doit contenir au moins 8 caractères';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(PasswordViewModel viewModel) {
    return TextFormField(
      controller: viewModel.confirmPasswordController,
      obscureText: !viewModel.isConfirmPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Confirmer le mot de passe',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            viewModel.isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: viewModel.toggleConfirmPasswordVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez confirmer votre mot de passe';
        }
        if (value != viewModel.passwordController.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton(PasswordViewModel viewModel) {
    return ElevatedButton(
      onPressed: () => _savePassword(viewModel),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        'Valider',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
