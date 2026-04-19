import 'validadores.dart';

class FormValidators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome é obrigatório';
    }

    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length < 2) {
      return 'Digite nome e sobrenome';
    }

    if (parts[0].length < 2 || parts[1].length < 2) {
      return 'Nome e sobrenome devem ser válidos';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-mail é obrigatório';
    }

    if (!Validators.isValidEmail(value.trim())) {
      return 'E-mail inválido';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }

    if (value.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'A senha deve ter ao menos 1 letra maiúscula';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'A senha deve ter ao menos 1 letra minúscula';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'A senha deve ter ao menos 1 número';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\];]').hasMatch(value)) {
      return 'A senha deve ter ao menos 1 caractere especial';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }

    if (!Validators.passwordsMatch(value, password)) {
      return 'As senhas não coincidem';
    }

    return null;
  }

  static String? validateCPF(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CPF é obrigatório';
    }

    if (!Validators.isValidCPF(value)) {
      return 'CPF inválido';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefone é obrigatório';
    }

    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 10 || clean.length > 11) {
      return 'Telefone inválido';
    }

    return null;
  }

  static String? validateZipCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CEP é obrigatório';
    }

    final cleanZipCode = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanZipCode.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }

    return null;
  }

  static String? validateBirthDate(DateTime? value, {int minAge = 18}) {
    if (value == null) {
      return 'Data de nascimento é obrigatória';
    }

    final now = DateTime.now();

    if (value.isAfter(now)) {
      return 'Data de nascimento não pode ser no futuro';
    }

    int age = now.year - value.year;
    final hadBirthdayThisYear =
        (now.month > value.month) ||
        (now.month == value.month && now.day >= value.day);

    if (!hadBirthdayThisYear) {
      age--;
    }

    if (age < minAge) {
      return 'Você deve ter pelo menos $minAge anos';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }
}