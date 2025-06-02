import 'package:flutter/material.dart';
import 'package:dumum_tergo/constants/colors.dart';
class AnimatedNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDarkMode;
  final List<Widget> screens;
  final bool asBottomBar; // Nouveau paramètre

  const AnimatedNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.isDarkMode,
    required this.screens,
    this.asBottomBar = false, // Par défaut false
  }) : super(key: key);

  @override
  _AnimatedNavBarState createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar> {
  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = widget.isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color selectedItemColor = widget.isDarkMode ? AppColors.primary : AppColors.primary;
    final Color unselectedItemColor = widget.isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color shadowColor = widget.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.1);
    final Color iconBackgroundColor = widget.isDarkMode ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.2);

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
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: _buildNavItems(
            iconBackgroundColor, 
            selectedItemColor, 
            unselectedItemColor
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
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 0,
              items: _buildNavItems(
                iconBackgroundColor, 
                selectedItemColor, 
                unselectedItemColor
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
  ) {
    return [
      _buildNavItem(Icons.directions_car, "Voiture Location", 0, iconBackgroundColor, selectedItemColor, unselectedItemColor),
      _buildNavItem(Icons.list, "Liste Voitures", 1, iconBackgroundColor, selectedItemColor, unselectedItemColor),
      _buildNavItem(Icons.shopping_cart, "Marketplace", 2, iconBackgroundColor, selectedItemColor, unselectedItemColor),
      _buildNavItem(Icons.person, "Profile", 3, iconBackgroundColor, selectedItemColor, unselectedItemColor),
    ];
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
    Color iconBackgroundColor,
    Color selectedItemColor,
    Color unselectedItemColor,
  ) {
    bool isSelected = widget.currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? iconBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: isSelected ? 30 : 26,
          color: isSelected ? selectedItemColor : unselectedItemColor,
        ),
      ),
      label: label,
    );
  }
}