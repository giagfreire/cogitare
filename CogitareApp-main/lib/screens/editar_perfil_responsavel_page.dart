import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../services/api_responsavel.dart';

class EditarPerfilResponsavelPage extends StatefulWidget {
  const EditarPerfilResponsavelPage({super.key});

  @override
  State<EditarPerfilResponsavelPage> createState() =>
      _EditarPerfilResponsavelPageState();
}

class _EditarPerfilResponsavelPageState
    extends State<EditarPerfilResponsavelPage> {
  final _formKey = GlobalKey<FormState>();

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color fundo = Color(0xFFF6F4F8);

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final dataNascimentoController = TextEditingController();

  final cepController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();
  final bairroController = TextEditingController();
  final ruaController = TextEditingController();
  final numeroController = TextEditingController();
  final complementoController = TextEditingController();

  final whatsappController = TextEditingController();
  final telefoneContatoController = TextEditingController();
  final emailContatoController = TextEditingController();

  String? preferenciaContato;
  String? fotoBase64;

  bool isLoading = true;
  bool isSaving = false;
  bool buscandoCep = false;

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    dataNascimentoController.dispose();

    cepController.dispose();
    cidadeController.dispose();
    estadoController.dispose();
    bairroController.dispose();
    ruaController.dispose();
    numeroController.dispose();
    complementoController.dispose();

    whatsappController.dispose();
    telefoneContatoController.dispose();
    emailContatoController.dispose();

    super.dispose();
  }

  String _valor(dynamic valor) {
    if (valor == null) return '';
    final texto = valor.toString().trim();
    if (texto.toLowerCase() == 'null') return '';
    return texto;
  }

  String _somenteNumeros(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  bool _fotoEhBase64(String texto) {
    return texto.startsWith('data:image');
  }

  Future<void> carregarPerfil() async {
    setState(() => isLoading = true);

    try {
      final perfil = await ApiResponsavel.getPerfil();

      if (perfil != null) {
        nomeController.text = _valor(perfil['Nome'] ?? perfil['nome']);
        emailController.text = _valor(perfil['Email'] ?? perfil['email']);
        telefoneController.text =
            _valor(perfil['Telefone'] ?? perfil['telefone']);

        final dataRaw =
            _valor(perfil['DataNascimento'] ?? perfil['dataNascimento']);

        dataNascimentoController.text =
            dataRaw.contains('T') ? dataRaw.split('T').first : dataRaw;

        fotoBase64 = _valor(perfil['FotoUrl'] ?? perfil['fotoUrl']);

        cepController.text = _valor(perfil['Cep'] ?? perfil['cep']);
        cidadeController.text = _valor(perfil['Cidade'] ?? perfil['cidade']);
        estadoController.text = _valor(perfil['Estado'] ?? perfil['estado']);
        bairroController.text = _valor(perfil['Bairro'] ?? perfil['bairro']);
        ruaController.text = _valor(perfil['Rua'] ?? perfil['rua']);
        numeroController.text = _valor(perfil['Numero'] ?? perfil['numero']);
        complementoController.text =
            _valor(perfil['Complemento'] ?? perfil['complemento']);

        whatsappController.text = _valor(
          perfil['ContatoWhatsapp'] ?? perfil['contatoWhatsapp'],
        );

        telefoneContatoController.text = _valor(
          perfil['ContatoTelefone'] ?? perfil['contatoTelefone'],
        );

        emailContatoController.text = _valor(
          perfil['ContatoEmail'] ?? perfil['contatoEmail'],
        );

        preferenciaContato = _valor(
          perfil['PreferenciaContato'] ?? perfil['preferenciaContato'],
        );

        if (preferenciaContato != 'WhatsApp' &&
            preferenciaContato != 'Telefone' &&
            preferenciaContato != 'E-mail') {
          preferenciaContato = null;
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar perfil: $e'),
          backgroundColor: rosa,
        ),
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> buscarCep() async {
    final cep = _somenteNumeros(cepController.text);

    if (cep.length != 8 || buscandoCep) return;

    setState(() => buscandoCep = true);

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['erro'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CEP não encontrado.'),
              backgroundColor: rosa,
            ),
          );
          return;
        }

        setState(() {
          ruaController.text = data['logradouro']?.toString() ?? '';
          bairroController.text = data['bairro']?.toString() ?? '';
          cidadeController.text = data['localidade']?.toString() ?? '';
          estadoController.text = data['uf']?.toString() ?? '';
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar CEP: $e'),
          backgroundColor: rosa,
        ),
      );
    } finally {
      if (mounted) setState(() => buscandoCep = false);
    }
  }

  Future<void> selecionarFoto() async {
    try {
      final picker = ImagePicker();

      final XFile? imagem = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();

      final extensao =
          imagem.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';

      setState(() {
        fotoBase64 = 'data:image/$extensao;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar foto: $e'),
          backgroundColor: rosa,
        ),
      );
    }
  }

  Future<void> salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final response = await ApiResponsavel.atualizarPerfil(
        nome: nomeController.text.trim(),
        email: emailController.text.trim(),
        telefone: telefoneController.text.trim(),
        dataNascimento: dataNascimentoController.text.trim(),
        fotoUrl: fotoBase64,
        cep: cepController.text.trim(),
        cidade: cidadeController.text.trim(),
        bairro: bairroController.text.trim(),
        rua: ruaController.text.trim(),
        numero: numeroController.text.trim(),
        estado: estadoController.text.trim(),
        complemento: complementoController.text.trim(),
        contatoWhatsapp: whatsappController.text.trim(),
        contatoTelefone: telefoneContatoController.text.trim(),
        contatoEmail: emailContatoController.text.trim(),
        preferenciaContato: preferenciaContato,
      );

      if (response['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso'),
            backgroundColor: roxo,
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception(response['message'] ?? 'Erro ao atualizar perfil');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar perfil: $e'),
          backgroundColor: rosa,
        ),
      );
    }

    if (!mounted) return;
    setState(() => isSaving = false);
  }

  InputDecoration campo(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: roxo),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: roxo),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: roxo.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: rosa, width: 2),
      ),
    );
  }

  Widget previewFoto() {
    if (fotoBase64 == null || fotoBase64!.trim().isEmpty) {
      return const CircleAvatar(
        radius: 52,
        backgroundColor: roxo,
        child: Icon(Icons.person, size: 52, color: Colors.white),
      );
    }

    if (_fotoEhBase64(fotoBase64!)) {
      final base64Limpo = fotoBase64!.split(',').last;

      return CircleAvatar(
        radius: 52,
        backgroundImage: MemoryImage(base64Decode(base64Limpo)),
      );
    }

    if (fotoBase64!.startsWith('http')) {
      return CircleAvatar(
        radius: 52,
        backgroundImage: NetworkImage(fotoBase64!),
        onBackgroundImageError: (_, __) {},
      );
    }

    return const CircleAvatar(
      radius: 52,
      backgroundColor: roxo,
      child: Icon(Icons.person, size: 52, color: Colors.white),
    );
  }

  Future<void> selecionarData() async {
    final inicial = DateTime.tryParse(dataNascimentoController.text) ??
        DateTime(1990, 1, 1);

    final data = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (data != null) {
      setState(() {
        dataNascimentoController.text =
            '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget tituloSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              color: rosa,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            titulo,
            style: const TextStyle(
              color: roxo,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget espaco() => const SizedBox(height: 14);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: rosa))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
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
                        children: [
                          previewFoto(),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: selecionarFoto,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Alterar foto'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),

                    tituloSecao('Dados pessoais'),

                    TextFormField(
                      controller: nomeController,
                      decoration: campo('Nome completo', Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome';
                        }
                        return null;
                      },
                    ),

                    espaco(),

                    TextFormField(
                      controller: emailController,
                      decoration: campo('E-mail', Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o e-mail';
                        }

                        if (!value.contains('@')) {
                          return 'E-mail inválido';
                        }

                        return null;
                      },
                    ),

                    espaco(),

                    TextFormField(
                      controller: telefoneController,
                      decoration: campo('Telefone', Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o telefone';
                        }
                        return null;
                      },
                    ),

                    espaco(),

                    TextFormField(
                      controller: dataNascimentoController,
                      readOnly: true,
                      onTap: selecionarData,
                      decoration: campo(
                        'Data de nascimento',
                        Icons.calendar_today_outlined,
                      ),
                    ),

                    tituloSecao('Endereço'),

                    TextFormField(
                      controller: cepController,
                      decoration: campo(
                        'CEP',
                        Icons.location_searching,
                        suffixIcon: buscandoCep
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: rosa,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search, color: roxo),
                                onPressed: buscarCep,
                              ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      onChanged: (value) {
                        if (_somenteNumeros(value).length == 8) {
                          buscarCep();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o CEP';
                        }

                        if (_somenteNumeros(value).length != 8) {
                          return 'CEP inválido';
                        }

                        return null;
                      },
                    ),

                    espaco(),

                    TextFormField(
                      controller: ruaController,
                      readOnly: true,
                      decoration: campo('Rua', Icons.signpost_outlined),
                    ),

                    espaco(),

                    TextFormField(
                      controller: bairroController,
                      readOnly: true,
                      decoration: campo('Bairro', Icons.map_outlined),
                    ),

                    espaco(),

                    TextFormField(
                      controller: cidadeController,
                      readOnly: true,
                      decoration: campo(
                        'Cidade',
                        Icons.location_city_outlined,
                      ),
                    ),

                    espaco(),

                    TextFormField(
                      controller: estadoController,
                      readOnly: true,
                      decoration: campo('Estado', Icons.public_outlined),
                    ),

                    espaco(),

                    TextFormField(
                      controller: numeroController,
                      decoration: campo('Número', Icons.numbers_outlined),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o número';
                        }
                        return null;
                      },
                    ),

                    espaco(),

                    TextFormField(
                      controller: complementoController,
                      decoration: campo(
                        'Complemento (opcional)',
                        Icons.add_location_alt_outlined,
                      ),
                    ),

                    tituloSecao('Contato para cuidadores'),

                    TextFormField(
                      controller: whatsappController,
                      decoration: campo('WhatsApp de contato', Icons.chat),
                      keyboardType: TextInputType.phone,
                    ),

                    espaco(),

                    TextFormField(
                      controller: telefoneContatoController,
                      decoration: campo(
                        'Telefone de contato',
                        Icons.call_outlined,
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    espaco(),

                    TextFormField(
                      controller: emailContatoController,
                      decoration: campo(
                        'E-mail de contato',
                        Icons.alternate_email,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    espaco(),

                    DropdownButtonFormField<String>(
                      initialValue: preferenciaContato,
                      decoration: campo(
                        'Preferência de contato',
                        Icons.contact_phone_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'WhatsApp',
                          child: Text('WhatsApp'),
                        ),
                        DropdownMenuItem(
                          value: 'Telefone',
                          child: Text('Telefone'),
                        ),
                        DropdownMenuItem(
                          value: 'E-mail',
                          child: Text('E-mail'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => preferenciaContato = value);
                      },
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : salvarPerfil,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rosa,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: rosa.withOpacity(0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Salvar alterações',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}