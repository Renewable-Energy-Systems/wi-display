import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebLogsScreen extends StatefulWidget {
  const WebLogsScreen({super.key});

  @override
  State<WebLogsScreen> createState() => _WebLogsScreenState();
}

class _WebLogsScreenState extends State<WebLogsScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..loadRequest(Uri.parse('https://logi.weberq.in'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // no app bar, no URL bar
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
