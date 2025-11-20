import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../socket_service.dart';

class WebLogsScreen extends StatefulWidget {
  const WebLogsScreen({super.key});

  @override
  State<WebLogsScreen> createState() => _WebLogsScreenState();
}

class _WebLogsScreenState extends State<WebLogsScreen>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool _isLoading = true;

  // Store the latest value and subscription
  String _latestGaugeValue = "";
  StreamSubscription? _gaugeSub;

  // Movable FAB Position (Offsets from bottom-right)
  double _fabBottom = 24.0;
  double _fabRight = 24.0;

  @override
  void initState() {
    super.initState();

    // 1. Subscribe to the Gauge Stream
    _gaugeSub = SocketService().gaugeStream.listen((data) {
      if (data.containsKey('value')) {
        setState(() {
          _latestGaugeValue = data['value'].toString();
        });
      }
    });

    // Ensure we are connected
    SocketService().connect("http://192.168.0.53:5050");

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://logi.weberq.in'));
  }

  @override
  void dispose() {
    _gaugeSub?.cancel();
    super.dispose();
  }

  Future<void> _pasteValueToWeb() async {
    if (_latestGaugeValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No gauge value received yet")),
      );
      return;
    }

    // JavaScript to inject the value into the active element
    final jsScript =
        '''
      (function() {
        var input = document.activeElement;
        if (input && (input.tagName === 'INPUT' || input.tagName === 'TEXTAREA')) {
          var nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
          if (nativeInputValueSetter) {
             nativeInputValueSetter.call(input, '$_latestGaugeValue');
          } else {
             input.value = '$_latestGaugeValue';
          }
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
        }
      })();
    ''';

    await _controller.runJavaScript(jsScript);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pasted: $_latestGaugeValue"),
          duration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        SafeArea(child: WebViewWidget(controller: _controller)),

        if (_isLoading)
          Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),

        // Movable Floating Paste Button
        Positioned(
          bottom: _fabBottom,
          right: _fabRight,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                // Subtract delta because we are positioning from Bottom/Right
                // Dragging down (+dy) decreases the 'bottom' offset
                _fabBottom -= details.delta.dy;
                _fabRight -= details.delta.dx;
              });
            },
            child: FloatingActionButton.extended(
              onPressed: _pasteValueToWeb,
              icon: const Icon(Icons.paste),
              label: Text(
                _latestGaugeValue.isEmpty
                    ? "Wait..."
                    : "Paste $_latestGaugeValue",
              ),
              backgroundColor: const Color(0xFF0A66FF),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
