import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente base para requisições HTTP
/// Centraliza configurações de autenticação e métodos HTTP
class ApiClient {
  static const String baseUrl = 'http://localhost:3000';
  static String? _token;

  /// Configura o token de autenticação
  static void setToken(String token) {
    _token = token;
  }

  /// Remove o token de autenticação
  static void clearToken() {
    _token = null;
  }

  /// Headers padrão com autenticação
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Requisição POST
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Erro na requisição: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Erro ao processar resposta do servidor');
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Requisição GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Erro na requisição: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Erro ao processar resposta do servidor');
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Requisição PUT
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Erro na requisição: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Erro ao processar resposta do servidor');
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Requisição DELETE
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Erro na requisição: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Erro ao processar resposta do servidor');
      }
      throw Exception('Erro de conexão: $e');
    }
  }
}

