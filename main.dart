import 'package:flutter/material.dart';

import 'app/app_repository.dart';
import 'app/screens/admin_dashboard.dart';
import 'app/screens/auth_screen.dart';
import 'app/screens/customer_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await AppRepository.create();
  runApp(PrinterShopApp(repository: repository));
}

class PrinterShopApp extends StatelessWidget {
  const PrinterShopApp({super.key, required this.repository});

  final AppRepository repository;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF0F766E),
      secondary: const Color(0xFFF59E0B),
      surface: const Color(0xFFFFFCF5),
      error: const Color(0xFFB42318),
    );

    return MaterialApp(
      title: 'Mount Print Zone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF3F6F8),
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: const Color(0xFF132238),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD8E1EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD8E1EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.4),
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: repository,
        builder: (context, _) {
          final currentUser = repository.currentUser;
          if (currentUser == null) {
            return AuthScreen(repository: repository);
          }
          return currentUser.role.name == 'admin'
              ? AdminDashboard(repository: repository)
              : CustomerDashboard(repository: repository);
        },
      ),
    );
  }
}