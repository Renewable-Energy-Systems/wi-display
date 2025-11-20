import 'dart:async'; // Import needed for StreamSubscription
import 'package:flutter/material.dart';
import '../socket_service.dart';

class GaugeScreen extends StatefulWidget {
  const GaugeScreen({super.key});

  @override
  State<GaugeScreen> createState() => _GaugeScreenState();
}

class _GaugeScreenState extends State<GaugeScreen> {
  String liveValue = "--";
  bool isConnected = false;
  StreamSubscription? _gaugeSub; // Subscription variable

  @override
  void initState() {
    super.initState();

    // 1. Listen to the broadcast stream
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

    // 2. Ensure connection is active
    SocketService().connect("http://192.168.0.53:5050");
  }

  @override
  void dispose() {
    // 3. Cancel the subscription when leaving
    _gaugeSub?.cancel();

    // Optional: Disconnect socket only if you want to stop data flow entirely
    // SocketService().disconnect();

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
                      color: Color(0xFF0A66FF), // Blue accent
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
