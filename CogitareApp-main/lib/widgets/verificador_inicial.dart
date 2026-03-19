import 'package:flutter/material.dart';
import '../services/servico_autenticacao.dart';
import '../screens/onboarding.dart';
import '../screens/dashboard_cuidador.dart';
import '../screens/tela_dashboard_responsavel.dart';

class VerificadorInicial extends StatelessWidget {
  const VerificadorInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determinarTelaInicial(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return snapshot.data ?? const OnboardingScreen();
      },
    );
  }

  Future<Widget> _determinarTelaInicial() async {
    try {
      final isLoggedIn = await ServicoAutenticacao.isLoggedIn();

      if (isLoggedIn) {
        final userType = await ServicoAutenticacao.getUserType();

        if (userType == 'cuidador') {
          return const DashboardCuidador();
        } else if (userType == 'responsavel') {
          return const TelaDashboardResponsavel();
        }
      }

      return const OnboardingScreen();
    } catch (e) {
      debugPrint('Erro ao verificar estado inicial: $e');
      return const OnboardingScreen();
    }
  }
}