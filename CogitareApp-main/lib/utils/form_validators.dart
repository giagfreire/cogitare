import 'validadores.dart';

/// Validações específicas para formulários
class FormValidators {
  /// Valida nome completo
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    return null;
  }

  /// Valida e-mail
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-mail é obrigatório';
    }
    if (!Validators.isValidEmail(value)) {
      return 'E-mail inválido';
    }
    return null;
  }

  /// Valida senha
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (!Validators.isValidPassword(value)) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  /// Valida confirmação de senha
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (!Validators.passwordsMatch(value, password)) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  /// Valida CPF
  static String? validateCPF(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }
    if (!Validators.isValidCPF(value)) {
      return 'CPF inválido';
    }
    return null;
  }

  /// Valida telefone
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }
    if (!Validators.isValidPhone(value)) {
      return 'Telefone inválido';
    }
    return null;
  }

  /// Valida CEP
  static String? validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'CEP é obrigatório';
    }
    // Remove caracteres não numéricos
    final cleanZipCode = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanZipCode.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }
    return null;
  }

  /// Valida data de nascimento
  static String? validateBirthDate(DateTime? value) {
    if (value == null) {
      return 'Data de nascimento é obrigatória';
    }
    final now = DateTime.now();
    final age = now.year - value.year;
    if (age < 18) {
      return 'Você deve ter pelo menos 18 anos';
    }
    if (value.isAfter(now)) {
      return 'Data de nascimento não pode ser no futuro';
    }
    return null;
  }

  /// Valida campo obrigatório
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }
}

