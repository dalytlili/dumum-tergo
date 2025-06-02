import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late WebSocketChannel _channel;

  // Se connecter au serveur WebSocket
  void connect() {
    _channel = IOWebSocketChannel.connect('ws://localhost:9099');
  }

  // Écouter les messages du serveur WebSocket
  Stream<dynamic> get stream => _channel.stream;

  // Fermer la connexion WebSocket
  void disconnect() {
    _channel.sink.close();
  }
}