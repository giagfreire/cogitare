import '../models/idoso.dart';
import '../services/api_idoso.dart';

/// Controller responsável pela lógica de negócio do Cadastro de Idoso
class CadastroIdosoController {
  /// Valida o formulário de cadastro de idoso
  static bool validateForm({
    required String? name,
    required DateTime? birthDate,
    required String? gender,
  }) {
    return name != null &&
        name.isNotEmpty &&
        birthDate != null &&
        gender != null;
  }

  /// Executa o cadastro do idoso
  static Future<Map<String, dynamic>> performCadastro({
    required Idoso idoso,
  }) async {
    try {
      final response = await ApiIdoso.create(idoso);
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao realizar cadastro: $e',
      };
    }
  }
}
