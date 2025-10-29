import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/kiosk_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation (optional but usually desired for kiosk tablets)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system overlays? (Nav bar / status bar)
  // You *can* uncomment this for hardcore kiosk, but test first.
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const RESKioskApp());
}

class RESKioskApp extends StatelessWidget {
  const RESKioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF304FFE), // deep-ish blue accent for UI
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.black,
        ),
      ),
    );

    return MaterialApp(
      title: 'RES Production Kiosk',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const KioskShell(),
    );
  }
}
