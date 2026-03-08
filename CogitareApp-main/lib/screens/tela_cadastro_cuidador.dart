import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/widgets_comuns.dart';
import '../models/cuidador.dart';
import '../models/endereco.dart';
import '../services/api_cuidador.dart';
import '../services/api_service.dart';
import '../utils/form_validators.dart';
import 'tela_sucesso.dart';

class TelaCadastroCuidador extends StatefulWidget {
  static const route = '/cadastro-cuidador';
  const TelaCadastroCuidador({super.key});

  @override
  State<TelaCadastroCuidador> createState() => _TelaCadastroCuidadorState();
}

class _TelaCadastroCuidadorState extends State<TelaCadastroCuidador> {
  final page = PageController();
  int index = 0;
  bool isLoading = false;

  // step 1
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

  // step 2 - Registros Profissionais
  final crmController = TextEditingController();
  final crefitoController = TextEditingController();
  final corenController = TextEditingController();
  final crpController = TextEditingController();
  DateTime? registrationDate;
  String? registrationStatus;

  // step 3 - Especialidades e Serviços
  final specializations = <String>{};
  final services = <String>{};
  List<Map<String, dynamic>> availableSpecializations = [];
  List<Map<String, dynamic>> availableServices = [];

  // step 4 - Informações Pessoais
  String? smokingStatus = 'Não';
  String? hasChildren = 'Não';
  String? hasLicense = 'Não';
  String? hasCar = 'Não';
  final biographyController = TextEditingController();

  // step 5 - Disponibilidade
  final Map<String, Map<String, dynamic>> availability = {
    'Segunda': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Terça': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Quarta': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Quinta': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Sexta': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Sábado': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Domingo': {'disponivel': false, 'inicio': '', 'fim': ''},
  };

  // Controllers para os campos de horário
  final Map<String, TextEditingController> _inicioControllers = {};
  final Map<String, TextEditingController> _fimControllers = {};

  // Campos adicionais
  final bioController = TextEditingController();
  final hourlyRateController = TextEditingController();

  // Validations
  // Usar FormValidators para validações
  String? _validateName(String? value) => FormValidators.validateName(value);
  String? _validateEmail(String? value) => FormValidators.validateEmail(value);
  String? _validatePassword(String? value) => FormValidators.validatePassword(value);
  String? _validateConfirmPassword(String? value) => 
      FormValidators.validateConfirmPassword(value, passwordController.text);
  String? _validateCPF(String? value) => FormValidators.validateCPF(value);
  String? _validatePhone(String? value) => FormValidators.validatePhone(value);
  String? _validateZipCode(String? value) => FormValidators.validateZipCode(value);

  void _next() {
    if (index < 5) {
      // 6 steps: 0, 1, 2, 3, 4, 5
      page.nextPage(
          duration: const Duration(milliseconds: 250), curve: Curves.ease);
    } else if (index == 5) {
      // Só chama _finish() quando estiver no último step (5)
      _finish();
    }
  }

  void _prev() => page.previousPage(
      duration: const Duration(milliseconds: 250), curve: Curves.ease);

  // Salvar dados adicionais dos steps 2, 3 e 4
  Future<void> _saveAdditionalData(int caregiverId) async {
    try {
      print('🔍 Salvando dados adicionais para cuidador ID: $caregiverId');

      // Step 2: Registros Profissionais
      if (crmController.text.isNotEmpty ||
          crefitoController.text.isNotEmpty ||
          corenController.text.isNotEmpty ||
          crpController.text.isNotEmpty) {
        print('🔍 Salvando registros profissionais...');
        await _saveProfessionalRegistrations(caregiverId);
      }

      // Step 3: Especialidades e Serviços
      if (specializations.isNotEmpty || services.isNotEmpty) {
        print('🔍 Salvando especialidades e serviços...');
        await _saveSpecializationsAndServices(caregiverId);
      }

      // Step 4: Informações Pessoais (já salvas no cuidador básico)

      // Step 5: Disponibilidade
      print('🔍 Salvando disponibilidades...');
      await _saveAvailability(caregiverId);

      print('✅ Dados adicionais salvos com sucesso!');
    } catch (e) {
      print('❌ Erro ao salvar dados adicionais: $e');
      // Não falhar o cadastro por causa dos dados adicionais
    }
  }

  // Salvar registros profissionais
  Future<void> _saveProfessionalRegistrations(int caregiverId) async {
    try {
      final response = await ServicoApi.post('/api/registro-profissional', {
        'cuidador_id': caregiverId,
        'crm': crmController.text,
        'crefito': crefitoController.text,
        'coren': corenController.text,
        'crp': crpController.text,
        'data_registro': registrationDate?.toIso8601String().split('T')[0],
        'status_registro': registrationStatus ?? 'Ativo',
      });

      if (response['success']) {
        print('✅ Registros profissionais salvos');
      } else {
        print(
            '❌ Erro ao salvar registros profissionais: ${response['message']}');
      }
    } catch (e) {
      print('❌ Erro ao salvar registros profissionais: $e');
    }
  }

  // Salvar especialidades e serviços
  Future<void> _saveSpecializationsAndServices(int caregiverId) async {
    try {
      // Salvar especialidades
      for (String specialization in specializations) {
        await ServicoApi.post('/api/cuidador/especialidade', {
          'cuidador_id': caregiverId,
          'especialidade': specialization,
        });
      }

      // Salvar serviços
      for (String service in services) {
        await ServicoApi.post('/api/cuidador/servico', {
          'cuidador_id': caregiverId,
          'servico': service,
        });
      }

      print('✅ Especialidades e serviços salvos');
    } catch (e) {
      print('❌ Erro ao salvar especialidades e serviços: $e');
    }
  }

  // Salvar disponibilidades
  Future<void> _saveAvailability(int caregiverId) async {
    try {
      List<Map<String, dynamic>> disponibilidades = [];

      // Converter disponibilidade para formato do banco
      availability.forEach((dia, dados) {
        bool disponivel = dados['disponivel'] ?? false;
        String inicio = dados['inicio'] ?? '';
        String fim = dados['fim'] ?? '';

        print(
            '🔍 Processando dia $dia: disponivel=$disponivel, inicio=$inicio, fim=$fim');

        if (disponivel && inicio.isNotEmpty && fim.isNotEmpty) {
          disponibilidades.add({
            'dia_semana': dia,
            'data_inicio': inicio,
            'data_fim': fim,
            'observacoes': 'Disponível das $inicio às $fim',
            'recorrente': 1
          });
        }
      });

      if (disponibilidades.isNotEmpty) {
        final response =
            await ServicoApi.post('/api/cuidador/disponibilidade', {
          'cuidador_id': caregiverId,
          'disponibilidades': disponibilidades,
        });

        if (!response['success']) {
          print('❌ Erro ao salvar disponibilidades: ${response['message']}');
        }
      }
    } catch (e) {
      print('❌ Erro ao salvar disponibilidades: $e');
    }
  }

  Future<void> _finish() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print('🔍 Criando endereço...');
      // Create address
      final address = Endereco(
        city: cityController.text,
        neighborhood: neighborhoodController.text,
        street: streetController.text,
        number: numberController.text,
        complement: complementController.text,
        zipCode: zipCodeController.text,
      );
      print('✅ Endereço criado: ${address.toJson()}');

      print('🔍 Criando cuidador...');
      // Create caregiver
      final caregiver = Cuidador(
        cpf: cpfController.text,
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        password: passwordController.text,
        birthDate: birthDate,
        biography: bioController.text,
        smokingStatus: smokingStatus,
        hasChildren: hasChildren,
        hasLicense: hasLicense,
        hasCar: hasCar,
        hourlyRate: hourlyRateController.text,
      );

      print('✅ Cuidador criado: ${caregiver.toJson()}');

      print('🔍 Chamando ServicoCuidador.createComplete...');
      // Create caregiver
      final response = await ApiCuidador.createComplete(
        address: address,
        caregiver: caregiver,
      );
      print('✅ Resultado do cadastro: $response');

      if (response['success'] == true) {
        final caregiverId = response['caregiverId'];
        print('🔍 Cuidador criado com ID: $caregiverId');

        // Agora salvar os dados dos steps 2, 3 e 4
        await _saveAdditionalData(caregiverId);
      }

      if (response['success'] == true) {
        Navigator.pushReplacementNamed(context, TelaSucesso.route,
            arguments: "Cadastro do cuidador realizado com sucesso!");
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

  // Validação específica para cada step
  bool _validateStep0() {
    final isValid = _validateName(nameController.text) == null &&
        _validateEmail(emailController.text) == null &&
        _validatePassword(passwordController.text) == null &&
        _validateConfirmPassword(confirmPasswordController.text) == null &&
        _validateCPF(cpfController.text) == null &&
        _validatePhone(phoneController.text) == null &&
        _validateZipCode(zipCodeController.text) == null &&
        birthDate != null;

    print('🔍 Validação Step 0: $isValid');
    return isValid;
  }

  bool _validateStep1() {
    final isValid = registrationDate != null; // Data de registro é obrigatória
    return isValid;
  }

  bool _validateStep2() {
    final isValid = bioController.text.isNotEmpty &&
        hourlyRateController
            .text.isNotEmpty; // Biografia e valor por hora são obrigatórios
    return isValid;
  }

  bool _validateStep3() {
    return true; // Step 3 (Informações Pessoais) não tem validações obrigatórias
  }

  bool _validateStep4() {
    final isValid = specializations.isNotEmpty ||
        services.isNotEmpty; // Pelo menos uma especialidade ou serviço
    return isValid;
  }

  bool _validateStep5() {
    // Verificar se pelo menos uma disponibilidade foi selecionada com horários válidos
    bool hasAvailability = false;
    availability.forEach((dia, dados) {
      bool disponivel = dados['disponivel'] ?? false;
      String inicio = dados['inicio'] ?? '';
      String fim = dados['fim'] ?? '';

      if (disponivel && inicio.isNotEmpty && fim.isNotEmpty) {
        hasAvailability = true;
      }
    });

    return hasAvailability; // Pelo menos uma disponibilidade com horários deve ser selecionada
  }

  // Validação completa para o final do cadastro
  bool _validateForm() {
    return _validateStep0() &&
        _validateStep1() &&
        _validateStep2() &&
        _validateStep3() &&
        _validateStep4() &&
        _validateStep5();
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != birthDate) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  Future<void> _selectRegistrationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: registrationDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != registrationDate) {
      setState(() {
        registrationDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSpecializationsAndServices();
    _initializeControllers();
  }

  // Inicializar controllers para os campos de horário
  void _initializeControllers() {
    for (String dia in availability.keys) {
      _inicioControllers[dia] = TextEditingController();
      _fimControllers[dia] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Limpar controllers
    for (var controller in _inicioControllers.values) {
      controller.dispose();
    }
    for (var controller in _fimControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Carregar especialidades e serviços do banco
  Future<void> _loadSpecializationsAndServices() async {
    try {
      // Carregar especialidades
      final especialidadesResponse =
          await ServicoApi.get('/api/cuidador/especialidades');
      if (especialidadesResponse['success']) {
        setState(() {
          availableSpecializations =
              List<Map<String, dynamic>>.from(especialidadesResponse['data']);
        });
        print(
            '✅ Especialidades carregadas: ${availableSpecializations.length}');
      }

      // Carregar serviços
      final servicosResponse = await ServicoApi.get('/api/cuidador/servicos');
      if (servicosResponse['success']) {
        setState(() {
          availableServices =
              List<Map<String, dynamic>>.from(servicosResponse['data']);
        });
        print('✅ Serviços carregados: ${availableServices.length}');
      }
    } catch (e) {
      print('❌ Erro ao carregar especialidades e serviços: $e');
      // Fallback para dados estáticos em caso de erro
      setState(() {
        availableSpecializations = [
          {'IdEspecialidade': 1, 'Nome': 'Cuidados básicos'},
          {'IdEspecialidade': 2, 'Nome': 'Cuidados médicos'},
          {'IdEspecialidade': 3, 'Nome': 'Fisioterapia'},
          {'IdEspecialidade': 4, 'Nome': 'Psicologia'},
          {'IdEspecialidade': 5, 'Nome': 'Enfermagem'}
        ];
        availableServices = [
          {'IdServico': 1, 'Nome': 'Cuidados 24h'},
          {'IdServico': 2, 'Nome': 'Cuidados diurnos'},
          {'IdServico': 3, 'Nome': 'Cuidados noturnos'},
          {'IdServico': 4, 'Nome': 'Cuidados de fim de semana'},
          {'IdServico': 5, 'Nome': 'Cuidados esporádicos'}
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (index == 0)
                Navigator.pop(context);
              else
                _prev();
            }),
        title: const Text("Criar conta"),
      ),
      body: PageView(
        controller: page,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) {
          setState(() => index = i);
        },
        children: [
          _StepScaffold(
            index: 0,
            total: 6,
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Nome Completo",
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
                        ? _validateConfirmPassword(
                            confirmPasswordController.text)
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
                    errorText:
                        _validateZipCode(zipCodeController.text) != null &&
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
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _validateStep0() ? _next : null,
                        child: const Text("Continuar"))),
              ],
            ),
          ),
          _StepScaffold(
            index: 1,
            total: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Registros Profissionais",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                LabeledField(
                  label: "CRM (Médico)",
                  hint: "Digite o número do CRM",
                  controller: crmController,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: "CREFITO (Fisioterapeuta)",
                  hint: "Digite o número do CREFITO",
                  controller: crefitoController,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: "COREN (Enfermeiro)",
                  hint: "Digite o número do COREN",
                  controller: corenController,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: "CRP (Psicólogo)",
                  hint: "Digite o número do CRP",
                  controller: crpController,
                ),
                const SizedBox(height: 16),
                const Text("Data de Registro *",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectRegistrationDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          registrationDate != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(registrationDate!)
                              : 'Selecione a data',
                          style: TextStyle(
                            color: registrationDate != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Status do Registro",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                DropdownButtonFormField<String>(
                  value: registrationStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecione o status',
                  ),
                  items: ['Ativo', 'Inativo', 'Suspenso'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      registrationStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _validateStep1() ? _next : null,
                      child: const Text("Continuar")),
                ),
              ],
            ),
          ),
          _StepScaffold(
            index: 2,
            total: 6,
            child: Column(
              children: [
                Row(
                  children: const [
                    CircleAvatar(radius: 28, child: Icon(Icons.person)),
                    SizedBox(width: 12),
                    Text("Adicionar Foto"),
                  ],
                ),
                const SizedBox(height: 12),
                LabeledField(
                    label: "Breve biografia",
                    hint: "Escreva um pouco sobre você",
                    controller: bioController),
                const SizedBox(height: 10),
                LabeledField(
                    label: "Valor por hora",
                    hint: "Ex. R\$ 50,00",
                    controller: hourlyRateController,
                    keyboard: TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(value: true, onChanged: (_) {}),
                    const Expanded(child: Text("Li e aceito os Termos de Uso")),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: isLoading ? null : _next,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Continuar"))),
              ],
            ),
          ),
          // Step 3 - Informações Pessoais
          _StepScaffold(
            index: 3,
            total: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Informações Pessoais",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text("Fumante:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Sim',
                      groupValue: smokingStatus,
                      onChanged: (value) {
                        setState(() {
                          smokingStatus = value;
                        });
                      },
                    ),
                    const Text('Sim'),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: 'Não',
                      groupValue: smokingStatus,
                      onChanged: (value) {
                        setState(() {
                          smokingStatus = value;
                        });
                      },
                    ),
                    const Text('Não'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Tem filhos:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Sim',
                      groupValue: hasChildren,
                      onChanged: (value) {
                        setState(() {
                          hasChildren = value;
                        });
                      },
                    ),
                    const Text('Sim'),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: 'Não',
                      groupValue: hasChildren,
                      onChanged: (value) {
                        setState(() {
                          hasChildren = value;
                        });
                      },
                    ),
                    const Text('Não'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Possui CNH:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Sim',
                      groupValue: hasLicense,
                      onChanged: (value) {
                        setState(() {
                          hasLicense = value;
                        });
                      },
                    ),
                    const Text('Sim'),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: 'Não',
                      groupValue: hasLicense,
                      onChanged: (value) {
                        setState(() {
                          hasLicense = value;
                        });
                      },
                    ),
                    const Text('Não'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Tem carro:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Sim',
                      groupValue: hasCar,
                      onChanged: (value) {
                        setState(() {
                          hasCar = value;
                        });
                      },
                    ),
                    const Text('Sim'),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: 'Não',
                      groupValue: hasCar,
                      onChanged: (value) {
                        setState(() {
                          hasCar = value;
                        });
                      },
                    ),
                    const Text('Não'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _validateStep3() ? _next : null,
                      child: const Text("Continuar")),
                ),
              ],
            ),
          ),
          // Step 4 - Especialidades e Serviços
          _StepScaffold(
            index: 4,
            total: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Especialidades",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableSpecializations
                      .map((spec) => FilterChip(
                            label: Text(spec['Nome']),
                            selected: specializations.contains(spec['Nome']),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  specializations.add(spec['Nome']);
                                } else {
                                  specializations.remove(spec['Nome']);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                const Text("Serviços",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableServices
                      .map((service) => FilterChip(
                            label: Text(service['Nome']),
                            selected: services.contains(service['Nome']),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  services.add(service['Nome']);
                                } else {
                                  services.remove(service['Nome']);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _validateStep2() ? _next : null,
                      child: const Text("Continuar")),
                ),
              ],
            ),
          ),
          // Step 5 - Disponibilidade
          _StepScaffold(
            index: 5,
            total: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Disponibilidade",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text("Selecione seus horários disponíveis:",
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 16),
                // Horários de disponibilidade por dia da semana
                ...availability.entries.map((entry) {
                  String dia = entry.key;
                  Map<String, dynamic> dados = entry.value;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dia,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Switch(
                                value: dados['disponivel'] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    availability[dia]!['disponivel'] = value;
                                    if (!value) {
                                      // Limpar horários quando desabilitar
                                      availability[dia]!['inicio'] = '';
                                      availability[dia]!['fim'] = '';
                                      _inicioControllers[dia]!.clear();
                                      _fimControllers[dia]!.clear();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          if (dados['disponivel'] == true) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _inicioControllers[dia],
                                    decoration: const InputDecoration(
                                      labelText: 'Início',
                                      hintText: 'Ex: 06:00',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        availability[dia]!['inicio'] = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _fimControllers[dia],
                                    decoration: const InputDecoration(
                                      labelText: 'Fim',
                                      hintText: 'Ex: 16:00',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        availability[dia]!['fim'] = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _validateStep4() ? _next : null,
                      child: const Text("Continuar")),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final int index;
  final int total;
  final Widget child;
  const _StepScaffold(
      {required this.index, required this.total, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).padding.bottom + 60),
        child: Column(
          children: [
            child,
            const SizedBox(height: 24),
            StepDots(total: total, index: index),
          ],
        ),
      ),
    );
  }
}
