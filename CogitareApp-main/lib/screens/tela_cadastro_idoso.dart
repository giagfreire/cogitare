import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/widgets_comuns.dart';
import '../models/idoso.dart';
import '../services/api_idoso.dart';
import '../utils/form_validators.dart';
import 'tela_sucesso.dart';

class TelaCadastroIdoso extends StatefulWidget {
  static const route = '/cadastro-idoso';
  const TelaCadastroIdoso({super.key});

  @override
  State<TelaCadastroIdoso> createState() => _TelaCadastroIdosoState();
}

class _TelaCadastroIdosoState extends State<TelaCadastroIdoso> {
  final page = PageController();
  int index = 0;
  bool isLoading = false;
  int? guardianId;

  final nameController = TextEditingController();
  final medicalConditions = <String>{"Diabetes"};
  final restrictionsController = TextEditingController();
  final medicalCareController = TextEditingController();
  final extraDescriptionController = TextEditingController();
  bool specialCareNeeded = false;
  final careList = <String>{"Higiene", "Companhia", "Medicação"};
  final serviceType = <int>{};
  final availability = <String, bool>{"Seg Manhã": false, "Sex Noite": false};
  DateTime? birthDate;
  String? gender;
  int? mobilityId = 1; // Default: Independente
  int? autonomyLevelId = 1; // Default: Totalmente independente
  String? _selectedImagePath;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    // Receive guardian ID passed as argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      print('Arguments received: $args'); // Debug
      print('Arguments type: ${args.runtimeType}'); // Debug
      if (args is int) {
        setState(() {
          guardianId = args;
        });
        print('Guardian ID set to: $guardianId'); // Debug
      } else if (args is String) {
        // Tentar converter string para int
        final intValue = int.tryParse(args);
        if (intValue != null) {
          setState(() {
            guardianId = intValue;
          });
          print('Guardian ID converted from string to: $guardianId'); // Debug
        } else {
          print('Could not convert string argument to int: $args'); // Debug
        }
      } else {
        print(
            'No guardian ID received or invalid type: ${args.runtimeType}'); // Debug
      }
    });
  }

  // Validations
  // Usar FormValidators para validações
  String? _validateName(String? value) => FormValidators.validateName(value);

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 70)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != birthDate) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    // Simulação de seleção de imagem
    // Em um app real, aqui seria implementada a seleção real de imagem
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Foto'),
        content: const Text(
            'Funcionalidade de seleção de foto será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Simular seleção de imagem
    setState(() {
      _selectedImagePath = "imagem_simulada.jpg";
    });
  }

  bool _validateForm() {
    if (index == 0) {
      // Validação da primeira etapa
      final nameValid = _validateName(nameController.text) == null;
      final birthDateValid = birthDate != null;
      final genderValid = gender != null;

      print('Form validation (Step 1):'); // Debug
      print('  Name valid: $nameValid'); // Debug
      print('  Birth date valid: $birthDateValid'); // Debug
      print('  Gender valid: $genderValid'); // Debug

      return nameValid && birthDateValid && genderValid;
    } else {
      // Validação da segunda etapa
      print('Form validation (Step 2):'); // Debug
      print('  Terms accepted: $_termsAccepted'); // Debug

      return _termsAccepted;
    }
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

  Future<void> _finish() async {
    if (!_validateForm()) {
      _showErrorDialog(
          'Por favor, preencha todos os campos obrigatórios corretamente.');
      return;
    }

    // Debug: Verificar se temos guardianId
    print('DEBUG: guardianId atual: $guardianId');

    final finalGuardianId;
    if (guardianId == null) {
      // Usar ID válido conhecido para teste (ID 22 que existe no banco)
      print('DEBUG: guardianId é null, usando ID 22 para teste');
      finalGuardianId = 22;
    } else {
      finalGuardianId = guardianId!;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create elder
      final elder = Idoso(
        guardianId: finalGuardianId,
        mobilityId: mobilityId,
        autonomyLevelId: autonomyLevelId,
        name: nameController.text,
        birthDate: birthDate,
        gender: gender,
        medicalCare: medicalCareController.text.isNotEmpty
            ? medicalCareController.text
            : null,
        extraDescription: extraDescriptionController.text.isNotEmpty
            ? extraDescriptionController.text
            : null,
        selectedServices: null, // Não usado mais na segunda etapa
        availability: null, // Não usado mais na segunda etapa
      );

      // Create elder
      final response = await ApiIdoso.create(elder);

      if (response['success'] == true) {
        Navigator.pushReplacementNamed(context, TelaSucesso.route,
            arguments: "Cadastro do idoso realizado com sucesso!");
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

  void _next() => page.nextPage(
      duration: const Duration(milliseconds: 250), curve: Curves.ease);
  void _prev() => page.previousPage(
      duration: const Duration(milliseconds: 250), curve: Curves.ease);

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
        title: const Text("Dados do Idoso"),
      ),
      body: PageView(
        controller: page,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => index = i),
        children: [
          _Step(
              index: 0,
              total: 2,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Nome Completo do Idoso",
                      hintText: "Digite o nome completo",
                      errorText: _validateName(nameController.text) != null &&
                              nameController.text.isNotEmpty
                          ? _validateName(nameController.text)
                          : null,
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Data de Nascimento *",
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        birthDate != null
                            ? DateFormat('dd/MM/yyyy').format(birthDate!)
                            : "Selecione a data de nascimento",
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: const InputDecoration(
                      labelText: "Sexo *",
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "Masculino", child: Text("Masculino")),
                      DropdownMenuItem(
                          value: "Feminino", child: Text("Feminino")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        gender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: mobilityId,
                    decoration: const InputDecoration(
                      labelText: "Nível de Mobilidade",
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Independente")),
                      DropdownMenuItem(
                          value: 2, child: Text("Cadeira de rodas")),
                      DropdownMenuItem(value: 3, child: Text("Andador")),
                      DropdownMenuItem(value: 4, child: Text("Bengala")),
                      DropdownMenuItem(value: 5, child: Text("Auxílio total")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        mobilityId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: autonomyLevelId,
                    decoration: const InputDecoration(
                      labelText: "Nível de Autonomia",
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 1, child: Text("Totalmente independente")),
                      DropdownMenuItem(
                          value: 2, child: Text("Parcialmente independente")),
                      DropdownMenuItem(
                          value: 3,
                          child: Text("Dependente de auxílio moderado")),
                      DropdownMenuItem(
                          value: 4,
                          child: Text("Dependente de auxílio intensivo")),
                      DropdownMenuItem(
                          value: 5, child: Text("Totalmente dependente")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        autonomyLevelId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: medicalCareController,
                    decoration: const InputDecoration(
                      labelText: "Cuidados Médicos",
                      hintText: "Descreva os cuidados médicos necessários",
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: extraDescriptionController,
                    decoration: const InputDecoration(
                      labelText: "Descrição Extra",
                      hintText: "Informações adicionais sobre o idoso",
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: _validateForm() ? _next : null,
                          child: const Text("Continuar"))),
                ],
              )),
          _Step(
              index: 1,
              total: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção de Foto
                  const SectionTitle("Foto do Idoso"),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        child: _selectedImagePath == null
                            ? const Icon(Icons.person,
                                size: 40, color: Colors.grey)
                            : const Icon(Icons.check_circle,
                                size: 40, color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedImagePath != null
                                  ? "Foto selecionada"
                                  : "Nenhuma foto selecionada",
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedImagePath != null
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.camera_alt),
                              label: Text(_selectedImagePath != null
                                  ? "Alterar Foto"
                                  : "Selecionar Foto"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Seção de Termos de Uso
                  const SectionTitle("Termos de Uso"),
                  Card(
                    child: ExpansionTile(
                      title: const Text(
                        "Termos de Uso e Política de Privacidade",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _termsAccepted
                            ? "Termos aceitos"
                            : "Clique para ler os termos",
                        style: TextStyle(
                          color: _termsAccepted
                              ? Colors.green[700]
                              : Colors.grey[600],
                        ),
                      ),
                      leading: Icon(
                        _termsAccepted
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: _termsAccepted ? Colors.green : Colors.grey,
                      ),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "1. Aceitação dos Termos",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Ao utilizar este aplicativo, você concorda em cumprir e estar sujeito a estes Termos de Uso.",
                              ),
                              SizedBox(height: 16),
                              Text(
                                "2. Uso dos Dados",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Seus dados pessoais serão utilizados exclusivamente para fornecer os serviços de cuidados ao idoso, respeitando todas as normas de privacidade e segurança.",
                              ),
                              SizedBox(height: 16),
                              Text(
                                "3. Responsabilidades",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Você é responsável por fornecer informações verdadeiras e atualizadas sobre o idoso sob sua responsabilidade.",
                              ),
                              SizedBox(height: 16),
                              Text(
                                "4. Privacidade",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Comprometemo-nos a proteger a privacidade e segurança de todos os dados fornecidos, seguindo as melhores práticas de segurança da informação.",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Checkbox de Aceite
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        onChanged: (value) {
                          setState(() {
                            _termsAccepted = value ?? false;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      const Expanded(
                        child: Text(
                          "Li e aceito os Termos de Uso e Política de Privacidade",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Botão de Cadastrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _termsAccepted && !isLoading ? _finish : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Cadastrar",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int index;
  final int total;
  final Widget child;
  const _Step({required this.index, required this.total, required this.child});

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
