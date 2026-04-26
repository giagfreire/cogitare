import 'package:flutter/material.dart';

import 'screens/onboarding.dart';
import 'screens/tela_cadastro_responsavel.dart';
import 'screens/tela_cadastro_idoso.dart';
import 'screens/tela_sucesso.dart';
import 'screens/criar_vaga_page.dart';
import 'screens/tela_login_unificada.dart';
import 'screens/dashboard_cuidador.dart';
import 'screens/tela_dashboard_responsavel.dart';
import 'screens/perfil_cuidador_page.dart';
import 'screens/tela_configuracoes.dart';
import 'screens/tela_editar_perfil_cuidador.dart';
import 'screens/tela_termos_condicoes.dart';
import 'screens/tela_cadastro_cuidador.dart';

void main() {
  runApp(const CogitareApp());
}

class CogitareApp extends StatelessWidget {
  const CogitareApp({super.key});

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF7F8FC);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cogitare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: roxo,
        scaffoldBackgroundColor: fundo,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: roxo,
          onPrimary: Colors.white,
          secondary: rosa,
          onSecondary: Colors.white,
          tertiary: verde,
          onTertiary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: roxo,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: roxo,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: rosa,
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
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: roxo),
          hintStyle: TextStyle(color: Colors.grey.shade500),
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
              color: rosa,
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
          backgroundColor: roxo,
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: rosa,
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

        TelaCadastroCuidador.route: (context) => const TelaCadastroCuidador(),

        PerfilCuidadorPage.route: (context) => const PerfilCuidadorPage(),
        '/configuracoes': (context) => const TelaConfiguracoes(),
        TelaEditarPerfilCuidador.route: (context) =>
            const TelaEditarPerfilCuidador(),
        TelaTermosCondicoes.route: (context) => const TelaTermosCondicoes(),

        '/criar-vaga': (context) => const CriarVagaPage(),
      },
    );
  }
}