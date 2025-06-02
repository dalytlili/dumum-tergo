import 'package:dumum_tergo/viewmodels/theme_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'animated_nav_bar.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();
    
    return WillPopScope(
      onWillPop: () async => false,
      child: AnimatedNavBar(
        isDarkMode: themeViewModel.isDarkMode,
      ),
    );
  }
}