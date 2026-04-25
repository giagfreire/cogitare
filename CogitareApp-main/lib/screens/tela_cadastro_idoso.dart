import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/idoso.dart';
import '../services/api_client.dart';

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

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();
  final TextEditingController _cuidadosMedicosController =
      TextEditingController();
  final TextEditingController _descricaoExtraController =
      TextEditingController();

  bool _loading = false;

  String? _sexo;
  int? _mobilidadeId;
  int? _nivelAutonomiaId;

  bool _temCuidadosMedicos = false;
  bool _temDescricaoExtra = false;
  bool _querServicos = false;

  final List<Map<String, dynamic>> _mobilidades = [
    {'id': 1, 'nome': 'Anda normalmente'},
    {'id': 2, 'nome': 'Usa bengala'},
    {'id': 3, 'nome': 'Usa andador'},
    {'id': 4, 'nome': 'Usa cadeira de rodas'},
    {'id': 5, 'nome': 'Acamado'},
  ];

  final List<Map<String, dynamic>> _autonomias = [
    {'id': 1, 'nome': 'Independente'},
    {'id': 2, 'nome': 'Precisa de pouca ajuda'},
    {'id': 3, 'nome': 'Precisa de ajuda frequente'},
    {'id': 4, 'nome': 'Totalmente dependente'},
  ];

  final List<Map<String, dynamic>> _servicos = [
    {'id': 1, 'nome': 'Acompanhamento'},
    {'id': 2, 'nome': 'Higiene pessoal'},
    {'id': 3, 'nome': 'Alimentação'},
    {'id': 4, 'nome': 'Administração de remédios'},
    {'id': 5, 'nome': 'Passeios e atividades'},
    {'id': 6, 'nome': 'Cuidados noturnos'},
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _dataNascimentoController.dispose();
    _cuidadosMedicosController.dispose();
    _descricaoExtraController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime(1950),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
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
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');
      final responsavelId =
          prefs.getInt('responsavelId') ?? prefs.getInt('userId');

      if (token == null || token.isEmpty) {
        throw Exception('Token não encontrado. Faça login novamente.');
      }

      if (responsavelId == null) {
        throw Exception('ID do responsável não encontrado.');
      }

      final idoso = Idoso(
        guardianId: responsavelId,
        name: _nomeController.text.trim(),
        birthDate: DateTime.tryParse(_dataNascimentoController.text.trim()),
        gender: _sexo,
        mobilityId: _mobilidadeId,
        autonomyLevelId: _nivelAutonomiaId,
        medicalCare: _temCuidadosMedicos
            ? _cuidadosMedicosController.text.trim()
            : null,
        extraDescription: _temDescricaoExtra
            ? _descricaoExtraController.text.trim()
            : null,
       
      );

      final body = idoso.toJson();
      body['IdResponsavel'] = responsavelId;
      body['ServicosSelecionados'] =
          _querServicos ? _servicosSelecionados : [];
      body['Disponibilidade'] =
          _querDisponibilidade ? _disponibilidade : {};

      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/idoso/cadastro'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Idoso cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception(data['message'] ?? 'Erro ao cadastrar idoso.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
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
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E5E4E),
        ),
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
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2E5E4E), width: 2),
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
        initialValue: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2E5E4E), width: 2),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pergunta,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFF2E5E4E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado ? const Color(0xFF2E5E4E) : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          texto,
          style: TextStyle(
            color: selecionado ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _listaServicos() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: _servicos.map((servico) {
          final int id = servico['id'];
          final String nome = servico['nome'];

          return CheckboxListTile(
            value: _servicosSelecionados.contains(id),
            title: Text(nome),
            activeColor: const Color(0xFF2E5E4E),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _servicosSelecionados.add(id);
                } else {
                  _servicosSelecionados.remove(id);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Cadastro do Idoso'),
        backgroundColor: const Color(0xFF2E5E4E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _tituloSecao('Dados principais'),

                _campoTexto(
                  controller: _nomeController,
                  label: 'Nome completo do idoso',
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
                  label: 'Sexo',
                  icon: Icons.wc,
                  value: _sexo,
                  items: const [
                    DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                    DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                    DropdownMenuItem(value: 'Outro', child: Text('Outro')),
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

                _dropdown<int>(
                  label: 'Nível de autonomia',
                  icon: Icons.elderly,
                  value: _nivelAutonomiaId,
                  items: _autonomias.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text(item['nome']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _nivelAutonomiaId = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione o nível de autonomia';
                    }
                    return null;
                  },
                ),

                _tituloSecao('Informações de cuidado'),

                _simNao(
                  pergunta: 'O idoso possui cuidados médicos específicos?',
                  valor: _temCuidadosMedicos,
                  onChanged: (value) {
                    setState(() {
                      _temCuidadosMedicos = value;
                      if (!value) _cuidadosMedicosController.clear();
                    });
                  },
                ),

                if (_temCuidadosMedicos)
                  _campoTexto(
                    controller: _cuidadosMedicosController,
                    label: 'Descreva os cuidados médicos',
                    icon: Icons.medical_services,
                    maxLines: 4,
                    validator: (value) {
                      if (_temCuidadosMedicos &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Descreva os cuidados médicos';
                      }
                      return null;
                    },
                  ),

                _simNao(
                  pergunta: 'Deseja adicionar uma descrição extra?',
                  valor: _temDescricaoExtra,
                  onChanged: (value) {
                    setState(() {
                      _temDescricaoExtra = value;
                      if (!value) _descricaoExtraController.clear();
                    });
                  },
                ),

                if (_temDescricaoExtra)
                  _campoTexto(
                    controller: _descricaoExtraController,
                    label: 'Descrição extra',
                    icon: Icons.description,
                    maxLines: 4,
                  ),

                _simNao(
                  pergunta: 'Deseja selecionar serviços necessários?',
                  valor: _querServicos,
                  onChanged: (value) {
                    setState(() {
                      _querServicos = value;
                      if (!value) _servicosSelecionados.clear();
                    });
                  },
                ),

                if (_querServicos) _listaServicos(),

                if (_querDisponibilidade) _listaDisponibilidade(),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _salvarIdoso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5E4E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Cadastrar idoso',
                            style: TextStyle(
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