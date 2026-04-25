import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  String? fotoBase64;

  bool isLoading = true;
  bool isSaving = false;

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
    super.dispose();
  }

  bool _fotoEhBase64(String texto) {
    return texto.startsWith('data:image');
  }

  Future<void> carregarPerfil() async {
    setState(() => isLoading = true);

    try {
      final perfil = await ApiResponsavel.getPerfil();

      if (perfil != null) {
        nomeController.text =
            (perfil['Nome'] ?? perfil['nome'] ?? '').toString();

        emailController.text =
            (perfil['Email'] ?? perfil['email'] ?? '').toString();

        telefoneController.text =
            (perfil['Telefone'] ?? perfil['telefone'] ?? '').toString();

        final dataRaw =
            (perfil['DataNascimento'] ?? perfil['dataNascimento'] ?? '')
                .toString();

        dataNascimentoController.text =
            dataRaw.contains('T') ? dataRaw.split('T').first : dataRaw;

        final foto = (perfil['FotoUrl'] ?? perfil['fotoUrl'] ?? '').toString();

        if (foto.trim().isNotEmpty) {
          fotoBase64 = foto;
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
      final extensao = imagem.name.toLowerCase().endsWith('.png')
          ? 'png'
          : 'jpeg';

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

  InputDecoration campo(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: roxo),
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
                            label: const Text('Selecionar foto da galeria'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: nomeController,
                      decoration: campo('Nome', Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

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

                    const SizedBox(height: 14),

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

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: dataNascimentoController,
                      readOnly: true,
                      onTap: selecionarData,
                      decoration: campo(
                        'Data de nascimento',
                        Icons.calendar_today_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a data de nascimento';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : salvarPerfil,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rosa,
                          foregroundColor: Colors.white,
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
                  ],
                ),
              ),
            ),
    );
  }
}