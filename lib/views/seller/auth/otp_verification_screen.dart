import 'package:dumum_tergo/viewmodels/seller/otp_verification_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OtpVerificationSellerScreen extends StatelessWidget {
  final String phoneNumber;

  const OtpVerificationSellerScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OtpSellerViewModel(fullPhoneNumber: phoneNumber),
      child: const _OtpVerificationSellerScreenContent(),
    );
  }
}

class _OtpVerificationSellerScreenContent extends StatefulWidget {
  const _OtpVerificationSellerScreenContent();

  @override
  State<_OtpVerificationSellerScreenContent> createState() =>
      _OtpVerificationSellerScreenContentState();
}

class _OtpVerificationSellerScreenContentState
    extends State<_OtpVerificationSellerScreenContent> {
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

  void _onOtpChanged(BuildContext context, OtpSellerViewModel viewModel) {
    final otpCode = _otpControllers.map((c) => c.text).join();
    viewModel.setOtpCode(otpCode);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OtpSellerViewModel>();

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
          final success = await viewModel.verifyOTP(context); // Passer le contexte ici
          if (!success && mounted) {
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