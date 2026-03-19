import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'session_service.dart';

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

    debugPrint('RESPOSTA LOGIN: $response');

    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      final user = data['user'];

      final token = data['token'];

      final dynamic cuidadorId =
          data['idCuidador'] ??
          data['IdCuidador'] ??
          data['cuidadorId'] ??
          data['id'] ??
          data['Id'] ??
          user?['idCuidador'] ??
          user?['IdCuidador'] ??
          user?['cuidadorId'] ??
          user?['id'] ??
          user?['Id'];

      debugPrint('TOKEN LOGIN: $token');
      debugPrint('CUIDADOR ID ENCONTRADO: $cuidadorId');

      if (token != null) {
        ApiClient.setToken(token);
      }

      if (tipo == 'cuidador' && token != null && cuidadorId != null) {
        await SessionService.saveLogin(
          token: token.toString(),
          cuidadorId: int.parse(cuidadorId.toString()),
        );
        debugPrint('CUIDADOR ID SALVO NA SESSÃO');
      }
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