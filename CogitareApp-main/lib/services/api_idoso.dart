import '../models/idoso.dart';
import 'api_client.dart';

/// Serviço de API para Idosos
class ApiIdoso {
  /// Cria idoso
  static Future<Map<String, dynamic>> create(Idoso idoso) async {
    try {
      final response = await ApiClient.post('/api/idoso', idoso.toJson());

      if (response['success']) {
        return {
          'success': true,
          'message': response['message'],
          'idosoId': response['data']['IdIdoso'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao criar idoso',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Lista todos os idosos
  static Future<List<Idoso>> list() async {
    try {
      final response = await ApiClient.get('/api/idoso');

      if (response['success']) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Idoso.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Erro ao listar idosos');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Lista idosos por responsável
  static Future<List<Idoso>> listByGuardian(int guardianId) async {
    try {
      // Por enquanto, retorna todos os idosos
      // Futuramente pode ser implementado um endpoint específico
      return await list();
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Busca idoso por ID
  static Future<Idoso?> getById(int id) async {
    try {
      final response = await ApiClient.get('/api/idoso/$id');

      if (response['success']) {
        return Idoso.fromJson(response['data']);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Atualiza idoso
  static Future<Map<String, dynamic>> update(int id, Idoso idoso) async {
    try {
      final idosoData = idoso.toJson();
      idosoData.remove('IdIdoso'); // Remove ID do objeto antes de enviar

      final response = await ApiClient.put('/api/idoso/$id', idosoData);

      if (response['success']) {
        return {
          'success': true,
          'message': response['message'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao atualizar idoso',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
}

