import 'package:flutter/material.dart';
import '../screens/onboarding.dart';
import '../screens/tela_login_unificada.dart';
import '../services/servico_autenticacao.dart';

/// Utilitários para navegação do app
class NavigationUtils {
  /// Navega para o onboarding pulando até a última página
  static void navigateToOnboardingLastPage(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const OnboardingScreen(skipToLastPage: true),
      ),
      (route) => false,
    );
  }

  /// Navega para seleção de papel após limpar processo de cadastro
  static Future<void> navigateToRoleSelection(BuildContext context) async {
    await ServicoAutenticacao.clearSignupProcess();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const OnboardingScreen(),
      ),
    );
  }

  /// Navega para login
  static void navigateToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, TelaLoginUnificada.route);
  }
}

