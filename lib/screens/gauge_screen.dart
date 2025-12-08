// lib/screens/gauge_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../config/api_constants.dart';
import '../services/config_service.dart';
import 'det_selector_screen.dart';
import 'settings_screen.dart';

class GaugeScreen extends StatefulWidget {
  const GaugeScreen({super.key});

  @override
  State<GaugeScreen> createState() => _GaugeScreenState();
}

class _GaugeScreenState extends State<GaugeScreen> with AutomaticKeepAliveClientMixin {
  String liveValue = "--.---";
  bool isConnected = false;
  StreamSubscription? _gaugeSub;
  String _machineName = "Unknown";
  String _machineIp = "";

  // WebSocket channel for DET selector & updates
  WebSocketChannel? _detChannel;
  final String detWsUrl = ApiConstants.detWsUrl; 
  final String apiHost = ApiConstants.detApiHost; 

  @override
  void initState() {
    super.initState();
    _loadConfig();

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

    // 2) Connect socket
    _connectSocket();

    // 3) create a WS channel dedicated for DET subscriptions & UI
    try {
      _detChannel = IOWebSocketChannel.connect(detWsUrl);
      _detChannel!.stream.listen(
        (msg) {
          // optionally route DET updates here to update gauge
          // print('DET WS raw: $msg');
        },
        onError: (err) {
          debugPrint('DET WS error: $err');
        },
        onDone: () {
          debugPrint('DET WS closed');
        },
      );
      _detChannel = null;
    } catch (_) { // Add catch block
       // ignore or log
       _detChannel = null;
       _detChannel = null;
    }
  }

  Future<void> _loadConfig() async {
    final name = await ConfigService().getSavedMachineType();
    setState(() {
      _machineName = name;
    });
  }

  Future<void> _connectSocket() async {
    final url = await ConfigService().getBaseUrl();
    setState(() {
      _machineIp = url;
    });
    SocketService().connect(url);
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Live Gauge",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "Model: $_machineName", 
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.normal),
            )
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
           IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueGrey),
            tooltip: 'Configuration',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              // Refresh config on return
              _loadConfig();
              _connectSocket();
            },
          ),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Connection Status Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: isConnected ? Colors.green[700] : Colors.red[700],
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? "Connected to $_machineName" : "Connecting to $_machineName...",
                          style: TextStyle(
                            fontSize: 14,
                            color: isConnected ? Colors.green[900] : Colors.red[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_machineIp.isNotEmpty)
                          Text(
                            _machineIp,
                            style: TextStyle(
                              fontSize: 12,
                              color: isConnected ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Gauge Value Card
              Container(
                padding: const EdgeInsets.all(50),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "CURRENT MEASUREMENT",
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 1.5,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      liveValue,
                      style: const TextStyle(
                        fontFamily: 'monospace', // Better for numbers
                        fontSize: 80,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A66FF),
                        letterSpacing: -2,
                      ),
                    ),
                     const Text(
                      "mm", // Assuming unit, can be dynamic
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
