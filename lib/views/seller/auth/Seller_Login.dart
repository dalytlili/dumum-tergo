import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/seller/SellerLoginViewModel.dart';
import 'package:dumum_tergo/views/user/auth/otp_verification_screen.dart';
import 'package:dumum_tergo/views/seller/auth/otp_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:provider/provider.dart';

class SellerLoginView extends StatefulWidget {
  const SellerLoginView({Key? key}) : super(key: key);

  @override
  _SellerLoginViewState createState() => _SellerLoginViewState();
}

class _SellerLoginViewState extends State<SellerLoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SellerLoginViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Se connecter'),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
 ? Colors.transparent : Colors.white,

      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Contenu principal qui peut défiler
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),
                            Text(
                              'Connectez-vous avec votre numéro de téléphone',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Un OTP sera envoyé à ce numéro pour vérification.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: viewModel.phoneNumberController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: 'Numéro de téléphone',
                                prefixIcon: InkWell(
                                  onTap: () {
                                    showCountryPicker(
                                      context: context,
                                      showPhoneCode: true,
                                      onSelect: (Country country) {
                                        setState(() {
                                          viewModel.selectedCountry = country;
                                        });
                                      },
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                            color: Theme.of(context).brightness ==
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
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre numéro de téléphone';
                                }
                                if (!RegExp(r'^\d+$').hasMatch(value)) {
                                  return 'Veuillez entrer un numéro valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Consumer<SellerLoginViewModel>(
                              builder: (context, viewModel, child) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: viewModel.isLoading
                                        ? null
                                        : () async {
                                            if (_formKey.currentState!.validate()) {
                                              bool success =
                                                  await viewModel.verifyPhoneNumber();

                                              if (!success && mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(viewModel.errorMessage ??
                                                        "Erreur inconnue"),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        "Code OTP envoyé avec succès !"),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        OtpVerificationSellerScreen(
                                                      phoneNumber:
                                                          '+${viewModel.selectedCountry.phoneCode}${viewModel.phoneNumberController.text.trim()}',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                    ),
                                    ),
                                    child: viewModel.isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white)
                                        : const Text(
                                            'Connexion',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Texte en bas qui reste fixe
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'En vous inscrivant, vous acceptez nos conditions générales, reconnaissez notre politique de confidentialité, et confirmez avoir plus de 18 ans. Nous pouvons envoyer des promotions liées à nos services - vous pouvez vous désabonner à tout moment dans les paramètres de communication sous votre profil.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
}