import 'api_client.dart';
import 'api_auth.dart';

/// Serviço de API unificado
/// Mantém compatibilidade com código existente que usa ServicoApi
class ServicoApi {
  /// Realiza login
  static Future<Map<String, dynamic>> login(
    String email,
    String senha,
    String tipo,
  ) async {
    return await ApiAuth.login(email, senha, tipo);
  }

  /// Verifica se o token é válido
  static Future<bool> verifyToken() async {
    return await ApiAuth.verifyToken();
  }

  /// Configura o token
  static void setToken(String token) {
    ApiClient.setToken(token);
  }

  /// Remove o token
  static void clearToken() {
    ApiClient.clearToken();
  }

  /// Requisição POST
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await ApiClient.post(endpoint, data);
  }

  /// Requisição GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    return await ApiClient.get(endpoint);
  }

  /// Requisição PUT
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await ApiClient.put(endpoint, data);
  }

  /// Requisição DELETE
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return await ApiClient.delete(endpoint);
  }
}
