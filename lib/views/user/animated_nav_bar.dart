import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/views/user/event/camping_events_screen.dart';
import 'package:dumum_tergo/views/user/experiences/experiences_screen.dart';
import 'package:dumum_tergo/views/user/experiences/user_search_screen.dart';
import 'package:dumum_tergo/views/user/item/camping_items_screen.dart';
import 'package:dumum_tergo/views/user/car/notifications_page.dart';
import 'package:dumum_tergo/views/user/car/rental_search_view.dart';
import 'package:dumum_tergo/views/user/side_menu_view.dart';
import 'package:dumum_tergo/views/user/experiences/profile_view.dart';
import 'package:flutter/material.dart';
import '../../services/notification_service_user.dart';
import 'dart:async';

class AnimatedNavBar extends StatefulWidget {
  final bool isDarkMode;

  const AnimatedNavBar({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _AnimatedNavBarState createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _unreadNotifications = 0;
  late StreamSubscription _notificationSubscription;
  final NotificationServiceuser _notificationService = NotificationServiceuser();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _lastTappedIndex;
  DateTime? _lastTapTime;
  late List<Widget> _screens;

  final List<String> _appBarTitles = [
    'Accueil',
    'Rechercher une voiture',
    'Marketplace',
    'Événements',
    'Profil',
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _initializeNotifications();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void _initializeScreens() {
    _screens = [
      const ExperiencesScreen(key: ValueKey('experiences')),
      const RentalSearchView(key: ValueKey('rental')),
      const CampingItemsScreen(key: ValueKey('items')),
      const CampingEventsScreen(key: ValueKey('events')),
      ProfileView(key: const ValueKey('profile')),
    ];
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    
    _notificationSubscription = _notificationService.notificationsStream.listen((notifications) {
      final unreadCount = notifications.where((n) => n['read'] == false).length;
      
      if (mounted) {
        setState(() {
          _unreadNotifications = unreadCount;
        });
      }
    });
  }

  void _handleTabTap(int index) {
    final now = DateTime.now();
    final isSameTab = index == _currentIndex;
    final isDoubleTap = _lastTappedIndex == index && 
                       _lastTapTime != null && 
                       now.difference(_lastTapTime!) < const Duration(milliseconds: 300);

    setState(() {
      _currentIndex = index;
    });

    if (isSameTab && isDoubleTap) {
      _reloadCurrentScreen();
    }

    _lastTappedIndex = index;
    _lastTapTime = now;
  }

  void _reloadCurrentScreen() {
    final newKey = ValueKey('${_currentIndex}_reloaded_${DateTime.now().millisecondsSinceEpoch}');
    final newScreens = List<Widget>.from(_screens);
    
    switch (_currentIndex) {
      case 0:
        newScreens[0] = ExperiencesScreen(key: newKey);
        break;
      case 1:
        newScreens[1] = RentalSearchView(key: newKey);
        break;
      case 2:
        newScreens[2] = CampingItemsScreen(key: newKey);
        break;
      case 3:
        newScreens[3] = CampingEventsScreen(key: newKey);
        break;
      case 4:
        newScreens[4] = ProfileView(key: newKey);
        break;
    }

    setState(() {
      _screens = newScreens;
    });
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
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
    final Color appBarColor = isDarkMode ? Colors.black! : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
              ),
            ),
            Text(
              _appBarTitles[_currentIndex],
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: appBarColor,
        elevation: 1,
        iconTheme: IconThemeData(
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserSearchScreen(),
                ),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, size: 26),
                onPressed: () async {
                  _animationController.forward().then((_) {
                    _animationController.reverse();
                  });
                  
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NotificationsUserPage(
                        onNotificationsRead: () {
                          setState(() {
                            _unreadNotifications = 0;
                          });
                        },
                      ),
                    ),
                  );
                  
                  if (result != null && result is int) {
                    setState(() {
                      _unreadNotifications = result;
                    });
                  }
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: appBarColor,
                          width: 2,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
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
          const SizedBox(width: 8),
        ],
      ),
      drawer: const SideMenuView(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
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
            currentIndex: _currentIndex,
            onTap: _handleTabTap,
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
            items: [
              _buildNavItem(Icons.home_filled, "Accueil", 0, iconBackgroundColor, selectedItemColor, unselectedItemColor),
              _buildNavItem(Icons.directions_car_filled, "Voitures", 1, iconBackgroundColor, selectedItemColor, unselectedItemColor),
              _buildNavItem(Icons.shopping_bag, "Boutique", 2, iconBackgroundColor, selectedItemColor, unselectedItemColor),
              _buildNavItem(Icons.event, "Événements", 3, iconBackgroundColor, selectedItemColor, unselectedItemColor),
              _buildNavItem(Icons.person, "Profil", 4, iconBackgroundColor, selectedItemColor, unselectedItemColor),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
    Color iconBackgroundColor,
    Color selectedItemColor,
    Color unselectedItemColor,
  ) {
    bool isSelected = _currentIndex == index;
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
            Icon(
              icon,
              size: isSelected ? 26 : 24,
              color: isSelected ? selectedItemColor : unselectedItemColor,
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