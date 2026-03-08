import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import '../screens/tela_dashboard_cuidador.dart';
import '../screens/tela_dashboard_responsavel.dart';

/// Controller responsável pela lógica de negócio do Login
class LoginController {
  /// Valida os campos do formulário de login
  static String? validateFields({
    required String email,
    required String senha,
    required String? userType,
  }) {
    if (email.isEmpty) {
      return 'Por favor, preencha o e-mail';
    }
    if (senha.isEmpty) {
      return 'Por favor, preencha a senha';
    }
    if (userType == null) {
      return 'Por favor, selecione o tipo de usuário';
    }
    return null;
  }

  /// Executa o processo de login
  static Future<Map<String, dynamic>> performLogin({
    required String email,
    required String senha,
    required String userType,
  }) async {
    try {
      final result = await ServicoApi.login(email, senha, userType);

      if (result['success']) {
        // Salvar dados de login
        await ServicoAutenticacao.saveLoginData(
          userType: result['data']['user']['tipo'],
          userData: result['data']['user'],
          token: result['data']['token'],
        );

        // Limpar flag de processo de cadastro ao fazer login
        await ServicoAutenticacao.clearSignupProcess();

        return {
          'success': true,
          'userType': result['data']['user']['tipo'],
          'userName': result['data']['user']['nome'],
          'message': 'Login realizado com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Erro no login',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Navega para o dashboard apropriado baseado no tipo de usuário
  static void navigateToDashboard(BuildContext context, String userType) {
    if (userType == 'cuidador') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const TelaDashboardCuidador()),
        (route) => false,
      );
    } else if (userType == 'responsavel') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const TelaDashboardResponsavel()),
        (route) => false,
      );
    }
  }
}
