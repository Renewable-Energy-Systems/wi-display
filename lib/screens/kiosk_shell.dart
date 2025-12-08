// lib/screens/kiosk_shell.dart
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// use prefixes to avoid name collisions and make it explicit
import 'web_logs_screen.dart' show WebLogsScreen;
import 'home_screen.dart' as home;
import 'wi_list_screen.dart' show WIListScreen;
import 'gauge_screen.dart' as gauge;
import 'det_selector_screen.dart' show DetSelectorScreen;

class KioskShell extends StatefulWidget {
  final WebSocketChannel? channel;
  final String apiHost;

  const KioskShell({
    super.key,
    required this.apiHost,
    this.channel,
  });

  @override
  State<KioskShell> createState() => _KioskShellState();
}


class _KioskShellState extends State<KioskShell> {
  late final PageController _controller;
  late final List<Widget> _pages; // cache pages
  int _pageIndex = 1; // start in the middle (Home)

  @override
  void initState() {
    super.initState();

    _controller = PageController(initialPage: _pageIndex);

    // IMPORTANT: create these widgets ONCE
    // no const because widget constructors are not const
    _pages = [
      WebLogsScreen(), // index 0 (left)
      home.HomeScreen(), // index 1 (center) — note the prefix
      WIListScreen(), // index 2 (right)
      gauge.GaugeScreen(), // index 3 — note the prefix
      DetSelectorScreen(         // index 4
        apiHost: widget.apiHost,
        channel: widget.channel,
      ),
    ];
  }

  void _goTo(int index) {
    if (index < 0 || index > _pages.length - 1) return;
    setState(() {
      _pageIndex = index;
    });
    _controller.animateToPage(
      _pageIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            physics:
                const NeverScrollableScrollPhysics(), // no swipe, use arrows
            children: _pages,
          ),

          // LEFT arrow
          if (_pageIndex > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _NavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _goTo(_pageIndex - 1),
                ),
              ),
            ),

          // RIGHT arrow
          if (_pageIndex < _pages.length - 1)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _NavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _goTo(_pageIndex + 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, size: 36, color: Colors.blueGrey[800]),
        ),
      ),
    );
  }
}
