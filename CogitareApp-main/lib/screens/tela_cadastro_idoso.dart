import 'package:flutter/material.dart';

import '../models/idoso.dart';
import '../services/api_idoso.dart';

class TelaCadastroIdoso extends StatefulWidget {
  static const String route = '/cadastro-idoso';

  final Idoso? idosoParaEditar;

  const TelaCadastroIdoso({
    super.key,
    this.idosoParaEditar,
  });

  @override
  State<TelaCadastroIdoso> createState() => _TelaCadastroIdosoState();
}

class _TelaCadastroIdosoState extends State<TelaCadastroIdoso> {
  final _formKey = GlobalKey<FormState>();

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF8F6FA);

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();
  final TextEditingController _condicoesMedicasController =
      TextEditingController();
  final TextEditingController _observacoesController =
      TextEditingController();

  final TextEditingController _nomeMedicamentoController =
      TextEditingController();
  final TextEditingController _horarioMedicamentoController =
      TextEditingController();

  bool _loading = false;

  String? _sexo;
  int? _mobilidadeId;

  bool _usaMedicacao = false;
  bool _cuidadorAplicaMedicacao = false;

  bool _precisaCompanhia = false;

  bool _precisaBanho = false;
  bool _precisaAjudaBanho = false;

  bool _precisaAjudaAlimentacao = false;

  final List<Map<String, dynamic>> _mobilidades = [
    {'id': 1, 'nome': 'Anda normalmente'},
    {'id': 2, 'nome': 'Usa bengala'},
    {'id': 3, 'nome': 'Usa andador'},
    {'id': 4, 'nome': 'Usa cadeira de rodas'},
    {'id': 5, 'nome': 'Acamado'},
  ];

  @override
  void initState() {
    super.initState();

    final idoso = widget.idosoParaEditar;

   if (idoso != null) {
  _nomeController.text = idoso.name;
  _dataNascimentoController.text =
      idoso.birthDate?.toIso8601String().split('T').first ?? '';

  _sexo = idoso.gender;
  _mobilidadeId = idoso.mobilityId;

  _condicoesMedicasController.text = idoso.medicalCare ?? '';
  _observacoesController.text = idoso.extraDescription ?? '';

  _usaMedicacao = idoso.usaMedicacao == 'Sim';
  _nomeMedicamentoController.text = idoso.medicacaoDetalhes ?? '';

  _precisaBanho = idoso.precisaBanho == 'Sim';
  _precisaAjudaAlimentacao = idoso.precisaAlimentacao == 'Sim';
  _precisaCompanhia = idoso.precisaAcompanhamento == 'Sim';

  _cuidadorAplicaMedicacao =
      idoso.medicacaoDetalhes != null &&
      idoso.medicacaoDetalhes!.trim().isNotEmpty;
}
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dataNascimentoController.dispose();
    _condicoesMedicasController.dispose();
    _observacoesController.dispose();
    _nomeMedicamentoController.dispose();
    _horarioMedicamentoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime(1950),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (data != null) {
      setState(() {
        _dataNascimentoController.text =
            '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _salvarIdoso() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);

  try {
    final editando = widget.idosoParaEditar != null;

    final detalhesMedicacao = [
      if (_nomeMedicamentoController.text.trim().isNotEmpty)
        'Medicamento: ${_nomeMedicamentoController.text.trim()}',
      if (_horarioMedicamentoController.text.trim().isNotEmpty)
        'Horário: ${_horarioMedicamentoController.text.trim()}',
    ].join(' | ');

    final idoso = Idoso(
      id: widget.idosoParaEditar?.id,
      guardianId: widget.idosoParaEditar?.guardianId,
      name: _nomeController.text.trim(),
      birthDate: DateTime.tryParse(_dataNascimentoController.text.trim()),
      gender: _sexo,
      mobilityId: _mobilidadeId,
      autonomyLevelId: null,
      medicalCare: _condicoesMedicasController.text.trim(),
      extraDescription: _observacoesController.text.trim(),
      usaMedicacao: _usaMedicacao ? 'Sim' : 'Não',
      medicacaoDetalhes: detalhesMedicacao.isEmpty ? null : detalhesMedicacao,
      precisaBanho: _precisaBanho ? 'Sim' : 'Não',
      banhoDetalhes: _precisaAjudaBanho ? 'Precisa de ajuda com banho' : null,
      precisaAlimentacao: _precisaAjudaAlimentacao ? 'Sim' : 'Não',
      alimentacaoDetalhes:
          _precisaAjudaAlimentacao ? 'Precisa de ajuda com alimentação' : null,
      precisaAcompanhamento: _precisaCompanhia ? 'Sim' : 'Não',
      acompanhamentoDetalhes:
          _precisaCompanhia ? 'Precisa de companhia/acompanhamento' : null,
    );

    final response = editando
        ? await ApiIdoso.update(widget.idosoParaEditar!.id!, idoso)
        : await ApiIdoso.create(idoso);

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editando
                ? 'Dados do idoso atualizados com sucesso!'
                : 'Idoso cadastrado com sucesso!',
          ),
          backgroundColor: roxo,
        ),
      );

      Navigator.pop(context, true);
    } else {
      throw Exception(response['message'] ?? 'Erro ao salvar idoso.');
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: rosa,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

  Widget _tituloSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 26,
            decoration: BoxDecoration(
              color: rosa,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: roxo,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: roxo),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: roxo),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: roxo.withOpacity(0.18)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: rosa, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: roxo),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: roxo),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: roxo.withOpacity(0.18)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: rosa, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _simNao({
    required String pergunta,
    required bool valor,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roxo.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pergunta,
            style: const TextStyle(
              color: roxo,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _botaoOpcao(
                  texto: 'Sim',
                  selecionado: valor == true,
                  onTap: () => onChanged(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _botaoOpcao(
                  texto: 'Não',
                  selecionado: valor == false,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botaoOpcao({
    required String texto,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado ? rosa : fundo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? rosa : roxo.withOpacity(0.18),
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: selecionado ? Colors.white : roxo,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _cardAviso(String texto) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: verde.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: verde.withOpacity(0.8)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: roxo,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _secaoMedicacao() {
    return Column(
      children: [
        _simNao(
          pergunta: 'O idoso usa medicação?',
          valor: _usaMedicacao,
          onChanged: (value) {
            setState(() {
              _usaMedicacao = value;

              if (!value) {
                _cuidadorAplicaMedicacao = false;
                _nomeMedicamentoController.clear();
                _horarioMedicamentoController.clear();
              }
            });
          },
        ),
        if (_usaMedicacao)
          _simNao(
            pergunta: 'O cuidador vai aplicar/dar essa medicação?',
            valor: _cuidadorAplicaMedicacao,
            onChanged: (value) {
              setState(() {
                _cuidadorAplicaMedicacao = value;

                if (!value) {
                  _nomeMedicamentoController.clear();
                  _horarioMedicamentoController.clear();
                }
              });
            },
          ),
        if (_usaMedicacao && _cuidadorAplicaMedicacao) ...[
          _campoTexto(
            controller: _nomeMedicamentoController,
            label: 'Nome do medicamento',
            icon: Icons.medication,
            validator: (value) {
              if (_usaMedicacao &&
                  _cuidadorAplicaMedicacao &&
                  (value == null || value.trim().isEmpty)) {
                return 'Informe o nome do medicamento';
              }
              return null;
            },
          ),
          _campoTexto(
            controller: _horarioMedicamentoController,
            label: 'Horário do medicamento',
            icon: Icons.access_time,
            validator: (value) {
              if (_usaMedicacao &&
                  _cuidadorAplicaMedicacao &&
                  (value == null || value.trim().isEmpty)) {
                return 'Informe o horário do medicamento';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _secaoNecessidades() {
    return Column(
      children: [
        _simNao(
          pergunta: 'Precisa de companhia?',
          valor: _precisaCompanhia,
          onChanged: (value) {
            setState(() => _precisaCompanhia = value);
          },
        ),
        _simNao(
          pergunta: 'Precisa de banho?',
          valor: _precisaBanho,
          onChanged: (value) {
            setState(() {
              _precisaBanho = value;

              if (!value) {
                _precisaAjudaBanho = false;
              }
            });
          },
        ),
        if (_precisaBanho)
          _simNao(
            pergunta: 'Precisa de ajuda com o banho?',
            valor: _precisaAjudaBanho,
            onChanged: (value) {
              setState(() => _precisaAjudaBanho = value);
            },
          ),
        _simNao(
          pergunta: 'Precisa de ajuda com alimentação?',
          valor: _precisaAjudaAlimentacao,
          onChanged: (value) {
            setState(() => _precisaAjudaAlimentacao = value);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool editando = widget.idosoParaEditar != null;

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(editando ? 'Editar idoso' : 'Cadastro do idoso'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _cardAviso(
                  'Preencha as informações principais do idoso para encontrar o cuidador ideal.',
                ),

                _tituloSecao('Dados do idoso'),

                _campoTexto(
                  controller: _nomeController,
                  label: 'Nome e sobrenome do idoso',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do idoso';
                    }
                    return null;
                  },
                ),

                _campoTexto(
                  controller: _dataNascimentoController,
                  label: 'Data de nascimento',
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: _selecionarData,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe a data de nascimento';
                    }
                    return null;
                  },
                ),

                _dropdown<String>(
                  label: 'Sexo do idoso',
                  icon: Icons.wc,
                  value: _sexo,
                  items: const [
                    DropdownMenuItem(
                      value: 'Feminino',
                      child: Text('Feminino'),
                    ),
                    DropdownMenuItem(
                      value: 'Masculino',
                      child: Text('Masculino'),
                    ),
                    DropdownMenuItem(
                      value: 'Outro',
                      child: Text('Outro'),
                    ),
                    DropdownMenuItem(
                      value: 'Prefiro não informar',
                      child: Text('Prefiro não informar'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _sexo = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione o sexo';
                    }
                    return null;
                  },
                ),

                _tituloSecao('Saúde e mobilidade'),

                _campoTexto(
                  controller: _condicoesMedicasController,
                  label: 'Condições médicas',
                  icon: Icons.medical_services,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe as condições médicas';
                    }
                    return null;
                  },
                ),

                _dropdown<int>(
                  label: 'Mobilidade',
                  icon: Icons.accessible,
                  value: _mobilidadeId,
                  items: _mobilidades.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text(item['nome']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _mobilidadeId = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione a mobilidade';
                    }
                    return null;
                  },
                ),

                _tituloSecao('Medicação'),

                _secaoMedicacao(),

                _tituloSecao('Observações importantes'),

                _campoTexto(
                  controller: _observacoesController,
                  label: 'Observações importantes',
                  icon: Icons.notes,
                  maxLines: 4,
                ),

                _tituloSecao('Necessidades do idoso'),

                _secaoNecessidades(),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _salvarIdoso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rosa,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: rosa.withOpacity(0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            editando ? 'Salvar alterações' : 'Cadastrar idoso',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}