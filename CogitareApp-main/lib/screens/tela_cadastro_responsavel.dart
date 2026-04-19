import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/endereco.dart';
import '../models/responsavel.dart';
import '../services/api_responsavel.dart';
import '../utils/form_validators.dart';
import 'tela_cadastro_idoso.dart';

class TelaCadastroResponsavel extends StatefulWidget {
  static const route = '/cadastro-responsavel';

  const TelaCadastroResponsavel({super.key});

  @override
  State<TelaCadastroResponsavel> createState() =>
      _TelaCadastroResponsavelState();
}

class _TelaCadastroResponsavelState extends State<TelaCadastroResponsavel> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final cpfController = TextEditingController();
  final phoneController = TextEditingController();
  final zipCodeController = TextEditingController();
  final cityController = TextEditingController();
  final neighborhoodController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final complementController = TextEditingController();

  DateTime? birthDate;
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    cpfController.dispose();
    phoneController.dispose();
    zipCodeController.dispose();
    cityController.dispose();
    neighborhoodController.dispose();
    streetController.dispose();
    numberController.dispose();
    complementController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) => FormValidators.validateName(value);
  String? _validateEmail(String? value) => FormValidators.validateEmail(value);
  String? _validatePassword(String? value) =>
      FormValidators.validatePassword(value);
  String? _validateConfirmPassword(String? value) =>
      FormValidators.validateConfirmPassword(value, passwordController.text);
  String? _validateCPF(String? value) => FormValidators.validateCPF(value);
  String? _validatePhone(String? value) => FormValidators.validatePhone(value);
  String? _validateZipCode(String? value) =>
      FormValidators.validateZipCode(value);

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initial = birthDate ?? DateTime(now.year - 25, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Selecione sua data de nascimento',
    );

    if (picked != null) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  Future<void> _buscarCep() async {
    final cep = zipCodeController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cep.length != 8) return;

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['erro'] == true) return;

        setState(() {
          streetController.text = data['logradouro'] ?? '';
          neighborhoodController.text = data['bairro'] ?? '';
          cityController.text = data['localidade'] ?? '';
        });
      }
    } catch (_) {}
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.green),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Preencha os campos obrigatórios corretamente.');
      return;
    }

    final birthDateError = FormValidators.validateBirthDate(birthDate);
    if (birthDateError != null) {
      _showSnack(birthDateError);
      return;
    }

    if (cityController.text.trim().isEmpty ||
        neighborhoodController.text.trim().isEmpty ||
        streetController.text.trim().isEmpty ||
        numberController.text.trim().isEmpty) {
      _showSnack('Preencha todos os dados do endereço.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final endereco = Endereco(
        city: cityController.text.trim(),
        neighborhood: neighborhoodController.text.trim(),
        street: streetController.text.trim(),
        number: numberController.text.trim(),
        zipCode: zipCodeController.text.trim(),
        complement: complementController.text.trim().isEmpty
            ? null
            : complementController.text.trim(),
      );

      final responsavel = Responsavel(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        cpf: cpfController.text.trim(),
        phone: phoneController.text.trim(),
        birthDate: birthDate,
      );

      final response = await ApiResponsavel.createComplete(
        address: endereco,
        guardian: responsavel,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final guardianId = response['guardianId'] ??
            response['id'] ??
            response['data']?['IdResponsavel'];

        Navigator.pushNamed(
          context,
          TelaCadastroIdoso.route,
          arguments: guardianId,
        );
      } else {
        _showSnack(response['message'] ?? 'Erro ao cadastrar responsável.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erro ao cadastrar: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f8fc),
      appBar: AppBar(
        title: const Text('Cadastro do Responsável'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Crie sua conta',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Preencha seus dados para continuar o cadastro no app.',
              ),
              const SizedBox(height: 18),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados pessoais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: _inputDecoration(
                        label: 'Nome completo',
                        hint: 'Digite nome e sobrenome',
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          label: 'Data de nascimento',
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          birthDate != null
                              ? DateFormat('dd/MM/yyyy').format(birthDate!)
                              : 'Selecione sua data de nascimento',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        label: 'E-mail',
                        hint: 'seuemail@exemplo.com',
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: cpfController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'CPF',
                        hint: 'Somente números ou formatado',
                      ),
                      validator: _validateCPF,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        label: 'Telefone',
                        hint: '(11) 99999-9999',
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: _inputDecoration(
                        label: 'Senha',
                        hint: 'Digite sua senha',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'A senha deve ter 8+ caracteres, maiúscula, minúscula, número e símbolo.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: _inputDecoration(
                        label: 'Confirmar senha',
                        hint: 'Digite novamente a senha',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: _validateConfirmPassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Endereço',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: zipCodeController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'CEP',
                        hint: '00000-000',
                        suffixIcon: const Icon(Icons.search),
                      ),
                      validator: _validateZipCode,
                      onChanged: (_) => _buscarCep(),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: streetController,
                      decoration: _inputDecoration(
                        label: 'Rua',
                        hint: 'Nome da rua',
                      ),
                      validator: (value) =>
                          FormValidators.validateRequired(value, 'Rua'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: numberController,
                      decoration: _inputDecoration(
                        label: 'Número',
                        hint: 'Ex.: 123',
                      ),
                      validator: (value) =>
                          FormValidators.validateRequired(value, 'Número'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: complementController,
                      decoration: _inputDecoration(
                        label: 'Complemento',
                        hint: 'Apartamento, bloco, casa...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: neighborhoodController,
                      decoration: _inputDecoration(
                        label: 'Bairro',
                        hint: 'Seu bairro',
                      ),
                      validator: (value) =>
                          FormValidators.validateRequired(value, 'Bairro'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: cityController,
                      decoration: _inputDecoration(
                        label: 'Cidade',
                        hint: 'Sua cidade',
                      ),
                      validator: (value) =>
                          FormValidators.validateRequired(value, 'Cidade'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _cadastrar,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continuar cadastro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}