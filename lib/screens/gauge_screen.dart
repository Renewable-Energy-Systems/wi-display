// lib/screens/gauge_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'det_selector_screen.dart';

class GaugeScreen extends StatefulWidget {
  const GaugeScreen({super.key});

  @override
  State<GaugeScreen> createState() => _GaugeScreenState();
}

class _GaugeScreenState extends State<GaugeScreen> {
  String liveValue = "--";
  bool isConnected = false;
  StreamSubscription? _gaugeSub;

  // WebSocket channel for DET selector & updates
  WebSocketChannel? _detChannel;
  final String detWsUrl = 'ws://192.168.0.77:3000'; // change if needed
  final String apiHost = 'http://192.168.0.77:3000'; // change if needed

  @override
  void initState() {
    super.initState();

    // 1) existing gauge data subscription (keeps your SocketService usage)
    _gaugeSub = SocketService().gaugeStream.listen((data) {
      if (data.containsKey('value')) {
        if (mounted) {
          setState(() {
            liveValue = data['value'].toString();
            isConnected = true;
          });
        }
      }
    });

    // 2) your existing connection call (keep as-is)
    SocketService().connect("http://192.168.0.53:5050");

    // 3) create a WS channel dedicated for DET subscriptions & UI
    try {
      _detChannel = IOWebSocketChannel.connect(detWsUrl);
      _detChannel!.stream.listen(
        (msg) {
          // optionally route DET updates here to update gauge
          // print('DET WS raw: $msg');
        },
        onError: (err) {
          print('DET WS error: $err');
        },
        onDone: () {
          print('DET WS closed');
        },
      );
    } catch (e) {
      debugPrint('Could not connect to DET WS: $e');
      _detChannel = null;
    }
  }

  @override
  void dispose() {
    _gaugeSub?.cancel();
    try {
      _detChannel?.sink.close();
    } catch (_) {}
    _detChannel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          "Live Gauge",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            tooltip: 'Select DET',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DetSelectorScreen(apiHost: apiHost, channel: _detChannel),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Gauge Reading",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    liveValue,
                    style: const TextStyle(
                      fontSize: 90,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A66FF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isConnected ? "Connected to Gauge" : "Connecting...",
                  style: TextStyle(
                    fontSize: 18,
                    color: isConnected ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
