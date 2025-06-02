import 'package:dumum_tergo/views/user/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

class ReservationSuccessPage extends StatefulWidget {
  final Map<String, dynamic> reservationData;

  const ReservationSuccessPage({Key? key, required this.reservationData}) : super(key: key);

  @override
  State<ReservationSuccessPage> createState() => _ReservationSuccessPageState();
}

class _ReservationSuccessPageState extends State<ReservationSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Délai pour démarrer l'animation après le build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.reservationData['car'] is Map ? widget.reservationData['car'] : {};
    final brand = car['brand']?.toString() ?? 'Inconnu';
    final model = car['model']?.toString() ?? 'Inconnu';
    final totalPrice = widget.reservationData['totalPrice']?.toString() ?? '0';
    final formattedPrice = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND').format(double.tryParse(totalPrice));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation de réservation'),
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.primary.withOpacity(0.02),
              Theme.of(context).colorScheme.background, // Adapté au dark mode
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(20),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Réservation confirmée!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Votre véhicule est réservé avec succès',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).hintColor, // Adapté au dark mode
                    ),
              ),
            ),
            const SizedBox(height: 32),
            SlideTransition(
              position: _slideAnimation,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Theme.of(context).cardColor, // Adapté au dark mode
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.confirmation_number,
                        label: 'Référence',
                        value: widget.reservationData['_id']?.toString() ?? '',
                      ),
                      Divider(height: 24, color: Theme.of(context).dividerColor), // Adapté
                      _buildDetailRow(
                        icon: Icons.directions_car,
                        label: 'Véhicule',
                        value: '$brand $model',
                      ),
                      Divider(height: 24, color: Theme.of(context).dividerColor), // Adapté
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Période',
                        value: '${_formatDate(widget.reservationData['startDate'])} - ${_formatDate(widget.reservationData['endDate'])}',
                      ),
                      Divider(height: 24, color: Theme.of(context).dividerColor), // Adapté
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Lieu',
                        value: widget.reservationData['location']?.toString() ?? '',
                      ),
                      Divider(height: 24, color: Theme.of(context).dividerColor), // Adapté
                      _buildDetailRow(
                        icon: Icons.attach_money,
                        label: 'Prix total',
                        value: formattedPrice,
                        isPrice: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const HomeView(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary, // Texte contrasté
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: Icon(Icons.home, size: 20, color: Theme.of(context).colorScheme.onPrimary),
                  label: Text(
                    "Retour à l'accueil",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimary, // Texte contrasté
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isPrice = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor, // Texte secondaire
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface, // Texte principal
                        fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy').format(parsedDate);
      }
      return 'Date inconnue';
    } catch (e) {
      return 'Date inconnue';
    }
  }
}