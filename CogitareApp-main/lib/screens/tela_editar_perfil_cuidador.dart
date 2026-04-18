import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class TelaEditarPerfilCuidador extends StatefulWidget {
  static const route = '/editar-perfil-cuidador';

  const TelaEditarPerfilCuidador({super.key});

  @override
  State<TelaEditarPerfilCuidador> createState() =>
      _TelaEditarPerfilCuidadorState();
}

class _TelaEditarPerfilCuidadorState extends State<TelaEditarPerfilCuidador> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController cidadeController = TextEditingController();
  final TextEditingController biografiaController = TextEditingController();
  final TextEditingController valorHoraController = TextEditingController();

  DateTime? dataNascimento;
  bool _isLoading = true;
  bool _isSaving = false;
  int? _cuidadorId;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    cpfController.dispose();
    cidadeController.dispose();
    biografiaController.dispose();
    valorHoraController.dispose();
    super.dispose();
  }

  String _textoSeguro(dynamic valor) {
    if (valor == null) return '';
    final texto = valor.toString().trim();
    if (texto.toLowerCase() == 'null') return '';
    return texto;
  }

  String _apenasNumeros(String valor) {
    return valor.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _selecionarDataNascimento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          dataNascimento ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        dataNascimento = picked;
      });
    }
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cuidadorId = await SessionService.getCuidadorId();

      if (cuidadorId == null) {
        throw Exception('Não foi possível identificar o cuidador logado.');
      }

      final response = await ServicoApi.get('/api/cuidador/$cuidadorId');

      if (response['success'] == true && response['data'] != null) {
        final data = Map<String, dynamic>.from(response['data']);

   nomeController.text = _textoSeguro(data['nome']);
emailController.text = _textoSeguro(data['email']);
telefoneController.text = _textoSeguro(data['telefone']);
cpfController.text = _textoSeguro(data['cpf']);
cidadeController.text = _textoSeguro(data['cidade']);
biografiaController.text = _textoSeguro(data['biografia']);
valorHoraController.text = _textoSeguro(data['valorHora']);

final dataNascimentoTexto = _textoSeguro(data['dataNascimento']);
        if (dataNascimentoTexto.isNotEmpty) {
          try {
            dataNascimento = DateTime.parse(dataNascimentoTexto);
          } catch (_) {}
        }

        _cuidadorId = cuidadorId;
      } else {
        throw Exception(response['message'] ?? 'Erro ao carregar perfil.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e')),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _salvar() async {
    if (_cuidadorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuidador não identificado.')),
      );
      return;
    }

    if (nomeController.text.trim().isEmpty ||
        telefoneController.text.trim().isEmpty ||
        cpfController.text.trim().isEmpty ||
        dataNascimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha nome, telefone, CPF e data de nascimento.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final body = {
        'nome': nomeController.text.trim(),
        'telefone': _apenasNumeros(telefoneController.text.trim()),
        'cpf': _apenasNumeros(cpfController.text.trim()),
        'dataNascimento': dataNascimento!.toIso8601String().split('T')[0],

        // campos extras
        'cidade': cidadeController.text.trim(),
        'biografia': biografiaController.text.trim(),
        'valorHora': valorHoraController.text.trim(),
      };

      final response = await ServicoApi.put('/api/cuidador/$_cuidadorId', body);

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Erro ao atualizar perfil.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar perfil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    child: Icon(Icons.person, size: 36),
                  ),
                  const SizedBox(height: 20),

                  _campo(
                    controller: nomeController,
                    label: 'Nome completo',
                    hint: 'Digite seu nome',
                  ),
                  const SizedBox(height: 12),

                  _campo(
                    controller: emailController,
                    label: 'E-mail',
                    hint: 'Seu e-mail',
                    keyboard: TextInputType.emailAddress,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),

                  _campo(
                    controller: telefoneController,
                    label: 'Telefone',
                    hint: 'Digite seu telefone',
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  _campo(
                    controller: cpfController,
                    label: 'CPF',
                    hint: 'Digite seu CPF',
                    keyboard: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _selecionarDataNascimento,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de nascimento',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        dataNascimento != null
                            ? DateFormat('dd/MM/yyyy').format(dataNascimento!)
                            : 'Selecione sua data de nascimento',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _campo(
                    controller: cidadeController,
                    label: 'Cidade',
                    hint: 'Digite sua cidade',
                  ),
                  const SizedBox(height: 12),

                  _campo(
                    controller: valorHoraController,
                    label: 'Valor por hora',
                    hint: 'Ex: 50,00',
                    keyboard: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  _campo(
                    controller: biografiaController,
                    label: 'Biografia',
                    hint: 'Fale um pouco sobre você',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _salvar,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar alterações'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}