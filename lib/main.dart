import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const EysfluisApp());
}

class EysfluisApp extends StatelessWidget {
  const EysfluisApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1E3A8A); // Azul Institucional
    const secondaryTeal = Color(0xFF0D9488); // Teal
    const accentAmber = Color(0xFFF59E0B); // Ámbar

    return MaterialApp(
      title: 'EYSFLUIS - Sistema de Gestión de Personas',,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: secondaryTeal,
          tertiary: accentAmber,
          surface: Colors.grey.shade50,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: secondaryTeal.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Alias para compatibilidad
typedef Gym360App = EysfluisApp;
