import 'api_client.dart';

class ApiPagamento {
  static Future<Map<String, dynamic>> criarPreferencia({
    required int idCuidador,
    required int idPlano,
    required String titulo,
    required double preco,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/mercadopago/criar-preferencia',
        {
          'idCuidador': idCuidador,
          'idPlano': idPlano,
          'titulo': titulo,
          'preco': preco,
        },
      );

      if (response is Map<String, dynamic>) {
        return response;
      }

      return {
        'success': false,
        'message': 'Resposta inválida do servidor.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao criar preferência de pagamento: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> buscarStatusPagamento({
    required int idCuidador,
  }) async {
    try {
      final response = await ApiClient.get(
        '/api/mercadopago/status-pagamento/$idCuidador',
      );

      if (response is Map<String, dynamic>) {
        return response;
      }

      return {
        'success': false,
        'message': 'Resposta inválida do servidor.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar status do pagamento: $e',
      };
    }
  }
}