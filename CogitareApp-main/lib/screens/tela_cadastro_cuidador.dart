import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/widgets_comuns.dart';
import '../services/api_service.dart';
import 'tela_sucesso.dart';

class TelaCadastroCuidador extends StatefulWidget {
  static const route = '/cadastro-cuidador';

  const TelaCadastroCuidador({super.key});

  @override
  State<TelaCadastroCuidador> createState() => _TelaCadastroCuidadorState();
}

class _TelaCadastroCuidadorState extends State<TelaCadastroCuidador> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();

  final TextEditingController zipCodeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController neighborhoodController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController complementController = TextEditingController();

  final TextEditingController crmController = TextEditingController();
  final TextEditingController crefitoController = TextEditingController();
  final TextEditingController corenController = TextEditingController();
  final TextEditingController crpController = TextEditingController();

  final TextEditingController bioController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();

  DateTime? birthDate;
  DateTime? registrationDate;
  String? registrationStatus = 'Ativo';

  String smokingStatus = 'Não';
  String hasChildren = 'Não';
  String hasLicense = 'Não';
  String hasCar = 'Não';

  final Set<String> specializations = {};
  final Set<String> services = {};

  List<Map<String, dynamic>> availableSpecializations = [];
  List<Map<String, dynamic>> availableServices = [];

  final Map<String, Map<String, dynamic>> availability = {
    'Segunda': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Terça': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Quarta': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Quinta': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Sexta': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Sábado': {'disponivel': false, 'inicio': '', 'fim': ''},
    'Domingo': {'disponivel': false, 'inicio': '', 'fim': ''},
  };

  final Map<String, TextEditingController> _inicioControllers = {};
  final Map<String, TextEditingController> _fimControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSpecializationsAndServices();
  }

  void _initializeControllers() {
    for (final dia in availability.keys) {
      _inicioControllers[dia] = TextEditingController();
      _fimControllers[dia] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    cpfController.dispose();

    zipCodeController.dispose();
    cityController.dispose();
    neighborhoodController.dispose();
    streetController.dispose();
    numberController.dispose();
    complementController.dispose();

    crmController.dispose();
    crefitoController.dispose();
    corenController.dispose();
    crpController.dispose();

    bioController.dispose();
    hourlyRateController.dispose();

    for (final c in _inicioControllers.values) {
      c.dispose();
    }
    for (final c in _fimControllers.values) {
      c.dispose();
    }

    super.dispose();
  }

  Future<void> _loadSpecializationsAndServices() async {
    try {
      final especialidadesResponse =
          await ServicoApi.get('/api/cuidador/especialidades');
      final servicosResponse = await ServicoApi.get('/api/cuidador/servicos');

      setState(() {
        if (especialidadesResponse['success'] == true) {
          availableSpecializations =
              List<Map<String, dynamic>>.from(especialidadesResponse['data']);
        } else {
          availableSpecializations = [];
        }

        if (servicosResponse['success'] == true) {
          availableServices =
              List<Map<String, dynamic>>.from(servicosResponse['data']);
        } else {
          availableServices = [];
        }

        if (availableSpecializations.isEmpty) {
          availableSpecializations = [
            {'IdEspecialidade': 1, 'Nome': 'Cuidados básicos'},
            {'IdEspecialidade': 2, 'Nome': 'Enfermagem'},
            {'IdEspecialidade': 3, 'Nome': 'Fisioterapia'},
            {'IdEspecialidade': 4, 'Nome': 'Psicologia'},
          ];
        }

        if (availableServices.isEmpty) {
          availableServices = [
            {'IdServico': 1, 'Nome': 'Cuidados 24h'},
            {'IdServico': 2, 'Nome': 'Cuidados diurnos'},
            {'IdServico': 3, 'Nome': 'Cuidados noturnos'},
            {'IdServico': 4, 'Nome': 'Fim de semana'},
          ];
        }
      });
    } catch (_) {
      setState(() {
        availableSpecializations = [
          {'IdEspecialidade': 1, 'Nome': 'Cuidados básicos'},
          {'IdEspecialidade': 2, 'Nome': 'Enfermagem'},
          {'IdEspecialidade': 3, 'Nome': 'Fisioterapia'},
          {'IdEspecialidade': 4, 'Nome': 'Psicologia'},
        ];
        availableServices = [
          {'IdServico': 1, 'Nome': 'Cuidados 24h'},
          {'IdServico': 2, 'Nome': 'Cuidados diurnos'},
          {'IdServico': 3, 'Nome': 'Cuidados noturnos'},
          {'IdServico': 4, 'Nome': 'Fim de semana'},
        ];
      });
    }
  }

  bool _isEmailValid(String value) {
    return value.contains('@') && value.contains('.');
  }

  String _onlyNumbers(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  bool _validateStep0() {
    return nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        _isEmailValid(emailController.text.trim()) &&
        passwordController.text.trim().length >= 6 &&
        confirmPasswordController.text.trim() == passwordController.text.trim() &&
        phoneController.text.trim().isNotEmpty &&
        cpfController.text.trim().isNotEmpty &&
        zipCodeController.text.trim().isNotEmpty &&
        cityController.text.trim().isNotEmpty &&
        neighborhoodController.text.trim().isNotEmpty &&
        streetController.text.trim().isNotEmpty &&
        numberController.text.trim().isNotEmpty &&
        birthDate != null;
  }

  bool _validateStep1() {
    return registrationDate != null;
  }

  bool _validateStep2() {
    return bioController.text.trim().isNotEmpty &&
        hourlyRateController.text.trim().isNotEmpty;
  }

  bool _validateStep3() {
    return true;
  }

  bool _validateStep4() {
    return specializations.isNotEmpty || services.isNotEmpty;
  }

  bool _validateStep5() {
    bool hasValidAvailability = false;

    availability.forEach((dia, dados) {
      final disponivel = dados['disponivel'] == true;
      final inicio = (dados['inicio'] ?? '').toString().trim();
      final fim = (dados['fim'] ?? '').toString().trim();

      if (disponivel && inicio.isNotEmpty && fim.isNotEmpty) {
        hasValidAvailability = true;
      }
    });

    return hasValidAvailability;
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateStep0();
      case 1:
        return _validateStep1();
      case 2:
        return _validateStep2();
      case 3:
        return _validateStep3();
      case 4:
        return _validateStep4();
      case 5:
        return _validateStep5();
      default:
        return false;
    }
  }

  void _next() {
    if (!_validateCurrentStep()) {
      _showErrorDialog('Preencha os campos obrigatórios desta etapa.');
      return;
    }

    if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  Future<void> _selectRegistrationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: registrationDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        registrationDate = picked;
      });
    }
  }

  Future<void> _saveProfessionalRegistrations(int caregiverId) async {
    try {
      await ServicoApi.post('/api/registro-profissional', {
        'cuidador_id': caregiverId,
        'crm': crmController.text.trim(),
        'crefito': crefitoController.text.trim(),
        'coren': corenController.text.trim(),
        'crp': crpController.text.trim(),
        'data_registro': registrationDate?.toIso8601String().split('T')[0],
        'status_registro': registrationStatus ?? 'Ativo',
      });
    } catch (_) {}
  }

  Future<void> _saveSpecializationsAndServices(int caregiverId) async {
    try {
      for (final specialization in specializations) {
        await ServicoApi.post('/api/cuidador/especialidade', {
          'cuidador_id': caregiverId,
          'especialidade': specialization,
        });
      }

      for (final service in services) {
        await ServicoApi.post('/api/cuidador/servico', {
          'cuidador_id': caregiverId,
          'servico': service,
        });
      }
    } catch (_) {}
  }

  Future<void> _saveAvailability(int caregiverId) async {
    try {
      final List<Map<String, dynamic>> disponibilidades = [];

      availability.forEach((dia, dados) {
        final disponivel = dados['disponivel'] == true;
        final inicio = (dados['inicio'] ?? '').toString().trim();
        final fim = (dados['fim'] ?? '').toString().trim();

        if (disponivel && inicio.isNotEmpty && fim.isNotEmpty) {
          disponibilidades.add({
            'dia_semana': dia,
            'data_inicio': inicio,
            'data_fim': fim,
            'observacoes': 'Disponível das $inicio às $fim',
            'recorrente': 1,
          });
        }
      });

      if (disponibilidades.isNotEmpty) {
        await ServicoApi.post('/api/cuidador/disponibilidade', {
          'cuidador_id': caregiverId,
          'disponibilidades': disponibilidades,
        });
      }
    } catch (_) {}
  }

  Future<void> _saveAdditionalData(int caregiverId) async {
    await _saveProfessionalRegistrations(caregiverId);
    await _saveSpecializationsAndServices(caregiverId);
    await _saveAvailability(caregiverId);
  }

  Future<void> _finish() async {
    if (!_validateStep0() ||
        !_validateStep1() ||
        !_validateStep2() ||
        !_validateStep3() ||
        !_validateStep4() ||
        !_validateStep5()) {
      _showErrorDialog('Preencha todos os campos obrigatórios.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> body = {
        'nome': nameController.text.trim(),
        'email': emailController.text.trim(),
        'senha': passwordController.text.trim(),
        'telefone': _onlyNumbers(phoneController.text.trim()),
        'cpf': _onlyNumbers(cpfController.text.trim()),
        'dataNascimento': birthDate?.toIso8601String().split('T')[0],
        'biografia': bioController.text.trim(),
        'fumante': smokingStatus,
        'temFilhos': hasChildren,
        'possuiCnh': hasLicense,
        'temCarro': hasCar,
        'valorHora': hourlyRateController.text.trim(),
        'cep': _onlyNumbers(zipCodeController.text.trim()),
        'rua': streetController.text.trim(),
        'numero': numberController.text.trim(),
        'bairro': neighborhoodController.text.trim(),
        'cidade': cityController.text.trim(),
        'complemento': complementController.text.trim(),
      };

      debugPrint('BODY CADASTRO CUIDADOR: $body');

      final response = await ServicoApi.post('/api/cuidador/cadastro', body);

      if (response['success'] == true) {
        final caregiverId = response['data']?['idCuidador'];

        if (caregiverId != null) {
          await _saveAdditionalData(caregiverId);
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          TelaSucesso.route,
          arguments: 'Cadastro do cuidador realizado com sucesso!',
        );
      } else {
        _showErrorDialog(
          'Erro no cadastro: ${response['message'] ?? 'Erro desconhecido'}',
        );
      }
    } catch (e) {
      _showErrorDialog('Erro no cadastro: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção'),
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

  Widget _buildRadioGroup({
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            Radio<String>(
              value: 'Sim',
              groupValue: value,
              onChanged: (v) => onChanged(v!),
            ),
            const Text('Sim'),
            const SizedBox(width: 20),
            Radio<String>(
              value: 'Não',
              groupValue: value,
              onChanged: (v) => onChanged(v!),
            ),
            const Text('Não'),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final isLast = _currentStep == 5;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _next,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(isLast ? 'Finalizar cadastro' : 'Continuar'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _prev,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Criar conta'),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) {
          setState(() {
            _currentStep = i;
          });
        },
        children: [
          _StepScaffold(
            index: 0,
            total: 6,
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    hintText: 'Digite seu nome completo',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    hintText: 'Digite seu e-mail',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    hintText: 'Digite sua senha',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',
                    hintText: 'Confirme sua senha',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: cpfController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    hintText: 'Digite seu CPF',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: 'Digite seu telefone',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: zipCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CEP',
                    hintText: 'Digite seu CEP',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'Cidade',
                    hintText: 'Digite sua cidade',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: neighborhoodController,
                  decoration: const InputDecoration(
                    labelText: 'Bairro',
                    hintText: 'Digite seu bairro',
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
                          labelText: 'Rua',
                          hintText: 'Nome da rua',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nº',
                          hintText: '123',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: complementController,
                  decoration: const InputDecoration(
                    labelText: 'Complemento',
                    hintText: 'Apto, casa, etc.',
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _selectBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data de nascimento',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      birthDate != null
                          ? DateFormat('dd/MM/yyyy').format(birthDate!)
                          : 'Selecione sua data de nascimento',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildBottomButton(),
              ],
            ),
          ),
          _StepScaffold(
            index: 1,
            total: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registros Profissionais',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'CRM (Médico)',
                  hint: 'Digite o número do CRM',
                  controller: crmController,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'CREFITO (Fisioterapeuta)',
                  hint: 'Digite o número do CREFITO',
                  controller: crefitoController,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'COREN (Enfermeiro)',
                  hint: 'Digite o número do COREN',
                  controller: corenController,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'CRP (Psicólogo)',
                  hint: 'Digite o número do CRP',
                  controller: crpController,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Data de Registro *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
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
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: registrationStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecione o status',
                  ),
                  items: ['Ativo', 'Inativo', 'Suspenso']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      registrationStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildBottomButton(),
              ],
            ),
          ),
          _StepScaffold(
            index: 2,
            total: 6,
            child: Column(
              children: [
                const Row(
                  children: [
                    CircleAvatar(radius: 28, child: Icon(Icons.person)),
                    SizedBox(width: 12),
                    Text('Adicionar Foto'),
                  ],
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Breve biografia',
                  hint: 'Escreva um pouco sobre você',
                  controller: bioController,
                ),
                const SizedBox(height: 10),
                LabeledField(
                  label: 'Valor por hora',
                  hint: 'Ex. R\$ 50,00',
                  controller: hourlyRateController,
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(value: true, onChanged: (_) {}),
                    const Expanded(child: Text('Li e aceito os Termos de Uso')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBottomButton(),
              ],
            ),
          ),
          _StepScaffold(
            index: 3,
            total: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informações Pessoais',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildRadioGroup(
                  title: 'Fumante:',
                  value: smokingStatus,
                  onChanged: (value) {
                    setState(() {
                      smokingStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildRadioGroup(
                  title: 'Tem filhos:',
                  value: hasChildren,
                  onChanged: (value) {
                    setState(() {
                      hasChildren = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildRadioGroup(
                  title: 'Possui CNH:',
                  value: hasLicense,
                  onChanged: (value) {
                    setState(() {
                      hasLicense = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildRadioGroup(
                  title: 'Tem carro:',
                  value: hasCar,
                  onChanged: (value) {
                    setState(() {
                      hasCar = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildBottomButton(),
              ],
            ),
          ),
          _StepScaffold(
            index: 4,
            total: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Especialidades',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableSpecializations
                      .map(
                        (spec) => FilterChip(
                          label: Text(spec['Nome'].toString()),
                          selected:
                              specializations.contains(spec['Nome'].toString()),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                specializations.add(spec['Nome'].toString());
                              } else {
                                specializations.remove(spec['Nome'].toString());
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Serviços',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableServices
                      .map(
                        (service) => FilterChip(
                          label: Text(service['Nome'].toString()),
                          selected: services.contains(service['Nome'].toString()),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                services.add(service['Nome'].toString());
                              } else {
                                services.remove(service['Nome'].toString());
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                _buildBottomButton(),
              ],
            ),
          ),
          _StepScaffold(
            index: 5,
            total: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Disponibilidade',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selecione seus horários disponíveis:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...availability.entries.map((entry) {
                  final dia = entry.key;
                  final dados = entry.value;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
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
                                value: dados['disponivel'] == true,
                                onChanged: (value) {
                                  setState(() {
                                    availability[dia]!['disponivel'] = value;
                                    if (!value) {
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
                                      availability[dia]!['inicio'] = value;
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
                                      availability[dia]!['fim'] = value;
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
                }),
                const SizedBox(height: 24),
                _buildBottomButton(),
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

  const _StepScaffold({
    required this.index,
    required this.total,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).padding.bottom + 60,
        ),
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