import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/user/ChangePasswordViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatelessWidget {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ChangePasswordViewModel>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier le mot de passe'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Champ pour l'ancien mot de passe
            TextField(
              controller: _oldPasswordController,
              obscureText: !viewModel.isOldPasswordVisible, // Utiliser l'état de visibilité spécifique
              decoration: InputDecoration(
                labelText: 'Ancien mot de passe',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    viewModel.isOldPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: viewModel.toggleOldPasswordVisibility, // Basculer la visibilité pour ce champ
                ),
              ),
            ),
            SizedBox(height: 20),
            // Champ pour le nouveau mot de passe
            TextField(
              controller: _newPasswordController,
              obscureText: !viewModel.isNewPasswordVisible, // Utiliser l'état de visibilité spécifique
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    viewModel.isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: viewModel.toggleNewPasswordVisibility, // Basculer la visibilité pour ce champ
                ),
              ),
            ),
            SizedBox(height: 20),
            // Champ pour confirmer le nouveau mot de passe
            TextField(
              controller: _confirmPasswordController,
              obscureText: !viewModel.isConfirmPasswordVisible, // Utiliser l'état de visibilité spécifique
              decoration: InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    viewModel.isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: viewModel.toggleConfirmPasswordVisibility, // Basculer la visibilité pour ce champ
                ),
              ),
            ),
            SizedBox(height: 20),
            if (viewModel.isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () async {
                  await viewModel.changePassword(
                    oldPassword: _oldPasswordController.text,
                    newPassword: _newPasswordController.text,
                    confirmPassword: _confirmPasswordController.text,
                  );

                  if (viewModel.errorMessage.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(viewModel.errorMessage)),
                    );
                  } else if (viewModel.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mot de passe modifié avec succès.')),
                    );
                    Navigator.pop(context); // Rediriger l'utilisateur vers l'écran précédent
                  }
                },
                child: Text('Modifier le mot de passe'),
              ),
          ],
        ),
      ),
    );
  }
}