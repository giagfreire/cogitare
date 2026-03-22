import 'package:flutter/material.dart';
import 'services/api_responsavel.dart';

class CriarVagaPage extends StatefulWidget {
  final int idResponsavel;

  const CriarVagaPage({
    super.key,
    required this.idResponsavel,
  });

  @override
  State<CriarVagaPage> createState() => _CriarVagaPageState();
}

class _CriarVagaPageState extends State<CriarVagaPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFimController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _cidadeController.dispose();
    _dataController.dispose();
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
      firstDate: agora,
      lastDate: DateTime(2030),
    );

    if (data != null) {
      final dataFormatada =
          '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

      setState(() {
        _dataController.text = dataFormatada;
      });
    }
  }

  Future<void> _selecionarHora(TextEditingController controller) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora != null) {
      final horaFormatada =
          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00';

      setState(() {
        controller.text = horaFormatada;
      });
    }
  }

  Future<void> _salvarVaga() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final valor = double.tryParse(
          _valorController.text.replaceAll(',', '.'),
        ) ??
        0;

    final resultado = await ApiResponsavel.criarVaga(
      idResponsavel: widget.idResponsavel,
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      cidade: _cidadeController.text.trim(),
      dataServico: _dataController.text.trim(),
      horaInicio: _horaInicioController.text.trim(),
      horaFim: _horaFimController.text.trim(),
      valor: valor,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['message'] ?? ''),
      ),
    );

    if (resultado['success'] == true) {
      Navigator.pop(context, true);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar vaga'),
        backgroundColor: const Color(0xFF35064E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: _inputDecoration('Título'),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Informe o título'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoController,
                maxLines: 4,
                decoration: _inputDecoration('Descrição'),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Informe a descrição'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cidadeController,
                decoration: _inputDecoration('Cidade'),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Informe a cidade'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dataController,
                readOnly: true,
                onTap: _selecionarData,
                decoration: _inputDecoration('Data do serviço'),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Informe a data'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _horaInicioController,
                readOnly: true,
                onTap: () => _selecionarHora(_horaInicioController),
                decoration: _inputDecoration('Hora início'),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Informe a hora de início'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _horaFimController,
                readOnly: true,
                onTap: () => _selecionarHora(_horaFimController),
                decoration: _inputDecoration('Hora fim'),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Informe a hora fim'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('Valor'),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Informe o valor'
                        : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _salvarVaga,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF35064E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Publicar vaga',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}