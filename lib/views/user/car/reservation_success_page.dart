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

    // Facteur de réduction pour les petits écrans
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final scaleFactor = isSmallScreen ? 0.8 : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation de réservation'),
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0 * scaleFactor),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.primary.withOpacity(0.02),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
                padding: EdgeInsets.all(16.0 * scaleFactor),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60.0 * scaleFactor,
                ),
              ),
            ),
            SizedBox(height: 8.0 * scaleFactor),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Réservation confirmée!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18.0 * scaleFactor,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 4.0 * scaleFactor),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Votre véhicule est réservé avec succès',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: 14.0 * scaleFactor,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8.0 * scaleFactor),
            SlideTransition(
              position: _slideAnimation,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0 * scaleFactor),
                ),
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: EdgeInsets.all(12.0 * scaleFactor),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.confirmation_number,
                        label: 'Référence',
                        value: widget.reservationData['_id']?.toString() ?? '',
                        scaleFactor: scaleFactor,
                      ),
                      Divider(height: 16.0 * scaleFactor, color: Theme.of(context).dividerColor),
                      _buildDetailRow(
                        icon: Icons.directions_car,
                        label: 'Véhicule',
                        value: '$brand $model',
                        scaleFactor: scaleFactor,
                      ),
                      Divider(height: 16.0 * scaleFactor, color: Theme.of(context).dividerColor),
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Période',
                        value: '${_formatDate(widget.reservationData['startDate'])} - ${_formatDate(widget.reservationData['endDate'])}',
                        scaleFactor: scaleFactor,
                      ),
                      Divider(height: 16.0 * scaleFactor, color: Theme.of(context).dividerColor),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Lieu',
                        value: widget.reservationData['location']?.toString() ?? '',
                        scaleFactor: scaleFactor,
                      ),
                      Divider(height: 16.0 * scaleFactor, color: Theme.of(context).dividerColor),
                      _buildDetailRow(
                        icon: Icons.attach_money,
                        label: 'Prix total',
                        value: formattedPrice,
                        isPrice: true,
                        scaleFactor: scaleFactor,
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
                padding: EdgeInsets.only(bottom: 16.0 * scaleFactor),
                child: SizedBox(
                  width: double.infinity,
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
                      minimumSize: Size(double.infinity, 40.0 * scaleFactor),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0 * scaleFactor),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0 * scaleFactor,
                        vertical: 8.0 * scaleFactor,
                      ),
                    ),
                    icon: Icon(
                      Icons.home,
                      size: 18.0 * scaleFactor,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    label: Text(
                      "Retour à l'accueil",
                      style: TextStyle(
                        fontSize: 14.0 * scaleFactor,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
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
    required double scaleFactor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0 * scaleFactor),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20.0 * scaleFactor),
          SizedBox(width: 8.0 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                        fontSize: 12.0 * scaleFactor,
                      ),
                ),
                SizedBox(height: 2.0 * scaleFactor),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14.0 * scaleFactor,
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