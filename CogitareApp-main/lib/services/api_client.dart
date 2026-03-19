import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente base para requisições HTTP
class ApiClient {
  // Para Flutter Web / Chrome no mesmo PC
  static const String baseUrl = 'http://127.0.0.1:3000';

  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

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

      final Map<String, dynamic> responseData =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ??
              responseData['error'] ??
              'Erro na requisição: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Erro ao processar resposta do servidor');
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final Map<String, dynamic> responseData =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ??
              responseData['error'] ??
              'Erro na requisição: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Erro ao processar resposta do servidor');
      }
      throw Exception('Erro de conexão: $e');
    }
  }

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

      final Map<String, dynamic> responseData =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ??
              responseData['error'] ??
              'Erro na requisição: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Erro ao processar resposta do servidor');
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final Map<String, dynamic> responseData =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 204) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ??
              responseData['error'] ??
              'Erro na requisição: ${response.statusCode}',
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