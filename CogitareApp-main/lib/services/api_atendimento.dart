import 'api_client.dart';

/// Serviço de API para Atendimentos
class ApiAtendimento {
  /// Busca estatísticas do cuidador
  static Future<Map<String, dynamic>> getEstatisticasCuidador(
    int cuidadorId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/api/atendimentos/cuidador/$cuidadorId/estatisticas',
      );

      if (response['success'] == true) {
        return {
          'success': true,
          'data': {
            'propostasPendentes': response['data']['propostasPendentes'] ?? 0,
            'servicosAtivos': response['data']['servicosAtivos'] ?? 0,
            'concluidos': response['data']['concluidos'] ?? 0,
          },
        };
      } else {
        return {
          'success': false,
          'data': {
            'propostasPendentes': 0,
            'servicosAtivos': 0,
            'concluidos': 0,
          },
        };
      }
    } catch (e) {
      print('Erro ao buscar estatísticas do cuidador: $e');
      return {
        'success': false,
        'data': {
          'propostasPendentes': 0,
          'servicosAtivos': 0,
          'concluidos': 0,
        },
      };
    }
  }

  /// Lista atendimentos do cuidador
  static Future<List<Map<String, dynamic>>> listarPorCuidador(
    int cuidadorId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/api/atendimentos/cuidador/$cuidadorId',
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => json as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Erro ao listar atendimentos do cuidador: $e');
      return [];
    }
  }

  /// Busca próximo atendimento do cuidador
  static Future<Map<String, dynamic>?> getProximoAtendimento(
    int cuidadorId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/api/atendimentos/cuidador/$cuidadorId/proximo',
      );

      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Erro ao buscar próximo atendimento: $e');
      return null;
    }
  }
}

