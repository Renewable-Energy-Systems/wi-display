import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  // Use a broadcast stream so multiple screens can listen if needed
  final _gaugeController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get gaugeStream => _gaugeController.stream;

  void connect(String url) {
    // If already connected to the same URL, don't reconnect
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      print("[SOCKET] Connected");
    });

    socket!.on("gauge_update", (data) {
      if (data is Map) {
        // Add data to the stream
        _gaugeController.add(Map<String, dynamic>.from(data));
      }
    });

    socket!.onDisconnect((_) => print("[SOCKET] Disconnected"));
    socket!.onConnectError((err) => print("[SOCKET] Error: $err"));

    socket!.connect();
  }

  void disconnect() {
    try {
      socket?.disconnect();
    } catch (_) {}
    socket = null;
  }
}
