import '../models/idoso.dart';
import 'api_client.dart';
import 'servico_autenticacao.dart';

class ApiIdoso {
  static Future<void> _prepararToken() async {
    final token = await ServicoAutenticacao.getToken();

    if (token != null && token.isNotEmpty) {
      ApiClient.setToken(token);
    }
  }

  static Future<Map<String, dynamic>> create(Idoso idoso) async {
    try {
      await _prepararToken();

      final response = await ApiClient.post(
        '/api/idoso/cadastro',
        idoso.toJson(),
      );

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Idoso cadastrado com sucesso',
          'idosoId': response['idosoId'] ?? response['data']?['IdIdoso'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Erro ao criar perfil do idoso',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  static Future<List<Idoso>> listMeus() async {
    try {
      await _prepararToken();

      final response = await ApiClient.get('/api/idoso/meus');

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Idoso.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Idoso?> getById(int id) async {
    try {
      await _prepararToken();

      final response = await ApiClient.get('/api/idoso/$id');

      if (response['success'] == true && response['data'] != null) {
        return Idoso.fromJson(response['data']);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> update(int id, Idoso idoso) async {
    try {
      await _prepararToken();

      final idosoData = idoso.toJson();

      idosoData.remove('IdIdoso');
      idosoData.remove('FotoUrl');

      final response = await ApiClient.put('/api/idoso/$id', idosoData);

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Idoso atualizado com sucesso',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Erro ao atualizar perfil do idoso',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    try {
      await _prepararToken();

      final response = await ApiClient.delete('/api/idoso/$id');

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Idoso excluído com sucesso',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Erro ao excluir perfil do idoso',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
}