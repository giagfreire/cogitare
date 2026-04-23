import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';

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
  final _valorController = TextEditingController();

  DateTime? _dataSelecionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;

  bool _carregando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _cidadeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  String _formatarHora(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _formatarData(DateTime data) {
    final ano = data.year.toString();
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '$ano-$mes-$dia';
  }

  Future<void> _criarVaga() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataSelecionada == null || _horaInicio == null || _horaFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a data e os horários.')),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      final token = await ServicoAutenticacao.getToken();

      if (token != null && token.isNotEmpty) {
        ServicoApi.setToken(token);
      }

      final response = await ServicoApi.post(
        '/api/responsavel/vagas',
        {
          'titulo': _tituloController.text.trim(),
          'descricao': _descricaoController.text.trim(),
          'cidade': _cidadeController.text.trim(),
          'dataServico': _formatarData(_dataSelecionada!),
          'horaInicio': _formatarHora(_horaInicio!),
          'horaFim': _formatarHora(_horaFim!),
          'valor': double.tryParse(
                _valorController.text.trim().replaceAll(',', '.'),
              ) ??
              0,
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga criada com sucesso!')),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erro ao criar vaga.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar vaga: $e')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _selecionarHora(bool inicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

  Widget _campo(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Campo obrigatório';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textoData = _dataSelecionada == null
        ? 'Selecionar data'
        : _formatarData(_dataSelecionada!);

    final textoInicio =
        _horaInicio == null ? 'Hora início' : _horaInicio!.format(context);

    final textoFim =
        _horaFim == null ? 'Hora fim' : _horaFim!.format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar vaga'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _campo(_tituloController, 'Título da vaga'),
              _campo(
                _descricaoController,
                'Descrição',
                maxLines: 4,
              ),
              _campo(_cidadeController, 'Cidade'),
              _campo(
                _valorController,
                'Valor',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selecionarData,
                icon: const Icon(Icons.calendar_today),
                label: Text(textoData),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _selecionarHora(true),
                icon: const Icon(Icons.access_time),
                label: Text(textoInicio),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _selecionarHora(false),
                icon: const Icon(Icons.access_time_filled),
                label: Text(textoFim),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _carregando ? null : _criarVaga,
                child: _carregando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Criar vaga'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}