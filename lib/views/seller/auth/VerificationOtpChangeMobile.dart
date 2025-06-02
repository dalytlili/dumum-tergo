import 'package:dumum_tergo/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dumum_tergo/viewmodels/seller/VerificationOtpViewModel.dart';

class VerificationOtpChangeMobile extends StatelessWidget {
  final String fullPhoneNumber;

  VerificationOtpChangeMobile({required this.fullPhoneNumber});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VerificationOtpViewModel(fullPhoneNumber: fullPhoneNumber),
      child: const _VerificationOtpChangeMobileContent(),
    );
  }
}

class _VerificationOtpChangeMobileContent extends StatefulWidget {
  const _VerificationOtpChangeMobileContent();

  @override
  State<_VerificationOtpChangeMobileContent> createState() =>
      _VerificationOtpChangeMobileContentState();
}

class _VerificationOtpChangeMobileContentState
    extends State<_VerificationOtpChangeMobileContent> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(BuildContext context, VerificationOtpViewModel viewModel) {
    final otpCode = _otpControllers.map((c) => c.text).join();
    viewModel.setOtpCode(otpCode);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VerificationOtpViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification OTP'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Entrez le code de vérification',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Entrez le code envoyé à ${viewModel.fullPhoneNumber}',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Champs OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 24),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        _onOtpChanged(context, viewModel);
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context)
                              .requestFocus(_otpFocusNodes[index + 1]);
                        }
                        if (value.isEmpty && index > 0) {
                          FocusScope.of(context)
                              .requestFocus(_otpFocusNodes[index - 1]);
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Bouton de vérification
             ElevatedButton(
  onPressed: viewModel.isLoading
      ? null
      : () async {
          try {
            final storage = FlutterSecureStorage();
            final authToken = await storage.read(key: 'seller_token');

            if (authToken == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Token d\'authentification manquant'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            final success = await viewModel.verifyOTP(authToken);
            if (success && mounted) {
              // Fermer la page actuelle
              Navigator.pop(context);

              // Afficher un SnackBar de succès
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil mis à jour avec succès !'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (!success && mounted) {
              // Effacer les champs OTP en cas d'échec
              for (var controller in _otpControllers) {
                controller.clear();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code OTP invalide'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            // Gérer les exceptions spécifiques
            if (e.toString().contains('OTP invalide ou expiré')) {
              if (mounted) {
 for (var controller in _otpControllers) {
                controller.clear();
              }
                FocusScope.of(context).requestFocus(_otpFocusNodes[0]);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code OTP invalide ou expiré'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              // Gérer les autres exceptions
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Une erreur s\'est produite'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
            debugPrint('Erreur lors de la vérification OTP: $e');
          }
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: viewModel.isLoading
      ? const CircularProgressIndicator()
      : const Text('Vérifier'),
),
              const SizedBox(height: 16),

              // Bouton pour renvoyer le code
              TextButton(
                onPressed: viewModel.countdown > 0 || viewModel.isLoading
                    ? null
                    : () async {
                        await viewModel.resendOtp();
                      },
                child: Text(
                  viewModel.countdown > 0
                      ? 'Renvoyer le code (${viewModel.countdown}s)'
                      : 'Renvoyer le code',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}