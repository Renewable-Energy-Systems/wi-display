import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  Function(Map<String, dynamic>)? onGauge;

  void connect(String url) {
    disconnect();

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
      if (data is Map) onGauge?.call(Map<String, dynamic>.from(data));
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
