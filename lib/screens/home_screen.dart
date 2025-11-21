import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Colors (same as your original)
  static const blueMain = Color(0xFF0A66FF); // header + bottom bar
  static const bgGradientTop = Color(0xFFF7FAFF); // page bg start
  static const bgGradientBottom = Color(0xFFF2F6FF); // page bg end
  static const cardBorder = Color(0xFFE6ECFF);
  static const panelBorder = Color(0xFFE1E8FF);
  static const headingText = Color(0xFF1C3366); // "Sensor Information" etc.
  static const labelText = Color(0xFF5A6B8A); // labels in left card
  static const valueText = Color(0xFF103B8C); // values in left card
  static const captionText = Color(0xFF7A8AA6); // "Updated: ..."
  static const dewBg = Color(0xFFF4F8FF); // right card bg
  static const dewBorder = Color(0xFFDFE8FF);
  static const dewLabelText = Color(0xFF1C3FAA); // "Dew Point"
  static const dewBigNumber = Color(0xFF0A66FF); // 20°C
  static const liveGreen = Color(0xFF247A3E); // "Live"

  // Left card static details (these can be made dynamic later)
  final String workstationName = 'WS-001';
  final String probeId = 'PRB-2024-001';
  final String calibrationDate = '15/01/2024';
  final String calibrationDue = '15/01/2025';

  // WS config
  // Use your PC IP here. Example: ws://192.168.0.77:3000
  final String wsUrl = 'ws://192.168.0.77:3000';
  final String subscribedColumn = 'Det01 (°C)';

  // Live values
  String dewPointDisplay = '-- °C';
  String updatedAt = '––';
  String status = 'disconnected';

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _connectWs();
  }

  void _connectWs() {
    // if already connected, do nothing
    if (_channel != null) return;

    setState(() => status = 'connecting');
    try {
      _channel = IOWebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (message) {
          // incoming message from server
          try {
            final m = json.decode(message);
            // debug
            // print('WS msg: $m');

            if (m is Map &&
                m['type'] == 'update' &&
                m['col'] == subscribedColumn) {
              final dew = m['dewpoint_c'];
              final date = m['date'];
              final time = m['time'];

              setState(() {
                dewPointDisplay = (dew == null) ? '-- °C' : '$dew °C';
                updatedAt = (date == null || time == null)
                    ? updatedAt
                    : '$date $time';
                status = 'connected';
              });
            } else if (m is Map && m['type'] == 'welcome') {
              setState(() => status = 'connected');
            }
          } catch (e) {
            // ignore parse error
            // print('WS parse error: $e');
          }
        },
        onDone: () {
          // closed normally
          _cleanupChannel();
          _scheduleReconnect();
        },
        onError: (err) {
          // error
          // print('WS error: $err');
          _cleanupChannel();
          _scheduleReconnect();
        },
      );

      // subscribe right away
      final subscribeMsg = json.encode({
        'action': 'subscribe',
        'col': subscribedColumn,
      });
      _channel!.sink.add(subscribeMsg);
      setState(() => status = 'subscribed');
    } catch (e) {
      // connection failed — schedule reconnect
      _cleanupChannel();
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    // avoid multiple timers
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _reconnectTimer = null;
      _connectWs();
    });
    setState(() => status = 'reconnecting');
  }

  void _cleanupChannel() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    setState(() => status = 'disconnected');
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    super.dispose();
  }

  // (HTTP polling removed — WebSocket pushes updates)

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgGradientTop, bgGradientBottom],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // ===== Top App Bar =====
              const _TopHeader(blueMain: blueMain),

              const SizedBox(height: 16),

              // ===== Main White Panel with 2 cards inside =====
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: panelBorder, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 780;

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SensorCard(
                              headingText: headingText,
                              labelText: labelText,
                              valueText: valueText,
                              captionText: captionText,
                              cardBorder: cardBorder,
                              workstationName: workstationName,
                              probeId: probeId,
                              calibrationDate: calibrationDate,
                              calibrationDue: calibrationDue,
                              updatedAt: updatedAt,
                            ),
                            const SizedBox(height: 24),
                            _DewPointCard(
                              dewBg: dewBg,
                              dewBorder: dewBorder,
                              dewLabelText: dewLabelText,
                              dewBigNumber: dewBigNumber,
                              liveGreen: liveGreen,
                              dewPointDisplay: dewPointDisplay,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 4,
                            child: _SensorCard(
                              headingText: headingText,
                              labelText: labelText,
                              valueText: valueText,
                              captionText: captionText,
                              cardBorder: cardBorder,
                              workstationName: workstationName,
                              probeId: probeId,
                              calibrationDate: calibrationDate,
                              calibrationDue: calibrationDue,
                              updatedAt: updatedAt,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Flexible(
                            flex: 4,
                            child: _DewPointCard(
                              dewBg: dewBg,
                              dewBorder: dewBorder,
                              dewLabelText: dewLabelText,
                              dewBigNumber: dewBigNumber,
                              liveGreen: liveGreen,
                              dewPointDisplay: dewPointDisplay,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== Bottom blue strip =====
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: blueMain,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------- Reused widgets (unchanged) ----------------------

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.blueMain});

  final Color blueMain;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: blueMain,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F1B2B65),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'RES',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Renewable Energy Systems Limited',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.headingText,
    required this.labelText,
    required this.valueText,
    required this.captionText,
    required this.cardBorder,
    required this.workstationName,
    required this.probeId,
    required this.calibrationDate,
    required this.calibrationDue,
    required this.updatedAt,
  });

  final Color headingText;
  final Color labelText;
  final Color valueText;
  final Color captionText;
  final Color cardBorder;

  final String workstationName;
  final String probeId;
  final String calibrationDate;
  final String calibrationDue;
  final String updatedAt;

  TextStyle get _headingStyle =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: headingText);

  TextStyle get _labelStyle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: labelText,
  );

  TextStyle get _valueStyle => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.3,
    color: valueText,
  );

  TextStyle get _captionStyle =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: captionText);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 320,
        maxWidth: 480,
        minHeight: 200,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(31, 27, 43, 101),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sensor Information', style: _headingStyle),
          const SizedBox(height: 24),
          _twoColRow('Workstation name:', workstationName),
          const SizedBox(height: 16),
          _twoColRow('Probe ID:', probeId),
          const SizedBox(height: 16),
          _twoColRow('Calibration Date:', calibrationDate),
          const SizedBox(height: 16),
          _twoColRow('Calibration Due:', calibrationDue),
          const SizedBox(height: 24),
          const Spacer(),
          Text('Updated: $updatedAt', style: _captionStyle),
        ],
      ),
    );
  }

  Widget _twoColRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(label, style: _labelStyle)),
        const SizedBox(width: 12),
        Expanded(flex: 3, child: Text(value, style: _valueStyle)),
      ],
    );
  }
}

class _DewPointCard extends StatelessWidget {
  const _DewPointCard({
    required this.dewBg,
    required this.dewBorder,
    required this.dewLabelText,
    required this.dewBigNumber,
    required this.liveGreen,
    required this.dewPointDisplay,
  });

  final Color dewBg;
  final Color dewBorder;
  final Color dewLabelText;
  final Color dewBigNumber;
  final Color liveGreen;

  final String dewPointDisplay;

  TextStyle get _headingStyle =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: dewLabelText);

  TextStyle get _bigNumberStyle => TextStyle(
    fontSize: 108,
    fontWeight: FontWeight.w900,
    height: 1.0,
    color: dewBigNumber,
    letterSpacing: -2,
  );

  TextStyle get _liveStyle =>
      TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: liveGreen);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 300,
        maxWidth: 480,
        minHeight: 200,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dewBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dewBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(41, 27, 43, 101),
            offset: Offset(0, 8),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A8DFF).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.opacity_rounded,
                  size: 20,
                  color: Color(0xFF5A8DFF),
                ),
              ),
              const SizedBox(width: 12),
              Text('Dew Point', style: _headingStyle),
            ],
          ),

          const Spacer(),

          // giant number
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dewPointDisplay,
              style: _bigNumberStyle,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // live status row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 6,
                backgroundColor: Color(0xFF1F9D55), // green dot
              ),
              const SizedBox(width: 8),
              Text('Live', style: _liveStyle),
            ],
          ),
        ],
      ),
    );
  }
}
