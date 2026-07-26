import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/hardware_bind_page.dart';
import 'screens/dashboard_page.dart';
import 'services/secure_storage_service.dart';

Future<void> main() async {
  // Ensure Flutter engine bindings are fully initialized before running async tasks
  WidgetsFlutterBinding.ensureInitialized();

  String? savedToken;

  try {
    // Check if user session token exists in secure storage
    savedToken = await SecureStorageService.getUserToken();
  } catch (e) {
    debugPrint('Error reading token: $e');
  }

  // Pass login status to MyApp to dynamically decide the initial screen
  runApp(MyApp(isLoggedIn: savedToken != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laser Communication Hub',
      debugShowCheckedModeBanner: false,

      // Cyberpunk/Terminal Dark Theme Matrix
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111111),
          elevation: 0,
          centerTitle: true,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.cyanAccent,
          surface: Color(0xFF1E1E1E),
        ),
      ),

      // If a valid session token exists, jump directly into hardware link setup; otherwise, show login
      initialRoute: '/login',

      // Declarative Explicit Navigation Route Mapping
      routes: {
        '/login': (context) => const LoginPage(),
        '/hardware': (context) => const HardwareBindPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
