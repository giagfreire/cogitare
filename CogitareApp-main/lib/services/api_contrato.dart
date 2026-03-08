import '../models/contrato.dart';
import 'api_client.dart';

/// Serviço de API para Contratos
class ApiContrato {
  /// Busca contrato ativo do responsável
  static Future<Contrato?> getActive(int responsavelId) async {
    try {
      final response = await ApiClient.get(
        '/api/contracts/active?responsavel_id=$responsavelId',
      );

      if (response['success'] == true && response['data'] != null) {
        return Contrato.fromJson(response['data']);
      }

      return null; // Nenhum contrato ativo
    } catch (e) {
      print('Erro ao buscar contrato ativo: $e');
      return null;
    }
  }

  /// Busca histórico de contratos
  static Future<List<Contrato>> getHistory(int responsavelId) async {
    try {
      final response = await ApiClient.get(
        '/api/contracts/history?responsavel_id=$responsavelId',
      );

      if (response['success'] == true) {
        final List<dynamic> contractsData = response['data'];
        return contractsData.map((json) => Contrato.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Erro ao buscar histórico de contratos: $e');
      return [];
    }
  }

  /// Cria novo contrato
  static Future<Contrato?> create({
    required int responsavelId,
    required int cuidadorId,
    required int idosoId,
    required DateTime dataInicio,
    required DateTime dataFim,
    required double valor,
    required String local,
    String? observacoes,
  }) async {
    try {
      final response = await ApiClient.post('/api/contracts', {
        'responsavel_id': responsavelId,
        'cuidador_id': cuidadorId,
        'idoso_id': idosoId,
        'data_inicio': dataInicio.toIso8601String(),
        'data_fim': dataFim.toIso8601String(),
        'valor': valor,
        'local': local,
        'observacoes': observacoes,
      });

      if (response['success'] == true) {
        return Contrato.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      print('Erro ao criar contrato: $e');
      return null;
    }
  }

  /// Cancela contrato
  static Future<bool> cancel(int contractId) async {
    try {
      final response = await ApiClient.put('/api/contracts/$contractId/cancel', {});
      return response['success'] ?? false;
    } catch (e) {
      print('Erro ao cancelar contrato: $e');
      return false;
    }
  }
}

