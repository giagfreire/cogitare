import '../models/responsavel.dart';
import '../models/endereco.dart';
import '../services/api_responsavel.dart';

/// Controller responsável pela lógica de negócio do Cadastro de Responsável
class CadastroResponsavelController {
  /// Valida o formulário completo
  static bool validateForm({
    required String? name,
    required String? email,
    required String? password,
    required String? confirmPassword,
    required String? cpf,
    required String? phone,
    required String? zipCode,
    required String? city,
    required String? neighborhood,
    required String? street,
    required String? number,
    required DateTime? birthDate,
  }) {
    return name != null &&
        name.isNotEmpty &&
        email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty &&
        confirmPassword != null &&
        confirmPassword.isNotEmpty &&
        cpf != null &&
        cpf.isNotEmpty &&
        phone != null &&
        phone.isNotEmpty &&
        zipCode != null &&
        zipCode.isNotEmpty &&
        city != null &&
        city.isNotEmpty &&
        neighborhood != null &&
        neighborhood.isNotEmpty &&
        street != null &&
        street.isNotEmpty &&
        number != null &&
        number.isNotEmpty &&
        birthDate != null;
  }

  /// Executa o cadastro do responsável
  static Future<Map<String, dynamic>> performCadastro({
    required Endereco address,
    required Responsavel guardian,
  }) async {
    try {
      final response = await ApiResponsavel.createComplete(
        address: address,
        guardian: guardian,
      );
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao realizar cadastro: $e',
      };
    }
  }
}
