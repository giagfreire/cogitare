import 'api_client.dart';
import 'api_auth.dart';

class ServicoApi {
  static Future<Map<String, dynamic>> login(
    String email,
    String senha,
    String tipo,
  ) async {
    return await ApiAuth.login(email, senha, tipo);
  }

  static Future<bool> verifyToken() async {
    return await ApiAuth.verifyToken();
  }

  static void setToken(String token) {
    ApiClient.setToken(token);
  }

  static void clearToken() {
    ApiClient.clearToken();
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await ApiClient.post(endpoint, data);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    return await ApiClient.get(endpoint);
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await ApiClient.put(endpoint, data);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return await ApiClient.delete(endpoint);
  }
}