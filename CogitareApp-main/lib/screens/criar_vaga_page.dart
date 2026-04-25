import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/idoso.dart';
import '../services/api_idoso.dart';
import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'tela_cadastro_idoso.dart';

class CriarVagaPage extends StatefulWidget {
  const CriarVagaPage({super.key});

  @override
  State<CriarVagaPage> createState() => _CriarVagaPageState();
}

class _CriarVagaPageState extends State<CriarVagaPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _cepController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _bairroController = TextEditingController();
  final _ruaController = TextEditingController();

  DateTime? _dataSelecionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;

  bool _carregando = false;
  bool _buscandoCep = false;
  bool _carregandoIdosos = true;

  List<Idoso> _idosos = [];
  Idoso? _idosoSelecionado;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _carregarIdosos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _cepController.dispose();
    _cidadeController.dispose();
    _bairroController.dispose();
    _ruaController.dispose();
    super.dispose();
  }

  String _onlyNumbers(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _carregarIdosos() async {
    setState(() => _carregandoIdosos = true);

    try {
      final token = await ServicoAutenticacao.getToken();

      if (token != null && token.isNotEmpty) {
        ServicoApi.setToken(token);
      }

      final lista = await ApiIdoso.listMeus();

      if (!mounted) return;

      setState(() {
        _idosos = lista;
        if (_idosos.isNotEmpty) {
          _idosoSelecionado ??= _idosos.first;
        }
        _carregandoIdosos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoIdosos = false);
    }
  }

  Future<void> _irCadastrarIdoso() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaCadastroIdoso(),
      ),
    );

    if (result == true) {
      await _carregarIdosos();
    }
  }

  Future<void> _buscarCep() async {
    final cep = _onlyNumbers(_cepController.text.trim());

    if (cep.length != 8 || _buscandoCep) return;

    setState(() => _buscandoCep = true);

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['erro'] == true) {
          _mostrarSnack('CEP não encontrado.');
          return;
        }

        setState(() {
          _ruaController.text = data['logradouro']?.toString() ?? '';
          _bairroController.text = data['bairro']?.toString() ?? '';
          _cidadeController.text = data['localidade']?.toString() ?? '';
        });
      } else {
        _mostrarSnack('Não foi possível buscar o CEP.');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarSnack('Erro ao buscar CEP: $e');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  String _formatarHora(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _formatarHoraTela(TimeOfDay? hora) {
    if (hora == null) return 'Selecionar';
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatarData(DateTime data) {
    final ano = data.year.toString();
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '$ano-$mes-$dia';
  }

  String _formatarDataTela(DateTime? data) {
    if (data == null) return 'Selecionar';
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    return '$dia/$mes/$ano';
  }

  int _minutos(TimeOfDay hora) {
    return hora.hour * 60 + hora.minute;
  }

  bool _horarioValido() {
    if (_horaInicio == null || _horaFim == null) return false;
    return _minutos(_horaFim!) > _minutos(_horaInicio!);
  }

  Future<void> _criarVaga() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idosoSelecionado == null) {
      _mostrarSnack('Cadastre ou selecione um idoso para criar a vaga.');
      return;
    }

    if (_dataSelecionada == null) {
      _mostrarSnack('Selecione a data do serviço.');
      return;
    }

    if (_horaInicio == null || _horaFim == null) {
      _mostrarSnack('Preencha a hora de início e fim.');
      return;
    }

    if (!_horarioValido()) {
      _mostrarSnack('A hora final precisa ser maior que a hora inicial.');
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
          'idIdoso': _idosoSelecionado!.id,
          'titulo': _tituloController.text.trim(),
          'cep': _onlyNumbers(_cepController.text.trim()),
          'cidade': _cidadeController.text.trim(),
          'bairro': _bairroController.text.trim(),
          'rua': _ruaController.text.trim(),
          'dataServico': _formatarData(_dataSelecionada!),
          'horaInicio': _formatarHora(_horaInicio!),
          'horaFim': _formatarHora(_horaFim!),
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga criada com sucesso!')),
        );

        Navigator.pop(context, true);
      } else {
        _mostrarSnack(response['message'] ?? 'Erro ao criar vaga.');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarSnack('Erro ao criar vaga: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
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

  Widget _campo({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    String? Function(String?)? validator,
    bool enabled = true,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        maxLength: maxLength,
        onChanged: onChanged,
        validator: validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obrigatório';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: roxo) : null,
          suffixIcon: suffixIcon,
          counterText: '',
        ),
      ),
    );
  }

  Widget _seletor({
    required IconData icon,
    required String titulo,
    required String valor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: roxo.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: roxo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: roxo.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: const TextStyle(
                        color: roxo,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: roxo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [roxo, rosa],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.work_outline, color: Colors.white, size: 36),
          SizedBox(height: 12),
          Text(
            'Nova oportunidade',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Selecione o idoso, informe a localidade e o horário do serviço.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardIdoso() {
    if (_carregandoIdosos) {
      return Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_idosos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: verde.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nenhum idoso cadastrado',
              style: TextStyle(
                color: roxo,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre primeiro o perfil do idoso para criar uma vaga.',
              style: TextStyle(color: roxo, height: 1.4),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _irCadastrarIdoso,
                icon: const Icon(Icons.elderly_outlined),
                label: const Text('Cadastrar idoso'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rosa,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roxo.withOpacity(0.08)),
      ),
      child: DropdownButtonFormField<Idoso>(
        value: _idosoSelecionado,
        decoration: const InputDecoration(
          labelText: 'Idoso',
          prefixIcon: Icon(Icons.elderly_outlined, color: roxo),
        ),
        items: _idosos.map((idoso) {
          return DropdownMenuItem<Idoso>(
            value: idoso,
            child: Text(idoso.name),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _idosoSelecionado = value);
        },
      ),
    );
  }

  Widget _infoValor() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: verde.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: roxo),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Valor a combinar com o cuidador. O cuidador poderá informar o preço conforme horário, cuidados e deslocamento.',
              style: TextStyle(
                color: roxo,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textoData = _formatarDataTela(_dataSelecionada);
    final textoInicio = _formatarHoraTela(_horaInicio);
    final textoFim = _formatarHoraTela(_horaFim);

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Criar vaga'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _header(),
              const SizedBox(height: 20),
              _cardIdoso(),
              _campo(
                controller: _tituloController,
                label: 'Título da vaga',
                hint: 'Ex: Cuidador para acompanhamento',
                icon: Icons.title,
              ),
              _campo(
                controller: _cepController,
                label: 'CEP da localidade',
                hint: 'Digite o CEP',
                icon: Icons.location_searching,
                keyboardType: TextInputType.number,
                maxLength: 8,
                suffixIcon: _buscandoCep
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _buscarCep,
                      ),
                onChanged: (value) {
                  if (_onlyNumbers(value).length == 8) {
                    _buscarCep();
                  }
                },
                validator: (value) {
                  if (_onlyNumbers(value ?? '').length != 8) {
                    return 'Informe um CEP válido';
                  }
                  return null;
                },
              ),
              _campo(
                controller: _cidadeController,
                label: 'Cidade',
                hint: 'Cidade',
                icon: Icons.location_city,
              ),
              _campo(
                controller: _bairroController,
                label: 'Bairro',
                hint: 'Bairro',
                icon: Icons.map_outlined,
              ),
              _campo(
                controller: _ruaController,
                label: 'Rua / localidade aproximada',
                hint: 'Rua',
                icon: Icons.place_outlined,
              ),
              const SizedBox(height: 4),
              _seletor(
                icon: Icons.calendar_today,
                titulo: 'Data do serviço',
                valor: textoData,
                onTap: _selecionarData,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _seletor(
                      icon: Icons.access_time,
                      titulo: 'Início',
                      valor: textoInicio,
                      onTap: () => _selecionarHora(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _seletor(
                      icon: Icons.access_time_filled,
                      titulo: 'Fim',
                      valor: textoFim,
                      onTap: () => _selecionarHora(false),
                    ),
                  ),
                ],
              ),
              if (_horaInicio != null &&
                  _horaFim != null &&
                  !_horarioValido()) ...[
                const SizedBox(height: 10),
                const Text(
                  'A hora final precisa ser maior que a hora inicial.',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _infoValor(),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _carregando ? null : _criarVaga,
              icon: _carregando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_carregando ? 'Criando...' : 'Criar vaga'),
              style: ElevatedButton.styleFrom(
                backgroundColor: rosa,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}