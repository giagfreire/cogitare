import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/widgets_comuns.dart';
import '../models/responsavel.dart';
import '../models/endereco.dart';
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
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final cpfController = TextEditingController();
  final zipCodeController = TextEditingController();
  final cityController = TextEditingController();
  final neighborhoodController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final complementController = TextEditingController();
  DateTime? birthDate;
  bool isLoading = false;

  // Usar FormValidators para validações
  String? _validateName(String? value) => FormValidators.validateName(value);
  String? _validateEmail(String? value) => FormValidators.validateEmail(value);
  String? _validatePassword(String? value) => FormValidators.validatePassword(value);
  String? _validateConfirmPassword(String? value) => 
      FormValidators.validateConfirmPassword(value, passwordController.text);
  String? _validateCPF(String? value) => FormValidators.validateCPF(value);
  String? _validatePhone(String? value) => FormValidators.validatePhone(value);
  String? _validateZipCode(String? value) => FormValidators.validateZipCode(value);

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != birthDate) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  bool _validateForm() {
    return _validateName(nameController.text) == null &&
        _validateEmail(emailController.text) == null &&
        _validatePassword(passwordController.text) == null &&
        _validateConfirmPassword(confirmPasswordController.text) == null &&
        _validateCPF(cpfController.text) == null &&
        _validatePhone(phoneController.text) == null &&
        _validateZipCode(zipCodeController.text) == null &&
        cityController.text.isNotEmpty &&
        neighborhoodController.text.isNotEmpty &&
        streetController.text.isNotEmpty &&
        numberController.text.isNotEmpty &&
        birthDate != null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _next() async {
    if (!_validateForm()) {
      _showErrorDialog(
          'Por favor, preencha todos os campos obrigatórios corretamente.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create address
      final address = Endereco(
        city: cityController.text,
        neighborhood: neighborhoodController.text,
        street: streetController.text,
        number: numberController.text,
        complement: complementController.text,
        zipCode: zipCodeController.text,
      );

      // Create guardian
      final guardian = Responsavel(
        cpf: cpfController.text,
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        birthDate: birthDate,
        password: passwordController.text,
      );

      // Create guardian
      final response = await ApiResponsavel.createComplete(
        address: address,
        guardian: guardian,
      );

      if (response['success'] == true) {
        // Store guardian ID for elder registration
        final guardianId = response['data']['idResponsavel'];
        print('DEBUG: Guardian ID capturado: $guardianId');
        print('DEBUG: Response completa: $response');
        Navigator.pushReplacementNamed(context, TelaCadastroIdoso.route,
            arguments: guardianId);
      } else {
        _showErrorDialog(
            'Erro no cadastro: ${response['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      _showErrorDialog('Erro no cadastro: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text("Criar conta"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).padding.bottom + 60),
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nome Completo do Responsável",
                  hintText: "Digite seu nome completo",
                  errorText: _validateName(nameController.text) != null &&
                          nameController.text.isNotEmpty
                      ? _validateName(nameController.text)
                      : null,
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "E-mail",
                  hintText: "Digite seu e-mail",
                  errorText: _validateEmail(emailController.text) != null &&
                          emailController.text.isNotEmpty
                      ? _validateEmail(emailController.text)
                      : null,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Senha",
                  hintText: "Digite sua senha",
                  errorText:
                      _validatePassword(passwordController.text) != null &&
                              passwordController.text.isNotEmpty
                          ? _validatePassword(passwordController.text)
                          : null,
                ),
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: "Confirmar senha",
                  hintText: "Confirme sua senha",
                  errorText: _validateConfirmPassword(
                                  confirmPasswordController.text) !=
                              null &&
                          confirmPasswordController.text.isNotEmpty
                      ? _validateConfirmPassword(confirmPasswordController.text)
                      : null,
                ),
                obscureText: true,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: cpfController,
                decoration: InputDecoration(
                  labelText: "CPF",
                  hintText: "Digite seu CPF",
                  errorText: _validateCPF(cpfController.text) != null &&
                          cpfController.text.isNotEmpty
                      ? _validateCPF(cpfController.text)
                      : null,
                ),
                keyboardType: TextInputType.number,
                validator: _validateCPF,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: "Telefone",
                  hintText: "Digite seu telefone",
                  errorText: _validatePhone(phoneController.text) != null &&
                          phoneController.text.isNotEmpty
                      ? _validatePhone(phoneController.text)
                      : null,
                ),
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: zipCodeController,
                decoration: InputDecoration(
                  labelText: "CEP",
                  hintText: "Digite seu CEP",
                  errorText: _validateZipCode(zipCodeController.text) != null &&
                          zipCodeController.text.isNotEmpty
                      ? _validateZipCode(zipCodeController.text)
                      : null,
                ),
                keyboardType: TextInputType.number,
                validator: _validateZipCode,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: "Cidade",
                  hintText: "Digite sua cidade",
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: neighborhoodController,
                decoration: const InputDecoration(
                  labelText: "Bairro",
                  hintText: "Digite seu bairro",
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: streetController,
                      decoration: const InputDecoration(
                        labelText: "Rua",
                        hintText: "Nome da rua",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: "Nº",
                        hintText: "123",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: complementController,
                decoration: const InputDecoration(
                  labelText: "Complemento",
                  hintText: "Apto, casa, etc.",
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Data de Nascimento",
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    birthDate != null
                        ? DateFormat('dd/MM/yyyy').format(birthDate!)
                        : "Selecione sua data de nascimento",
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StepDots(total: 1, index: 0),
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: isLoading ? null : _next,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Continuar para cadastro do Idoso"))),
            ],
          ),
        ),
      ),
    );
  }
}
