import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static Future<void> saveLogin({
    required String token,
    required int cuidadorId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setInt('cuidadorId', cuidadorId);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<int?> getCuidadorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('cuidadorId');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('cuidadorId');
  }
}