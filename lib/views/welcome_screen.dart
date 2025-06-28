import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/animation.dart';
import '../constants/colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Fade animation for the logo
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Scale animation for the logo
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Slide animation for the buttons
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    // Start animations after build completes
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final maxHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
  
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Animated logo
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    isDarkMode
                        ? 'assets/images/logo2.png'
                        : 'assets/images/logo.png',
                    height: maxHeight * 0.3,
                  ),
                ),
                const SizedBox(height: 32),
                // Title with fade animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Bienvenue dans l\'aventure !',
                    style: TextStyle(
                      fontSize: maxWidth > 600 ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                      shadows: isDarkMode
                          ? [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(2.0, 2.0),
                              ),
                            ]
                          : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                // Subtitle with fade animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Trouvez tout ce dont vous avez besoin pour un camping inoubliable.',
                    style: TextStyle(
                      fontSize: maxWidth > 600 ? 18 : 16,
                      color: isDarkMode ? Colors.white : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                // Slide up animation for buttons
                SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/signin_seller'),
                    isDarkMode: isDarkMode,
                    icon: Icons.store,
                    label: 'Je suis un Vendeur',
                    maxWidth: maxWidth,
                  ),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/signin'),
                    isDarkMode: isDarkMode,
                    icon: Icons.person,
                    label: 'Je suis un Utilisateur',
                    maxWidth: maxWidth,
                    isOutlined: true,
                  ),
                ),
                SizedBox(height: maxHeight * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDarkMode;
  final IconData icon;
  final String label;
  final double maxWidth;
  final bool isOutlined;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.isDarkMode,
    required this.icon,
    required this.label,
    required this.maxWidth,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return isOutlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: isDarkMode
                  ? Colors.transparent
                  : AppColors.primary.withOpacity(0.05),
              elevation: 0,
            ),
            icon: Icon(
              icon,
              size: 24,
              color: AppColors.primary,
            ),
            label: Text(
              label,
              style: TextStyle(
                fontSize: maxWidth > 600 ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.3),
            ),
            icon: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
            label: Text(
              label,
              style: TextStyle(
                fontSize: maxWidth > 600 ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
  }
}