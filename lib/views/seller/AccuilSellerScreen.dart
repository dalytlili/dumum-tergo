import 'package:dumum_tergo/viewmodels/seller/AccueilViewModel.dart';
import 'package:dumum_tergo/viewmodels/seller/liste_car_viewmodel.dart';
import 'package:dumum_tergo/viewmodels/theme_viewmodel.dart';
import 'package:dumum_tergo/views/seller/car/add-car-rental-page.dart';
import 'package:dumum_tergo/views/seller/animated_nav_bar.dart';
import 'package:dumum_tergo/views/seller/auth/EditProfileSellerView.dart';
import 'package:dumum_tergo/views/seller/car/car-detail-page.dart';
import 'package:dumum_tergo/views/seller/car/car-reservations-page.dart';
import 'package:dumum_tergo/views/seller/item/liste_items_screen_seller.dart';
import 'package:dumum_tergo/views/seller/car/liste-seller-car.dart';
import 'package:dumum_tergo/views/seller/car/reservation_detail_page.dart';
import 'package:dumum_tergo/views/seller/side_menu_view.dart';
import 'package:dumum_tergo/views/seller/car/notifications_page.dart';
import 'package:dumum_tergo/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class AccuilSellerScreen extends StatefulWidget {
  const AccuilSellerScreen({Key? key}) : super(key: key);

  @override
  State<AccuilSellerScreen> createState() => _AccuilSellerScreenState();
}

class _AccuilSellerScreenState extends State<AccuilSellerScreen> {
  int _currentIndex = 0;
  Widget? _overlayContent;
  int _unreadNotifications = 0;
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _notificationsSubscription;

  late final List<Widget> _screens;

  final List<String> _appBarTitles = [
    "Voitures en location",
    "Liste des voitures",
    "Marketplace",
 
    "Profil"
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      ListeSellerCar(
        onCarSelected: (car) {
          setState(() {
            _overlayContent = CarDetailPage(
              car: car,
              onBack: () {
                setState(() {
                  _overlayContent = null;
                });
              },
              onCarDeleted: () {
                if (mounted) {
                  setState(() {
                    _overlayContent = null;
                       final viewModel = Provider.of<ListeCarViewModel>(context, listen: false);
              viewModel.fetchCarsFromVendor();
              
                  });
                }
              },
            );
          });
        },
      ),
      CarReservationsPage(
        onReservationSelected: (reservation) {
          setState(() {
            _overlayContent = ReservationDetailPage(
              reservation: reservation,
              onBack: () {
                setState(() {
                  _overlayContent = null;
                });
              },
            );
          });
        },
      ),
      const CampingItemsScreenSeller(),
      EditProfileSellerView(),
    ];
  }




  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();
    final accueilViewModel = Provider.of<AccueilViewModel>(context);
    accueilViewModel.fetchToken();

    return Scaffold(
      body: Stack(
        children: [
          // Contenu principal
          _buildCurrentScreen(),
          
          // Overlay (si présent)
          if (_overlayContent != null)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _overlayContent,
            ),
        ],
      ),
      bottomNavigationBar: AnimatedNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _overlayContent = null;
            _currentIndex = index;
          });
        },
        isDarkMode: themeViewModel.isDarkMode,
        screens: _screens,
        asBottomBar: true,
      ),
    );
  }

  Widget _buildCurrentScreen() {
    return IndexedStack(
      index: _currentIndex,
      children: _screens,
    );
  }
}