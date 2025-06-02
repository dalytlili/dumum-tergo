import 'package:dumum_tergo/views/user/auth/set_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/user/otp_verification_viewmodel.dart';

class OtpVerificationScreen extends StatelessWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OtpVerificationViewModel(fullPhoneNumber: phoneNumber),
      child: const _OtpVerificationScreenContent(),
    );
  }
}

class _OtpVerificationScreenContent extends StatefulWidget {
  const _OtpVerificationScreenContent();

  @override
  State<_OtpVerificationScreenContent> createState() =>
      _OtpVerificationScreenContentState();
}

class _OtpVerificationScreenContentState
    extends State<_OtpVerificationScreenContent> {
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

  void _onOtpChanged(BuildContext context, OtpVerificationViewModel viewModel) {
    final otpCode = _otpControllers.map((c) => c.text).join();
    viewModel.setOtpCode(otpCode);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OtpVerificationViewModel>();

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
          final success = await viewModel.verifyOTP();
          if (success && mounted) {
            debugPrint('User ID avant navigation: ${viewModel.userId}'); // Afficher userId
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => SetPasswordScreen(),
                settings: RouteSettings(arguments: viewModel.userId), // Passer userId ici
              ),
            );
          } else if (mounted) {
            // Clear OTP inputs if failed
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
        },
  style: ElevatedButton.styleFrom(
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