import '../services/servico_autenticacao.dart';
import '../services/api_atendimento.dart';

/// Controller responsável pela lógica de negócio do Dashboard do Cuidador
class DashboardCuidadorController {
  /// Carrega o nome do cuidador logado
  static Future<String> loadUserName() async {
    try {
      final userData = await ServicoAutenticacao.getUserData();

      if (userData != null) {
        final nome = userData['nome'] ??
                     userData['Nome'] ??
                     userData['name'];

        if (nome != null && nome.toString().isNotEmpty) {
          return nome.toString();
        }
      }
      return 'Cuidador'; // Valor padrão
    } catch (e) {
      print('Erro ao carregar nome do cuidador: $e');
      return 'Cuidador';
    }
  }

  /// Obtém o ID do cuidador logado
  static Future<int?> getCuidadorId() async {
    try {
      final userData = await ServicoAutenticacao.getUserData();

      if (userData != null) {
        final id = userData['id'] ??
                   userData['Id'] ??
                   userData['IdCuidador'] ??
                   userData['idCuidador'];

        if (id != null) {
          return int.tryParse(id.toString());
        }
      }
      return null;
    } catch (e) {
      print('Erro ao obter ID do cuidador: $e');
      return null;
    }
  }

  /// Carrega as estatísticas do dashboard
  static Future<Map<String, int>> loadEstatisticas() async {
    try {
      final cuidadorId = await getCuidadorId();

      if (cuidadorId == null) {
        return {
          'propostasPendentes': 0,
          'servicosAtivos': 0,
          'concluidos': 0,
        };
      }

      final response = await ApiAtendimento.getEstatisticasCuidador(cuidadorId);

      if (response['success']) {
        final data = response['data'] as Map<String, dynamic>;
        return {
          'propostasPendentes': data['propostasPendentes'] as int? ?? 0,
          'servicosAtivos': data['servicosAtivos'] as int? ?? 0,
          'concluidos': data['concluidos'] as int? ?? 0,
        };
      } else {
        return {
          'propostasPendentes': 0,
          'servicosAtivos': 0,
          'concluidos': 0,
        };
      }
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
      return {
        'propostasPendentes': 0,
        'servicosAtivos': 0,
        'concluidos': 0,
      };
    }
  }

  /// Carrega o próximo atendimento
  static Future<Map<String, dynamic>?> loadProximoAtendimento() async {
    try {
      final cuidadorId = await getCuidadorId();

      if (cuidadorId == null) {
        return null;
      }

      return await ApiAtendimento.getProximoAtendimento(cuidadorId);
    } catch (e) {
      print('Erro ao carregar próximo atendimento: $e');
      return null;
    }
  }

  /// Executa o processo de logout
  static Future<void> performLogout() async {
    await ServicoAutenticacao.clearLoginData();
  }
}

