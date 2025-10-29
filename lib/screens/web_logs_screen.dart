import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebLogsScreen extends StatefulWidget {
  const WebLogsScreen({super.key});

  @override
  State<WebLogsScreen> createState() => _WebLogsScreenState();
}

class _WebLogsScreenState extends State<WebLogsScreen>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // once first page finishes loading, hide spinner
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
  Widget build(BuildContext context) {
    super.build(context); // IMPORTANT for AutomaticKeepAliveClientMixin

    return Stack(
      children: [
        // the actual webview
        SafeArea(child: WebViewWidget(controller: _controller)),

        // small loading overlay for first load
        if (_isLoading)
          Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }

  // tell Flutter we want to keep this state alive even when off-screen
  @override
  bool get wantKeepAlive => true;
}
