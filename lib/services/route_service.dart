// services/route_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

Future<String> getInitialRoute() async {
  final email = await storage.read(key: 'email');
  final password = await storage.read(key: 'password');
  
  return (email != null && password != null) ? '/welcome' : '/home';
}