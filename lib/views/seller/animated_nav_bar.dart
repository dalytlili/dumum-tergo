import 'package:flutter/material.dart';
import 'package:dumum_tergo/constants/colors.dart';

class AnimatedNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDarkMode;
  final List<Widget> screens;
  final bool asBottomBar;
  final int unreadNotifications;

  const AnimatedNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.isDarkMode,
    required this.screens,
    this.asBottomBar = false,
    this.unreadNotifications = 0,
  }) : super(key: key);

  @override
  _AnimatedNavBarState createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    
    final Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color selectedItemColor = AppColors.primary;
    final Color unselectedItemColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color shadowColor = isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.1);
    final Color iconBackgroundColor = AppColors.primary.withOpacity(0.1);

    // Mode BottomBar
    if (widget.asBottomBar) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: backgroundColor,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            height: 1.5,
          ),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: _buildNavItems(
            iconBackgroundColor, 
            selectedItemColor, 
            unselectedItemColor,
            isDarkMode, // Passer isDarkMode ici
          ),
        ),
      );
    }

    // Mode normal (avec contenu)
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: widget.currentIndex,
            children: widget.screens,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            child: BottomNavigationBar(
              currentIndex: widget.currentIndex,
              onTap: widget.onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: backgroundColor,
              selectedItemColor: selectedItemColor,
              unselectedItemColor: unselectedItemColor,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                height: 1.5,
              ),
              selectedFontSize: 12,
              unselectedFontSize: 11,
              elevation: 0,
              items: _buildNavItems(
                iconBackgroundColor, 
                selectedItemColor, 
                unselectedItemColor,
                isDarkMode, // Passer isDarkMode ici
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(
    Color iconBackgroundColor,
    Color selectedItemColor,
    Color unselectedItemColor,
    bool isDarkMode, // Ajouter ce paramètre
  ) {
    return [
    _buildNavItem(Icons.directions_car_filled, "Mes voitures", 0, iconBackgroundColor, selectedItemColor, unselectedItemColor, isDarkMode),
    _buildNavItem(Icons.calendar_today, "Mes réservations", 1, iconBackgroundColor, selectedItemColor, unselectedItemColor, isDarkMode),
      _buildNavItem(Icons.shopping_bag, "Boutique", 2, iconBackgroundColor, selectedItemColor, unselectedItemColor, isDarkMode),
      _buildNavItem(Icons.person, "Profil", 3, iconBackgroundColor, selectedItemColor, unselectedItemColor, isDarkMode),
    ];
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
    Color iconBackgroundColor,
    Color selectedItemColor,
    Color unselectedItemColor,
    bool isDarkMode, // Ajouter ce paramètre
  ) {
    bool isSelected = widget.currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? iconBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected ? LinearGradient(
            colors: [
              iconBackgroundColor.withOpacity(0.8),
              iconBackgroundColor.withOpacity(0.4),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  size: isSelected ? 26 : 24,
                  color: isSelected ? selectedItemColor : unselectedItemColor,
                ),
                if (index == 3 && widget.unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[900]! : Colors.white, // Correction ici
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          widget.unreadNotifications > 9 ? '9+' : widget.unreadNotifications.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 16,
                decoration: BoxDecoration(
                  color: selectedItemColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
      label: label,
    );
  }
}