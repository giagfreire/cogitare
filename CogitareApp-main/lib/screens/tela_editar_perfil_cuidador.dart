import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';

class TelaEditarPerfilCuidador extends StatefulWidget {
  static const route = '/editar-perfil-cuidador';

  const TelaEditarPerfilCuidador({super.key});

  @override
  State<TelaEditarPerfilCuidador> createState() =>
      _TelaEditarPerfilCuidadorState();
}

class _TelaEditarPerfilCuidadorState extends State<TelaEditarPerfilCuidador> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final cpfController = TextEditingController();
  final cidadeController = TextEditingController();
  final biografiaController = TextEditingController();
  final valorHoraController = TextEditingController();

  final escolaridadeController = TextEditingController();
  final experienciaController = TextEditingController();
  final trabalhosController = TextEditingController();
  final diplomasController = TextEditingController();

  String? sexoSelecionado;
  DateTime? dataNascimento;

  bool _isLoading = true;
  bool _isSaving = false;
  int? _cuidadorId;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color fundo = Color(0xFFF6F4F8);

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
    escolaridadeController.dispose();
    experienciaController.dispose();
    trabalhosController.dispose();
    diplomasController.dispose();
    super.dispose();
  }

  int? _parseInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
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

  Future<int?> _getCuidadorIdLogado() async {
    final token = await ServicoAutenticacao.getToken();
    final userData = await ServicoAutenticacao.getUserData();
    final userType = await ServicoAutenticacao.getUserType();

    if (token != null && token.isNotEmpty) {
      ServicoApi.setToken(token);
    }

    if (userType != 'cuidador' || userData == null) return null;

    return _parseInt(
      userData['IdCuidador'] ??
          userData['idCuidador'] ??
          userData['cuidadorId'] ??
          userData['id'] ??
          userData['Id'],
    );
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
      setState(() => dataNascimento = picked);
    }
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final cuidadorId = await _getCuidadorIdLogado();

      if (cuidadorId == null) {
        throw Exception('Não foi possível identificar o cuidador logado.');
      }

      final response = await ServicoApi.get('/api/cuidador/$cuidadorId');

      if (response['success'] == true && response['data'] != null) {
        final data = Map<String, dynamic>.from(response['data']);

        nomeController.text = _textoSeguro(data['nome'] ?? data['Nome']);
        emailController.text = _textoSeguro(data['email'] ?? data['Email']);
        telefoneController.text = _textoSeguro(data['telefone'] ?? data['Telefone']);
        cpfController.text = _textoSeguro(data['cpf'] ?? data['Cpf']);
        cidadeController.text = _textoSeguro(data['cidade'] ?? data['Cidade']);
        biografiaController.text =
            _textoSeguro(data['biografia'] ?? data['Biografia']);
        valorHoraController.text =
            _textoSeguro(data['valorHora'] ?? data['ValorHora']);

        sexoSelecionado = _textoSeguro(data['sexo'] ?? data['Sexo']);
        if (sexoSelecionado!.isEmpty) sexoSelecionado = null;

        escolaridadeController.text =
            _textoSeguro(data['escolaridade'] ?? data['Escolaridade']);
        experienciaController.text = _textoSeguro(
          data['experienciaProfissional'] ?? data['ExperienciaProfissional'],
        );
        trabalhosController.text = _textoSeguro(
          data['trabalhosFeitos'] ?? data['TrabalhosFeitos'],
        );
        diplomasController.text = _textoSeguro(
          data['diplomasCertificados'] ?? data['DiplomasCertificados'],
        );

        final dataNascimentoTexto =
            _textoSeguro(data['dataNascimento'] ?? data['DataNascimento']);

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
      if (mounted) setState(() => _isLoading = false);
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
        dataNascimento == null ||
        sexoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha nome, telefone, CPF, sexo e data de nascimento.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final body = {
        'nome': nomeController.text.trim(),
        'telefone': _apenasNumeros(telefoneController.text.trim()),
        'cpf': _apenasNumeros(cpfController.text.trim()),
        'dataNascimento': dataNascimento!.toIso8601String().split('T')[0],
        'sexo': sexoSelecionado,
        'cidade': cidadeController.text.trim(),
        'biografia': biografiaController.text.trim(),
        'valorHora': valorHoraController.text.trim(),
        'escolaridade': escolaridadeController.text.trim(),
        'experienciaProfissional': experienciaController.text.trim(),
        'trabalhosFeitos': trabalhosController.text.trim(),
        'diplomasCertificados': diplomasController.text.trim(),
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
          SnackBar(content: Text(response['message'] ?? 'Erro ao atualizar perfil.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _tituloSecao(String texto) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: const TextStyle(
          color: roxo,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: roxo,
                    child: Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  _tituloSecao('Dados pessoais'),
                  const SizedBox(height: 12),

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

                  DropdownButtonFormField<String>(
                    value: sexoSelecionado,
                    decoration: const InputDecoration(labelText: 'Sexo'),
                    items: const [
                      DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
                      DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                    ],
                    onChanged: (value) {
                      setState(() => sexoSelecionado = value);
                    },
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

                  const SizedBox(height: 22),
                  _tituloSecao('Perfil profissional'),
                  const SizedBox(height: 12),

                  _campo(
                    controller: escolaridadeController,
                    label: 'Escolaridade',
                    hint: 'Ex: Ensino médio completo, Técnico em Enfermagem...',
                  ),
                  const SizedBox(height: 12),

                  _campo(
                    controller: experienciaController,
                    label: 'Experiência profissional',
                    hint: 'Conte sua experiência como cuidador(a)',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),

                  _campo(
                    controller: trabalhosController,
                    label: 'Trabalhos já feitos',
                    hint: 'Ex: cuidados com idosos, acompanhamento hospitalar...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),

                  _campo(
                    controller: diplomasController,
                    label: 'Diplomas e certificados',
                    hint: 'Ex: Cuidador de idosos, primeiros socorros...',
                    maxLines: 4,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
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