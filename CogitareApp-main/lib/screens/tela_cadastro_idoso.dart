import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/idoso.dart';
import '../services/api_idoso.dart';
import '../utils/form_validators.dart';
import '../widgets/widgets_comuns.dart';
import 'tela_sucesso.dart';

class TelaCadastroIdoso extends StatefulWidget {
  static const route = '/cadastro-idoso';

  const TelaCadastroIdoso({super.key});

  @override
  State<TelaCadastroIdoso> createState() => _TelaCadastroIdosoState();
}

class _TelaCadastroIdosoState extends State<TelaCadastroIdoso> {
  final PageController page = PageController();

  int index = 0;
  bool isLoading = false;
  int? guardianId;

  final nameController = TextEditingController();
  final medicalCareController = TextEditingController();
  final extraDescriptionController = TextEditingController();
  final photoUrlController = TextEditingController();

  DateTime? birthDate;
  String? gender;
  int? mobilityId = 1;
  int? autonomyLevelId = 1;

  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is int) {
        setState(() {
          guardianId = args;
        });
      } else if (args is String) {
        final parsed = int.tryParse(args);
        if (parsed != null) {
          setState(() {
            guardianId = parsed;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    page.dispose();
    nameController.dispose();
    medicalCareController.dispose();
    extraDescriptionController.dispose();
    photoUrlController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) => FormValidators.validateName(value);

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = birthDate ?? DateTime(now.year - 70, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Selecione a data de nascimento',
    );

    if (picked != null) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  bool _validateForm() {
    if (index == 0) {
      final nameValid = _validateName(nameController.text) == null;
      final birthDateValid = birthDate != null;
      final genderValid = gender != null;

      return nameValid && birthDateValid && genderValid;
    } else {
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
        'Por favor, preencha todos os campos obrigatórios corretamente.',
      );
      return;
    }

    final int finalGuardianId = guardianId ?? 22;

    setState(() {
      isLoading = true;
    });

    try {
      final elder = Idoso(
        guardianId: finalGuardianId,
        mobilityId: mobilityId,
        autonomyLevelId: autonomyLevelId,
        name: nameController.text.trim(),
        birthDate: birthDate,
        gender: gender,
        medicalCare: medicalCareController.text.trim().isNotEmpty
            ? medicalCareController.text.trim()
            : null,
        extraDescription: extraDescriptionController.text.trim().isNotEmpty
            ? extraDescriptionController.text.trim()
            : null,
        photoUrl: photoUrlController.text.trim().isNotEmpty
            ? photoUrlController.text.trim()
            : null,
        selectedServices: null,
        availability: null,
      );

      final response = await ApiIdoso.create(elder);

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.pushReplacementNamed(
          context,
          TelaSucesso.route,
          arguments: "Cadastro do idoso realizado com sucesso!",
        );
      } else {
        _showErrorDialog(
          'Erro no cadastro: ${response['message'] ?? 'Erro desconhecido'}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Erro no cadastro: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _next() {
    page.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
    );
  }

  void _prev() {
    page.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      errorText: errorText,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f8fc),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (index == 0) {
              Navigator.pop(context);
            } else {
              _prev();
            }
          },
        ),
        title: const Text("Dados do Idoso"),
        centerTitle: true,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informações principais',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Preencha os dados do idoso com atenção para criar um perfil mais completo.',
                ),
                const SizedBox(height: 18),
                _buildCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: _inputDecoration(
                          label: "Nome completo do idoso",
                          hint: "Digite nome e sobrenome",
                          errorText: _validateName(nameController.text) != null &&
                                  nameController.text.isNotEmpty
                              ? _validateName(nameController.text)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            label: "Data de nascimento *",
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            birthDate != null
                                ? DateFormat('dd/MM/yyyy').format(birthDate!)
                                : "Selecione a data de nascimento",
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: gender,
                        decoration: _inputDecoration(label: "Sexo *"),
                        items: const [
                          DropdownMenuItem(
                            value: "Masculino",
                            child: Text("Masculino"),
                          ),
                          DropdownMenuItem(
                            value: "Feminino",
                            child: Text("Feminino"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            gender = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        initialValue: mobilityId,
                        decoration: _inputDecoration(label: "Nível de mobilidade"),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text("Independente")),
                          DropdownMenuItem(value: 2, child: Text("Cadeira de rodas")),
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
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        initialValue: autonomyLevelId,
                        decoration: _inputDecoration(label: "Nível de autonomia"),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text("Totalmente independente")),
                          DropdownMenuItem(value: 2, child: Text("Parcialmente independente")),
                          DropdownMenuItem(value: 3, child: Text("Dependente de auxílio moderado")),
                          DropdownMenuItem(value: 4, child: Text("Dependente de auxílio intensivo")),
                          DropdownMenuItem(value: 5, child: Text("Totalmente dependente")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            autonomyLevelId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: medicalCareController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          label: "Cuidados médicos",
                          hint: "Ex.: medicação, alimentação assistida, pressão, diabetes...",
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: extraDescriptionController,
                        maxLines: 4,
                        decoration: _inputDecoration(
                          label: "Descrição extra",
                          hint: "Ex.: rotina, preferências, observações importantes, restrições ou cuidados especiais",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _validateForm() ? _next : null,
                    child: const Text("Continuar"),
                  ),
                ),
              ],
            ),
          ),
          _Step(
            index: 1,
            total: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto e finalização do cadastro',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Você pode colar o link de uma foto e confirmar os termos para concluir o cadastro.',
                ),
                const SizedBox(height: 18),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle("Foto do idoso"),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: photoUrlController,
                        decoration: _inputDecoration(
                          label: "Link da foto (opcional)",
                          hint: "https://...",
                          suffixIcon: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle("Termos de uso"),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 0,
                        color: Colors.grey.shade50,
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
                            _termsAccepted ? Icons.check_circle : Icons.info_outline,
                            color: _termsAccepted ? Colors.green : Colors.grey,
                          ),
                          children: const [
                            Padding(
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
                                    "Seus dados pessoais serão utilizados exclusivamente para fornecer os serviços de cuidados ao idoso, respeitando as normas de privacidade e segurança.",
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _termsAccepted && !isLoading ? _finish : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            "Cadastrar",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int index;
  final int total;
  final Widget child;

  const _Step({
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