import 'package:flutter/material.dart';

import 'screens/onboarding.dart';
import 'screens/tela_cadastro_responsavel.dart';
import 'screens/tela_cadastro_idoso.dart';
import 'screens/tela_sucesso.dart';
import 'screens/criar_vaga_page.dart';
import 'screens/tela_login_unificada.dart';
import 'screens/dashboard_cuidador.dart';
import 'screens/tela_dashboard_responsavel.dart';

void main() {
  runApp(const CogitareApp());
}

class CogitareApp extends StatelessWidget {
  const CogitareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cogitare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF42124C),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF42124C),
          onPrimary: Colors.white,
          secondary: Color(0xFFFE0472),
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF42124C),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF42124C),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFE0472),
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 52),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
),        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: Color(0xFF42124C),
          ),
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFFE0472),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF42124C),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFFFE0472),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/login': (context) => const TelaLoginUnificada(),
        TelaLoginUnificada.route: (context) => const TelaLoginUnificada(),
        DashboardCuidador.route: (context) => const DashboardCuidador(),
        TelaDashboardResponsavel.route: (context) =>
            const TelaDashboardResponsavel(),
        TelaCadastroResponsavel.route: (context) =>
            const TelaCadastroResponsavel(),
        TelaCadastroIdoso.route: (context) => const TelaCadastroIdoso(),
        TelaSucesso.route: (context) => const TelaSucesso(),
        '/criar-vaga': (context) => const CriarVagaPage(),
        DashboardCuidador.route: (context) => const DashboardCuidador(),
      },
    );
  }
}