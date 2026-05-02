import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/idoso.dart';
import '../services/api_idoso.dart';
import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'tela_cadastro_idoso.dart';

class CriarVagaPage extends StatefulWidget {
  final Map<String, dynamic>? vagaParaEditar;

  const CriarVagaPage({
    super.key,
    this.vagaParaEditar,
  });

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

  bool _carregando = false;
  bool _buscandoCep = false;
  bool _carregandoIdosos = true;

  List<Idoso> _idosos = [];
  Idoso? _idosoSelecionado;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  bool get editando => widget.vagaParaEditar != null;

  @override
  void initState() {
    super.initState();
    _preencherDadosEdicao();
    _carregarIdosos();
  }

  void _preencherDadosEdicao() {
    final vaga = widget.vagaParaEditar;
    if (vaga == null) return;

    _tituloController.text = vaga['Titulo']?.toString() ?? '';
    _cepController.text = vaga['Cep']?.toString() ?? '';
    _cidadeController.text = vaga['Cidade']?.toString() ?? '';
    _bairroController.text = vaga['Bairro']?.toString() ?? '';
    _ruaController.text = vaga['Rua']?.toString() ?? '';
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

  Future<void> _prepararToken() async {
    final token = await ServicoAutenticacao.getToken();

    if (token != null && token.isNotEmpty) {
      ServicoApi.setToken(token);
    }
  }

  Future<void> _carregarIdosos() async {
    setState(() => _carregandoIdosos = true);

    try {
      await _prepararToken();

      final lista = await ApiIdoso.listMeus();

      if (!mounted) return;

      Idoso? selecionado;

      if (editando && widget.vagaParaEditar?['IdIdoso'] != null) {
        final idVagaIdoso =
            int.tryParse(widget.vagaParaEditar!['IdIdoso'].toString());

        for (final idoso in lista) {
          if (idoso.id == idVagaIdoso) {
            selecionado = idoso;
            break;
          }
        }
      }

      setState(() {
        _idosos = lista;
        _idosoSelecionado =
            selecionado ?? (_idosos.isNotEmpty ? _idosos.first : null);
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

  Future<void> _salvarVaga() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idosoSelecionado == null) {
      _mostrarSnack('Cadastre ou selecione um idoso para criar a vaga.');
      return;
    }

    setState(() => _carregando = true);

    try {
      await _prepararToken();

      final body = {
        'idIdoso': _idosoSelecionado!.id,
        'titulo': _tituloController.text.trim(),
        'cep': _onlyNumbers(_cepController.text.trim()),
        'cidade': _cidadeController.text.trim(),
        'bairro': _bairroController.text.trim(),
        'rua': _ruaController.text.trim(),
      };

      late final Map<String, dynamic> response;

      if (editando) {
        final idVaga = widget.vagaParaEditar!['IdVaga'];

        response = await ServicoApi.put(
          '/api/responsavel/vaga/$idVaga',
          body,
        );
      } else {
        response = await ServicoApi.post(
          '/api/responsavel/vagas',
          body,
        );
      }

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editando
                  ? 'Vaga atualizada com sucesso!'
                  : 'Vaga criada com sucesso!',
            ),
            backgroundColor: roxo,
          ),
        );

        Navigator.pop(context, true);
      } else {
        _mostrarSnack(response['message'] ?? 'Erro ao salvar vaga.');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarSnack('Erro ao salvar vaga: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: rosa,
      ),
    );
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
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: roxo),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: roxo.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: rosa, width: 2),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            editando ? Icons.edit_note : Icons.work_outline,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            editando ? 'Editar oportunidade' : 'Nova oportunidade',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            editando
                ? 'Atualize as informações da vaga publicada.'
                : 'Selecione o idoso e informe a localidade do serviço.',
            style: const TextStyle(
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
        child: const Center(
          child: CircularProgressIndicator(color: rosa),
        ),
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
        onChanged: editando
            ? null
            : (value) {
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
              'Valor a combinar com o cuidador. O cuidador poderá informar o preço conforme os cuidados e deslocamento.',
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
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: Text(editando ? 'Editar vaga' : 'Criar vaga'),
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
              onPressed: _carregando ? null : _salvarVaga,
              icon: _carregando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(editando ? Icons.save : Icons.add),
              label: Text(
                _carregando
                    ? 'Salvando...'
                    : editando
                        ? 'Salvar alterações'
                        : 'Criar vaga',
              ),
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