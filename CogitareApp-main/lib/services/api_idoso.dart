import '../models/idoso.dart';
import 'api_client.dart';

class ApiIdoso {
  static Future<Map<String, dynamic>> create(Idoso idoso) async {
    try {
      final response = await ApiClient.post('/api/idoso', idoso.toJson());

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'],
          'idosoId': response['data']?['IdIdoso'],
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
      final response = await ApiClient.get('/api/idoso/meus');

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Idoso.fromJson(json)).toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Idoso?> getById(int id) async {
    try {
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
      final idosoData = idoso.toJson();
      idosoData.remove('IdIdoso');
      idosoData.remove('FotoUrl');

      final response = await ApiClient.put('/api/idoso/$id', idosoData);

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'],
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
}