/// Classe de validação de dados
class Validators {
  /// Valida CPF
  static bool isValidCPF(String cpf) {
    // Remove caracteres não numéricos
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Verifica se tem 11 dígitos
    if (cpf.length != 11) return false;

    // Verifica se todos os dígitos são iguais
    if (cpf.split('').every((digit) => digit == cpf[0])) return false;

    // Validação do primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int firstDigit = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cpf[9]) != firstDigit) return false;

    // Validação do segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    int secondDigit = remainder < 2 ? 0 : 11 - remainder;

    return int.parse(cpf[10]) == secondDigit;
  }

  /// Valida e-mail
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Valida se o campo não está vazio
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Valida telefone (formato brasileiro)
  static bool isValidPhone(String phone) {
    // Remove caracteres não numéricos
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Telefone brasileiro deve ter 10 ou 11 dígitos (com DDD)
    return cleanPhone.length >= 10 && cleanPhone.length <= 11;
  }

  /// Valida senha (mínimo 6 caracteres)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Valida se a senha confere
  static bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }
}
