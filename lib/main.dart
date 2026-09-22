import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ManageNotifApp());
}

class ManageNotifApp extends StatelessWidget {
  const ManageNotifApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationProvider(),
      child: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Manage Notif',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1), // Indigo 500
                primary: const Color(0xFF6366F1),
                onPrimary: Colors.white,
                secondary: const Color(0xFF8B5CF6), // Violet 500
                tertiary: const Color(0xFF06B6D4), // Cyan 500
                surface: const Color(0xFFF8FAFC), // Slate 50
                onSurface: const Color(0xFF0F172A), // Slate 900
                surfaceContainer: Colors.white,
                surfaceContainerHighest: const Color(0xFFF1F5F9),
                outline: const Color(0xFFE2E8F0),
                outlineVariant: const Color(0xFFCBD5E1),
                error: const Color(0xFFEF4444),
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.8),
                ),
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: const Color(0xFFF1F5F9),
                selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF818CF8), // Indigo 400
                primary: const Color(0xFF818CF8),
                onPrimary: const Color(0xFF0F172A),
                secondary: const Color(0xFFA78BFA), // Violet 400
                tertiary: const Color(0xFF22D3EE), // Cyan 400
                surface: const Color(0xFF0F172A), // Slate 900
                onSurface: const Color(0xFFF8FAFC),
                surfaceContainer: const Color(0xFF1E293B), // Slate 800
                surfaceContainerHighest: const Color(0xFF334155), // Slate 700
                outline: const Color(0xFF334155),
                outlineVariant: const Color(0xFF475569),
                error: const Color(0xFFF87171),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF0B0F19), // Deep Midnight
              cardTheme: CardThemeData(
                color: const Color(0xFF151D2C),
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFF243044), width: 1),
                ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF151D2C),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF243044)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF243044)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.8),
                ),
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF818CF8),
                  foregroundColor: const Color(0xFF0F172A),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF818CF8),
                  side: const BorderSide(color: Color(0xFF243044), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: const Color(0xFF1E293B),
                selectedColor: const Color(0xFF818CF8).withValues(alpha: 0.18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF243044)),
                ),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
            themeMode: provider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
