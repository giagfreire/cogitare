import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cuidador.dart';
import '../models/responsavel.dart';

class ServicoAutenticacao {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userTypeKey = 'user_type';
  static const String _userDataKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  // Verificar se o usuário está logado
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      print('🔍 Verificando login: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      print('❌ Erro ao verificar status de login: $e');
      return false;
    }
  }

  // Obter tipo do usuário logador
  static Future<String?> getUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userTypeKey);
    } catch (e) {
      print('Erro ao obter tipo do usuário: $e');
      return null;
    }
  }

  // Obter dados do usuário logado
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        return json.decode(userDataString);
      }
      return null;
    } catch (e) {
      print('Erro ao obter dados do usuário: $e');
      return null;
    }
  }

  // Obter token de autenticação
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Erro ao obter token: $e');
      return null;
    }
  }

  // Salvar dados de login
  static Future<void> saveLoginData({
    required String userType,
    required Map<String, dynamic> userData,
    String? token,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userTypeKey, userType);
      await prefs.setString(_userDataKey, json.encode(userData));

      if (token != null) {
        await prefs.setString(_tokenKey, token);
      }

      print('✅ Dados de login salvos com sucesso');
      print('📱 UserType: $userType');
      print('👤 UserData: $userData');

      // Verificar se realmente foi salvo
      final saved = prefs.getBool(_isLoggedInKey);
      print('🔍 Verificação pós-salvamento: $saved');
    } catch (e) {
      print('❌ Erro ao salvar dados de login: $e');
    }
  }

  // Limpar dados de login (logout)
  static Future<void> clearLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userTypeKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_tokenKey);
      await prefs
          .remove('in_signup_process'); // Limpar flag de processo de cadastro

      print('Dados de login limpos com sucesso');
    } catch (e) {
      print('Erro ao limpar dados de login: $e');
    }
  }

  // Limpar todos os dados (incluindo onboarding) - para debug
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('Todos os dados limpos com sucesso');
    } catch (e) {
      print('Erro ao limpar todos os dados: $e');
    }
  }

  // Obter objeto Cuidador se o usuário for cuidador
  static Future<Cuidador?> getCaregiverUser() async {
    try {
      final userData = await getUserData();
      final userType = await getUserType();

      if (userData != null && userType == 'cuidador') {
        return Cuidador.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Erro ao obter dados do cuidador: $e');
      return null;
    }
  }

  // Obter objeto Responsavel se o usuário for responsável
  static Future<Responsavel?> getGuardianUser() async {
    try {
      final userData = await getUserData();
      final userType = await getUserType();

      if (userData != null && userType == 'responsavel') {
        return Responsavel.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Erro ao obter dados do responsável: $e');
      return null;
    }
  }

  // Verificar se é primeira vez abrindo o app
  static Future<bool> isFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      return !hasSeenOnboarding;
    } catch (e) {
      print('Erro ao verificar primeira vez: $e');
      return true; // Em caso de erro, assume que é primeira vez
    }
  }

  // Marcar que o usuário já viu o onboarding
  static Future<void> markOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      print('Onboarding marcado como visto');
    } catch (e) {
      print('Erro ao marcar onboarding como visto: $e');
    }
  }

  // Marcar que o usuário está no processo de cadastro
  static Future<void> markInSignupProcess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('in_signup_process', true);
      print('✅ Processo de cadastro iniciado');

      // Verificar se realmente foi salvo
      final saved = prefs.getBool('in_signup_process');
      print('🔍 Verificação pós-salvamento processo de cadastro: $saved');
    } catch (e) {
      print('Erro ao marcar processo de cadastro: $e');
    }
  }

  // Verificar se está no processo de cadastro
  static Future<bool> isInSignupProcess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final flag = prefs.getBool('in_signup_process') ?? false;
      print('🔍 Flag de processo de cadastro: $flag');

      return flag;
    } catch (e) {
      print('Erro ao verificar processo de cadastro: $e');
      return false;
    }
  }

  // Limpar flag de processo de cadastro
  static Future<void> clearSignupProcess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('in_signup_process');
      print('✅ Flag de processo de cadastro removida');
    } catch (e) {
      print('Erro ao limpar flag de processo de cadastro: $e');
    }
  }

  // Limpar dados de processo de cadastro especificamente
  static Future<void> clearSignupData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('in_signup_process');
      print('Dados de processo de cadastro limpos com sucesso');
    } catch (e) {
      print('Erro ao limpar dados de processo de cadastro: $e');
    }
  }

  // Obter rota inicial baseada no status de login
  static Future<String> getInitialRoute() async {
    try {
      final isLoggedIn = await ServicoAutenticacao.isLoggedIn();

      // Se não está logado, sempre vai para tela de onboarding
      if (!isLoggedIn) {
        return '/onboarding';
      }

      // Se está logado, vai para dashboard baseado no tipo
      if (isLoggedIn) {
        final userType = await ServicoAutenticacao.getUserType();
        if (userType == 'cuidador') {
          return '/cuidador-dashboard';
        } else if (userType == 'responsavel') {
          return '/responsavel-dashboard';
        }
      }

      // Fallback para tela de onboarding
      return '/onboarding';
    } catch (e) {
      print('Erro ao determinar rota inicial: $e');
      return '/onboarding';
    }
  }
}
