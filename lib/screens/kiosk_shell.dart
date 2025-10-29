// kiosk_shell.dart
import 'package:flutter/material.dart';
import 'web_logs_screen.dart';
import 'home_screen.dart';
import 'wi_list_screen.dart';

class KioskShell extends StatefulWidget {
  const KioskShell({super.key});

  @override
  State<KioskShell> createState() => _KioskShellState();
}

class _KioskShellState extends State<KioskShell> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 1); // center = HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const PageScrollPhysics(),
      children: const [
        WebLogsScreen(), // swipe LEFT
        HomeScreen(), // center
        WIListScreen(), // swipe RIGHT
      ],
    );
  }
}
