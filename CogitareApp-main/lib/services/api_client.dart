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
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
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

  static Map<String, dynamic> _normalizeSuccessResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {
      'success': true,
      'data': data,
    };
  }

  static Exception _buildException(
    String metodo,
    http.Response response,
    dynamic responseData,
  ) {
    String message = 'Erro na requisição $metodo';

    if (responseData is Map && responseData['message'] != null) {
      message = responseData['message'].toString();
    } else if (responseData is String && responseData.trim().isNotEmpty) {
      message = responseData;
    } else {
      message = '$message (${response.statusCode})';
    }

    return Exception(message);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final responseData = _decodeBody(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _normalizeSuccessResponse(responseData);
      } else {
        throw _buildException('GET', response, responseData);
      }
    } catch (e) {
      throw Exception('Erro de conexão GET: $e');
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
        return _normalizeSuccessResponse(responseData);
      } else {
        throw _buildException('POST', response, responseData);
      }
    } catch (e) {
      throw Exception('Erro de conexão POST: $e');
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
        return _normalizeSuccessResponse(responseData);
      } else {
        throw _buildException('PUT', response, responseData);
      }
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
        return _normalizeSuccessResponse(responseData);
      } else {
        throw _buildException('DELETE', response, responseData);
      }
    } catch (e) {
      throw Exception('Erro de conexão DELETE: $e');
    }
  }
}