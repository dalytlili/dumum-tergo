import 'package:dumum_tergo/main.dart';
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import '../../services/logout_service.dart';

class HomeViewModel with ChangeNotifier {
  final LogoutService logoutService;
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  HomeViewModel({required this.logoutService});
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

}
