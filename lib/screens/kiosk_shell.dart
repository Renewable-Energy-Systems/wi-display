import 'package:flutter/material.dart';
import 'web_logs_screen.dart';
import 'home_screen.dart';
import 'wi_list_screen.dart';
import 'gauge_screen.dart';

class KioskShell extends StatefulWidget {
  const KioskShell({super.key});

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
    _pages = const [
      WebLogsScreen(), // index 0 (left)
      HomeScreen(), // index 1 (center)
      WIListScreen(), // index 2 (right)
      GaugeScreen(), // index 3
    ];
  }

  void _goTo(int index) {
    if (index < 0 || index > 3) return;
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
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _NavButton(
                alignment: Alignment.centerLeft,
                icon: Icons.chevron_left_rounded,
                onTap: () => _goTo(_pageIndex - 1),
              ),
            ),

          // RIGHT arrow
          if (_pageIndex < 3)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _NavButton(
                alignment: Alignment.centerRight,
                icon: Icons.chevron_right_rounded,
                onTap: () => _goTo(_pageIndex + 1),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final Alignment alignment;
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({
    super.key,
    required this.alignment,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 80,
        alignment: alignment,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: alignment == Alignment.centerLeft
                ? Alignment.centerLeft
                : Alignment.centerRight,
            end: alignment == Alignment.centerLeft
                ? Alignment.centerRight
                : Alignment.centerLeft,
            colors: [Colors.black.withOpacity(0.08), Colors.transparent],
          ),
        ),
        child: Icon(icon, size: 48, color: Colors.black.withOpacity(0.4)),
      ),
    );
  }
}
