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
    } catch (e) {
      return response.body;
    }
  }

  // =========================
  // GET
  // =========================
  static Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final response = await http.get(uri, headers: _headers);

    return _decodeBody(response);
  }

  // =========================
  // POST
  // =========================
  static Future<dynamic> post(String endpoint, dynamic body) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    return _decodeBody(response);
  }

  // =========================
  // PUT
  // =========================
  static Future<dynamic> put(String endpoint, dynamic body) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    return _decodeBody(response);
  }

  // =========================
  // DELETE 
  // =========================
  static Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final response = await http.delete(
      uri,
      headers: _headers,
    );

    return _decodeBody(response);
  }
}