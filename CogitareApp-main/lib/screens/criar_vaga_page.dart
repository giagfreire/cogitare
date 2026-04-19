import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

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
Future<void> _criarVaga() async {
  if (!_formKey.currentState!.validate()) return;

  if (_dataSelecionada == null || _horaInicio == null || _horaFim == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preencha data e horários')),
    );
    return;
  }

  setState(() => _carregando = true);

  try {
    final responsavelId = 1;

    final response = await ServicoApi.post(
      '/api/responsavel/vagas',
      {
        'idResponsavel': responsavelId,
        'titulo': _tituloController.text,
        'descricao': _descricaoController.text,
        'cidade': _cidadeController.text,
        'dataServico': _dataSelecionada.toString().split(' ')[0],
        'horaInicio': _horaInicio!.format(context),
        'horaFim': _horaFim!.format(context),
        'valor': _valorController.text,
      },
    );

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaga criada com sucesso!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Erro')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: $e')),
    );
  }

  setState(() => _carregando = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Vaga')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _campo(_tituloController, 'Título'),
              _campo(_descricaoController, 'Descrição'),
              _campo(_cidadeController, 'Cidade'),
              _campo(_valorController, 'Valor'),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _selecionarData,
                child: Text(_dataSelecionada == null
                    ? 'Selecionar Data'
                    : _dataSelecionada.toString().split(' ')[0]),
              ),

              ElevatedButton(
                onPressed: () => _selecionarHora(true),
                child: Text(_horaInicio == null
                    ? 'Hora início'
                    : _horaInicio!.format(context)),
              ),

              ElevatedButton(
                onPressed: () => _selecionarHora(false),
                child: Text(_horaFim == null
                    ? 'Hora fim'
                    : _horaFim!.format(context)),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _carregando ? null : _criarVaga,
                child: _carregando
                    ? const CircularProgressIndicator()
                    : const Text('Criar vaga'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: (value) =>
            value == null || value.isEmpty ? 'Obrigatório' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}