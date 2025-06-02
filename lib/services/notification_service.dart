import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:dumum_tergo/views/user/auth/sign_in_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final _notificationsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  List<Map<String, dynamic>> _notifications = [];
  String? _userId;
  final FlutterSecureStorage storage = FlutterSecureStorage();
  bool _isConnecting = false;
  Timer? _reconnectTimer;

  Stream<List<Map<String, dynamic>>> get notificationsStream => _notificationsController.stream;

  Future<void> initialize() async {
    await _initAudioPlayer();
    await _initNotifications();
    await _initializeWebSocket();
  }

  Future<void> dispose() async {
    await _socketSubscription?.cancel();
    await _channel?.sink.close();
    _reconnectTimer?.cancel();
    await _notificationsController.close();
    await _audioPlayer.dispose();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print("Erreur d'initialisation audio: $e");
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print('Erreur de lecture audio: $e');
    }
  }

  Future<void> _initNotifications() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      print('Permissions iOS accordées: $result');
    }

    if (Platform.isAndroid) {
      await _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          'notifications_channel',
          'Notifications',
          description: 'Notifications en temps réel',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        ),
      );
    }

    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      ),
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification cliquée: ${response.payload}');
      },
    );
  }

  Future<void> _showNotification(String title, String body) async {
    await _playNotificationSound();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'notifications_channel',
        'Notifications',
        channelDescription: 'Notifications en temps réel',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
      payload: 'notification_payload',
    );
  }

  Future<void> _initializeWebSocket() async {
    try {
      String? token = await storage.read(key: 'seller_token');
      if (token == null) {
        print('Aucun token vendeur trouvé !!');
        return;
      }

      final vendorId = await _getUserIdFromToken(token);
      if (vendorId == null) {
        print('Impossible d\'extraire l\'ID utilisateur du token???');
        return;
      }

      _userId = vendorId;
      await _connectToWebSocket(vendorId);
    } catch (e) {
      print('Erreur d\'initialisation WebSocket: $e');
      _scheduleReconnect();
    }
  }

  Future<String?> _getUserIdFromToken(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final jsonMap = jsonDecode(decoded);

      print("Payload décodé : $jsonMap");

      final user = jsonMap['user'];
      if (user != null && user['_id'] != null) {
        return user['_id'].toString();
      }

      return jsonMap['vendorId']?.toString() ??
             jsonMap['userId']?.toString() ??
             jsonMap['id']?.toString();
    } catch (e) {
      print('Erreur de décodage du token: $e');
      return null;
    }
  }

  Future<void> _connectToWebSocket(String userId) async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      // Fermer les connexions existantes
      await _socketSubscription?.cancel();
      await _channel?.sink.close();

      const String serverUrl = 'dumum-tergo-backend.onrender.com';
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://$serverUrl/?userId=$userId'),
      );

      print('Connexion WebSocket réussie avec l\'ID utilisateur: $userId');

      _socketSubscription = _channel!.stream.listen(
        (message) => _handleSocketMessage(message),
        onError: (error) {
          print('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket fermé');
          _scheduleReconnect();
        },
      );

      _isConnecting = false;
    } catch (e) {
      print('Erreur de connexion WebSocket: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_userId != null) {
        _connectToWebSocket(_userId!);
      }
    });
  }

  void _handleSocketMessage(String message) {
    try {
      final data = json.decode(message);
      if (data is! Map<String, dynamic>) {
        print('Message inattendu: $data');
        return;
      }

      print('Message reçu : $data');

      final type = data['type'];
      final content = data['data'];
      if (content is! Map<String, dynamic>) {
        print('Données de notification invalides : $content');
        return;
      }

      if (type == 'new_reservation') {
        _handleNewNotification(content);
      } else if (type == 'existing_notifications') {
        _handleExistingNotifications(content);
      }
    } catch (e) {
      print('Erreur de traitement du message: $e');
    }
  }

  void _handleNewNotification(Map<String, dynamic> notification) {
    _notifications.insert(0, notification);
    _notificationsController.add(List.from(_notifications));

    final car = notification['car'] as Map<String, dynamic>?;
    final user = notification['user'] as Map<String, dynamic>?;

    final carName = car != null ? '${car['brand']} ${car['model']}' : 'Une voiture';
    final userName = user != null ? user['name'] ?? 'Quelqu\'un' : 'Quelqu\'un';

    final title = 'Nouvelle réservation';
    final body = '$userName a réservé $carName';

    _showNotification(title, body);
  }

  void _handleExistingNotifications(Map<String, dynamic> data) {
    if (data['notifications'] is List) {
      final List notificationsList = data['notifications'];
      _notifications = notificationsList.whereType<Map<String, dynamic>>().toList();
      _notificationsController.add(List.from(_notifications));
    }
  }
}