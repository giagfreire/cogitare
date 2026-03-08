import '../models/cuidador.dart';
import '../models/endereco.dart';
import '../services/api_cuidador.dart';

/// Controller responsável pela lógica de negócio do Cadastro de Cuidador
class CadastroCuidadorController {
  /// Valida step 0 (dados básicos)
  static bool validateStep0({
    required String? name,
    required String? email,
    required String? password,
    required String? confirmPassword,
    required String? cpf,
    required String? phone,
    required String? zipCode,
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
        birthDate != null;
  }

  /// Valida step 1 (registros profissionais)
  static bool validateStep1(DateTime? registrationDate) {
    return registrationDate != null;
  }

  /// Valida step 2 (biografia e valor)
  static bool validateStep2({
    required String bio,
    required String hourlyRate,
  }) {
    return bio.isNotEmpty && hourlyRate.isNotEmpty;
  }

  /// Valida step 3 (informações pessoais)
  static bool validateStep3() {
    return true; // Step 3 não tem validações obrigatórias
  }

  /// Valida step 4 (especialidades e serviços)
  static bool validateStep4({
    required List<String> specializations,
    required List<String> services,
  }) {
    return specializations.isNotEmpty || services.isNotEmpty;
  }

  /// Valida step 5 (disponibilidade)
  static bool validateStep5(Map<String, Map<String, dynamic>> availability) {
    bool hasAvailability = false;
    availability.forEach((dia, dados) {
      bool disponivel = dados['disponivel'] ?? false;
      String inicio = dados['inicio'] ?? '';
      String fim = dados['fim'] ?? '';

      if (disponivel && inicio.isNotEmpty && fim.isNotEmpty) {
        hasAvailability = true;
      }
    });
    return hasAvailability;
  }

  /// Valida formulário completo
  static bool validateForm({
    required bool step0Valid,
    required bool step1Valid,
    required bool step2Valid,
    required bool step3Valid,
    required bool step4Valid,
    required bool step5Valid,
  }) {
    return step0Valid &&
        step1Valid &&
        step2Valid &&
        step3Valid &&
        step4Valid &&
        step5Valid;
  }

  /// Executa o cadastro do cuidador
  static Future<Map<String, dynamic>> performCadastro({
    required Endereco address,
    required Cuidador caregiver,
  }) async {
    try {
      final response = await ApiCuidador.createComplete(
        address: address,
        caregiver: caregiver,
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
