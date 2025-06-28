import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
class NotificationServiceuser {
  static final NotificationServiceuser _instance = NotificationServiceuser._internal();
  factory NotificationServiceuser() => _instance;
  NotificationServiceuser._internal();

  final _storage = const FlutterSecureStorage();
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final _notificationsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  List<Map<String, dynamic>> _notifications = [];
  String? _userId;
  bool _isConnecting = false;
  Timer? _reconnectTimer;

  Stream<List<Map<String, dynamic>>> get notificationsStream => _notificationsController.stream;

  Future<void> initialize() async {
    await _initAudioPlayer();
    await _initNotifications();
    await _initializeWebSocket();
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
    print('Initialisation des notifications...');
    if (Platform.isAndroid) {
  final status = await Permission.notification.request();
  if (!status.isGranted) {
    print('Permissions de notification non accordées');
  }
}
    // Suppression préalable du canal existant (pour éviter les conflits)
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.deleteNotificationChannel('notifications_channel');
    }

    // Configuration des permissions pour iOS
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    }

    // Configuration du canal de notification pour Android
    var androidChannel = AndroidNotificationChannel(
      'notifications_channel',
      'Notifications importantes',
      description: 'Notifications pour les nouvelles activités',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      ledColor: Colors.blue,
   
    );

    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }

    // Initialisation des paramètres
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    // Initialisation du plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        print('Notification cliquée: ${response.payload}');
        // Traitez le clic sur la notification ici
      },
    );

    print('Initialisation des notifications terminée');
  }

  Future<void> _initializeWebSocket() async {
    try {
      String? token = await _storage.read(key: 'token');
      if (token == null) {
        print('Aucun token utilisateur trouvé');
        return;
      }

      final userId = await _getUserIdFromToken(token);
      if (userId == null) {
        print('Impossible d\'extraire l\'ID utilisateur du token');
        return;
      }

      _userId = userId;
      await _connectToWebSocket(userId);
    } catch (e) {
      print('Erreur WebSocket: $e');
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

      return jsonMap['userId']?.toString() ?? jsonMap['id']?.toString();
    } catch (e) {
      print('Erreur de décodage token: $e');
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

      // Adresse adaptée à la plateforme
      final serverUrl = Platform.isAndroid ? 'ws://10.0.2.2:9098' : 'ws://localhost:9098';
      print('Tentative de connexion WebSocket à: wss://dumum-tergo-backend.onrender.com');

      _channel = WebSocketChannel.connect(
        Uri.parse('wss://dumum-tergo-backend.onrender.com/?userId=$userId'),
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
      print('Message brut reçu: $message');
      final data = json.decode(message);
      print('Message décodé: $data');

      if (data is! Map<String, dynamic>) {
        print('Format de message inattendu');
        return;
      }

      final type = data['type'];
      final content = data['data'] ?? data;
      print('Type: $type, Content: $content');

      if (type == 'reservation_accepted' || 
          type == 'reservation_rejected' || 
           type == 'experience_comment' || 
          type == 'experience_like') {
_handleNewNotification(
  content is Map
      ? Map<String, dynamic>.from(content)
      : {'message': content.toString()},
  type,
);
      } else if (type == 'existing_notifications') {
        _handleExistingNotifications(content);
      } else {
        print('Type de notification non géré: $type');
      }
    } catch (e) {
      print('Erreur de traitement du message: $e\nMessage: $message');
    }
  }

  void _handleNewNotification(Map<String, dynamic> notification, String type) {
    _notifications.insert(0, notification);
    _notificationsController.add(List.from(_notifications));

    String title;
    String body;

    if (type == 'reservation_accepted') {
      title = 'Réservation acceptée';
      body = 'Votre réservation a été acceptée';
    } else if (type == 'reservation_rejected') {
      title = 'Réservation refusée';
      body = 'Votre réservation a été refusée';
    } else if (type == 'experience_like') {
      title = 'Nouveau j\'jaime';
      body = notification['message'] ?? 'Quelqu\'un a aimé votre expérience';
    }else if (type == 'experience_comment') {
      title = 'Nouveau commentaire !';
      body = notification['message'] ?? 'Quelqu\'un a commenter a votre expérience';
    }  else {
      title = 'Nouvelle notification';
      body = notification['message'] ?? 'Vous avez une nouvelle notification';
    }

    _showNotification(title, body, notification);
  }

  void _handleExistingNotifications(Map<String, dynamic> data) {
    if (data['notifications'] is List) {
      final List notificationsList = data['notifications'];
      _notifications = notificationsList.whereType<Map<String, dynamic>>().toList();
      _notificationsController.add(List.from(_notifications));
    }
  }

  Future<void> _showNotification(String title, String body, Map<String, dynamic> data) async {
    await _playNotificationSound();
    print('Préparation de la notification: $title - $body');
    print('Données de notification: $data');

    try {
      final androidDetails = AndroidNotificationDetails(
        'notifications_channel',
        'Notifications',
        channelDescription: 'Notifications en temps réel',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        color: const Color.fromARGB(255, 0, 74, 173),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Génération d'un ID unique pour la notification
      final notificationId = data['experienceId']?.hashCode ?? 
                           data['reservationId']?.hashCode ?? 
                           DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        details,
        payload: json.encode(data),
      );

      print('Notification affichée avec succès (ID: $notificationId)');
    } catch (e) {
      print('Erreur lors de l\'affichage de la notification: $e');
    }
  }
}