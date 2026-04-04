import 'package:flutter/material.dart';
import '../services/api_responsavel.dart';

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
  final TextEditingController _dataServicoController = TextEditingController();
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFimController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  bool _salvando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _cidadeController.dispose();
    _dataServicoController.dispose();
    _horaInicioController.dispose();
    _horaFimController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: agora,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (data != null) {
      final texto =
          '${data.year.toString().padLeft(4, '0')}-'
          '${data.month.toString().padLeft(2, '0')}-'
          '${data.day.toString().padLeft(2, '0')}';

      _dataServicoController.text = texto;
    }
  }

  Future<void> _selecionarHora(TextEditingController controller) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora != null) {
      final texto =
          '${hora.hour.toString().padLeft(2, '0')}:'
          '${hora.minute.toString().padLeft(2, '0')}:00';

      controller.text = texto;
    }
  }

  Future<void> _salvarVaga() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final double valor =
        double.tryParse(_valorController.text.trim().replaceAll(',', '.')) ??
            0.0;

    final response = await ApiResponsavel.criarVaga(
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      cidade: _cidadeController.text.trim(),
      dataServico: _dataServicoController.text.trim(),
      horaInicio: _horaInicioController.text.trim(),
      horaFim: _horaFimController.text.trim(),
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

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Nova vaga',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preencha os dados abaixo para publicar uma nova necessidade.',
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _tituloController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Título',
                  hint: 'Ex.: Cuidador para acompanhamento diário',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o título';
                  }
                  if (value.trim().length < 3) {
                    return 'Digite um título maior';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descricaoController,
                textInputAction: TextInputAction.newline,
                maxLines: 4,
                decoration: _inputDecoration(
                  label: 'Descrição',
                  hint: 'Descreva a necessidade da vaga',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a descrição';
                  }
                  if (value.trim().length < 10) {
                    return 'Digite uma descrição mais completa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _cidadeController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
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
                controller: _dataServicoController,
                readOnly: true,
                decoration: _inputDecoration(
                  label: 'Data do serviço',
                  hint: 'AAAA-MM-DD',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selecionarData,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a data do serviço';
                  }
                  return null;
                },
                onTap: _selecionarData,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _horaInicioController,
                readOnly: true,
                decoration: _inputDecoration(
                  label: 'Hora de início',
                  hint: 'HH:MM:SS',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _selecionarHora(_horaInicioController),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a hora de início';
                  }
                  return null;
                },
                onTap: () => _selecionarHora(_horaInicioController),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _horaFimController,
                readOnly: true,
                decoration: _inputDecoration(
                  label: 'Hora de fim',
                  hint: 'HH:MM:SS',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _selecionarHora(_horaFimController),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a hora de fim';
                  }
                  return null;
                },
                onTap: () => _selecionarHora(_horaFimController),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  label: 'Valor',
                  hint: 'Ex.: 150.00',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o valor';
                  }

                  final numero =
                      double.tryParse(value.trim().replaceAll(',', '.'));
                  if (numero == null || numero <= 0) {
                    return 'Informe um valor válido';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
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