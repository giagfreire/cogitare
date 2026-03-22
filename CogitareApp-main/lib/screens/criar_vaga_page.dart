import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';

class CriarVagaPage extends StatefulWidget {
  const CriarVagaPage({super.key});

  @override
  State<CriarVagaPage> createState() => _CriarVagaPageState();
}

class _CriarVagaPageState extends State<CriarVagaPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  DateTime? _dataServico;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;

  bool _isLoading = false;

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataServico ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _dataServico = picked;
      });
    }
  }

  Future<void> _selecionarHoraInicio() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _horaInicio = picked;
      });
    }
  }

  Future<void> _selecionarHoraFim() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaFim ?? const TimeOfDay(hour: 17, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _horaFim = picked;
      });
    }
  }

  String _formatarHora(TimeOfDay hora) {
    final hh = hora.hour.toString().padLeft(2, '0');
    final mm = hora.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  Future<void> _salvarVaga() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataServico == null || _horaInicio == null || _horaFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data e os horários da vaga.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
          'dataServico': DateFormat('yyyy-MM-dd').format(_dataServico!),
          'horaInicio': _formatarHora(_horaInicio!),
          'horaFim': _formatarHora(_horaFim!),
          'valor': double.tryParse(
                _valorController.text.replaceAll(',', '.'),
              ) ??
              0,
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaga criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Erro ao criar vaga.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar vaga: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _cidadeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataTexto = _dataServico == null
        ? 'Selecionar data'
        : DateFormat('dd/MM/yyyy').format(_dataServico!);

    final horaInicioTexto =
        _horaInicio == null ? 'Hora inicial' : _horaInicio!.format(context);

    final horaFimTexto =
        _horaFim == null ? 'Hora final' : _horaFim!.format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar vaga'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título da vaga',
                  hintText: 'Ex: Cuidador para acompanhamento diário',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o título da vaga';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descreva os cuidados necessários',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cidadeController,
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  hintText: 'Digite a cidade do serviço',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a cidade';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  hintText: 'Ex: 150.00',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o valor';
                  }

                  final numero =
                      double.tryParse(value.replaceAll(',', '.'));
                  if (numero == null || numero <= 0) {
                    return 'Informe um valor válido';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data do serviço'),
                subtitle: Text(dataTexto),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selecionarData,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hora de início'),
                subtitle: Text(horaInicioTexto),
                trailing: const Icon(Icons.access_time),
                onTap: _selecionarHoraInicio,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hora de fim'),
                subtitle: Text(horaFimTexto),
                trailing: const Icon(Icons.access_time_filled),
                onTap: _selecionarHoraFim,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _salvarVaga,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
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