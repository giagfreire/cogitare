import 'api_client.dart';

/// Serviço de API para autenticação
class ApiAuth {
  /// Realiza login
  static Future<Map<String, dynamic>> login(
    String email,
    String senha,
    String tipo,
  ) async {
    final response = await ApiClient.post('/api/auth/login', {
      'email': email,
      'senha': senha,
      'tipo': tipo,
    });

    if (response['success'] && response['data']['token'] != null) {
      ApiClient.setToken(response['data']['token']);
    }

    return response;
  }

  /// Verifica se o token é válido
  static Future<bool> verifyToken() async {
    try {
      final response = await ApiClient.get('/api/auth/verify');
      return response['success'] ?? false;
    } catch (e) {
      ApiClient.clearToken();
      return false;
    }
  }
}

