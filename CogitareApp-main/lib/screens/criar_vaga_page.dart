import 'package:flutter/material.dart';
import '../services/api_responsavel.dart';

class CriarVagaPage extends StatefulWidget {
  const CriarVagaPage({super.key});

  @override
  State<CriarVagaPage> createState() => _CriarVagaPageState();
}

class _CriarVagaPageState extends State<CriarVagaPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _bairroController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime? _dataSelecionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  String? _turno;
  bool _salvando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _cidadeController.dispose();
    _bairroController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final agora = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? agora,
      firstDate: DateTime(agora.year, agora.month, agora.day),
      lastDate: DateTime(2035),
    );

    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _selecionarHora(bool inicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: inicio
          ? (_horaInicio ?? TimeOfDay.now())
          : (_horaFim ?? TimeOfDay.now()),
    );

    if (hora != null) {
      setState(() {
        if (inicio) {
          _horaInicio = hora;
        } else {
          _horaFim = hora;
        }
      });
    }
  }

  bool _horariosValidos() {
    if (_horaInicio == null || _horaFim == null) return false;

    final inicioMin = _horaInicio!.hour * 60 + _horaInicio!.minute;
    final fimMin = _horaFim!.hour * 60 + _horaFim!.minute;

    return fimMin > inicioMin;
  }

  String _formatarData(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  String _formatarHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:'
        '${hora.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _salvarVaga() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataSelecionada == null) {
      _mostrarErro('Selecione a data do serviço');
      return;
    }

    if (_horaInicio == null || _horaFim == null) {
      _mostrarErro('Selecione os horários de início e fim');
      return;
    }

    if (!_horariosValidos()) {
      _mostrarErro('A hora final deve ser maior que a hora inicial');
      return;
    }

    if (_turno == null || _turno!.isEmpty) {
      _mostrarErro('Selecione o turno');
      return;
    }

    setState(() => _salvando = true);

    final valor =
        double.tryParse(_valorController.text.trim().replaceAll(',', '.')) ?? 0;

    final descricaoFinal = '''
${_descricaoController.text.trim()}

Turno: $_turno
Bairro: ${_bairroController.text.trim()}
Observações: ${_observacoesController.text.trim().isEmpty ? 'Não informado' : _observacoesController.text.trim()}
''';

    final response = await ApiResponsavel.criarVaga(
      titulo: _tituloController.text.trim(),
      descricao: descricaoFinal,
      cidade: _cidadeController.text.trim(),
      dataServico: _formatarData(_dataSelecionada!),
      horaInicio: _formatarHora(_horaInicio!),
      horaFim: _formatarHora(_horaFim!),
      valor: valor,
    );

    if (!mounted) return;
    setState(() => _salvando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message'] ?? 'Operação concluída'),
        backgroundColor:
            response['success'] == true ? Colors.green : Colors.red,
      ),
    );

    if (response['success'] == true) {
      Navigator.pop(context, true);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  InputDecoration _decoracao({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.07),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _campoDataHora({
    required String titulo,
    required String valor,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: _decoracao(label: titulo, suffixIcon: Icon(icon)),
          child: Text(valor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f8fc),
      appBar: AppBar(
        title: const Text('Criar vaga'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Nova oportunidade de cuidado',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Preencha os dados abaixo para publicar uma vaga mais completa e atrativa.',
              ),
              const SizedBox(height: 18),
              _card(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tituloController,
                      decoration: _decoracao(
                        label: 'Título da vaga',
                        hint: 'Ex.: Cuidador para acompanhamento diário',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o título';
                        }
                        if (value.trim().length < 5) {
                          return 'Digite um título mais completo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descricaoController,
                      maxLines: 4,
                      decoration: _decoracao(
                        label: 'Descrição principal',
                        hint: 'Explique o que será necessário no cuidado',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a descrição';
                        }
                        if (value.trim().length < 15) {
                          return 'Descreva melhor a necessidade';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _cidadeController,
                      decoration: _decoracao(
                        label: 'Cidade',
                        hint: 'Ex.: São Caetano do Sul',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a cidade';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bairroController,
                      decoration: _decoracao(
                        label: 'Bairro',
                        hint: 'Ex.: Centro',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o bairro';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _turno,
                      decoration: _decoracao(label: 'Turno'),
                      items: const [
                        DropdownMenuItem(value: 'Manhã', child: Text('Manhã')),
                        DropdownMenuItem(value: 'Tarde', child: Text('Tarde')),
                        DropdownMenuItem(value: 'Noite', child: Text('Noite')),
                        DropdownMenuItem(
                          value: 'Integral',
                          child: Text('Integral'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _turno = value),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _campoDataHora(
                          titulo: 'Data',
                          valor: _dataSelecionada == null
                              ? 'Selecionar'
                              : _formatarData(_dataSelecionada!),
                          onTap: _selecionarData,
                          icon: Icons.calendar_today,
                        ),
                        const SizedBox(width: 12),
                        _campoDataHora(
                          titulo: 'Início',
                          valor: _horaInicio == null
                              ? 'Selecionar'
                              : _horaInicio!.format(context),
                          onTap: () => _selecionarHora(true),
                          icon: Icons.access_time,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _campoDataHora(
                      titulo: 'Fim',
                      valor: _horaFim == null
                          ? 'Selecionar'
                          : _horaFim!.format(context),
                      onTap: () => _selecionarHora(false),
                      icon: Icons.access_time_filled,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _valorController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _decoracao(
                        label: 'Valor do serviço',
                        hint: 'Ex.: 180,00',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o valor';
                        }
                        final numero = double.tryParse(
                          value.trim().replaceAll(',', '.'),
                        );
                        if (numero == null || numero <= 0) {
                          return 'Informe um valor válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _observacoesController,
                      maxLines: 3,
                      decoration: _decoracao(
                        label: 'Observações',
                        hint: 'Ex.: preferência por cuidador com experiência em medicação',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvarVaga,
                  child: _salvando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publicar vaga'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}