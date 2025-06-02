import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/seller/PaymentViewModelV.dart';
import 'package:dumum_tergo/views/seller/AccuilSellerScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({super.key});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<PaymentViewModel>(context, listen: false);
      viewModel.setAmount('Prix: 100 TND / ans');
    });
  }

  void _navigateToSuccessPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>  AccuilSellerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PaymentViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Définir le mode de paiement'),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Souscrivez à un abonnement pour publier vos annonces.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Card(
                color: const Color.fromARGB(255, 221, 255, 226),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Abonnement Premium',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('✔ Publiez des annonces illimitées'),
                      const Text('✔ Assistance prioritaire'),
                      const Text('✔ Visibilité accrue'),
                      const SizedBox(height: 10),
                      Text(
                        'Prix: ${viewModel.amount} TND / ans',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Choisissez votre mode de paiement:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Image.asset('assets/images/flouci_logo.png', width: 40),
                title: const Text('Flouci'),
                trailing: Radio<String>(
                  value: viewModel.paymentMethod.id,
                  groupValue: viewModel.paymentMethod.id,
                  onChanged: (value) {
                    viewModel.selectPaymentMethod();
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        try {
                          await viewModel.payement(context);
                          _navigateToSuccessPage(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur lors du paiement: $e')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.payment, color: Colors.white),
                label: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Payer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}