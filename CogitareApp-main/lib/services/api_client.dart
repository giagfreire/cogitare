import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cliente base para requisições HTTP
class ApiClient {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    return 'http://10.0.2.2:3000';
  }

  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

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

      final responseData = _decodeBody(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData is Map<String, dynamic>) {
          return responseData;
        }
        return {'success': true, 'data': responseData};
      }

      throw Exception(
        responseData is Map<String, dynamic>
            ? (responseData['message'] ?? 'Erro na requisição POST')
            : 'Erro na requisição POST',
      );
    } catch (e) {
      throw Exception('Erro de conexão POST: $e');
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final responseData = _decodeBody(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData is Map<String, dynamic>) {
          return responseData;
        }
        return {'success': true, 'data': responseData};
      }

      throw Exception(
        responseData is Map<String, dynamic>
            ? (responseData['message'] ?? 'Erro na requisição GET')
            : 'Erro na requisição GET',
      );
    } catch (e) {
      throw Exception('Erro de conexão GET: $e');
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

      final responseData = _decodeBody(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData is Map<String, dynamic>) {
          return responseData;
        }
        return {'success': true, 'data': responseData};
      }

      throw Exception(
        responseData is Map<String, dynamic>
            ? (responseData['message'] ?? 'Erro na requisição PUT')
            : 'Erro na requisição PUT',
      );
    } catch (e) {
      throw Exception('Erro de conexão PUT: $e');
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final responseData = _decodeBody(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData is Map<String, dynamic>) {
          return responseData;
        }
        return {'success': true, 'data': responseData};
      }

      throw Exception(
        responseData is Map<String, dynamic>
            ? (responseData['message'] ?? 'Erro na requisição DELETE')
            : 'Erro na requisição DELETE',
      );
    } catch (e) {
      throw Exception('Erro de conexão DELETE: $e');
    }
  }
}