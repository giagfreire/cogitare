import 'package:flutter/material.dart';
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

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final dataNascimentoController = TextEditingController();
  final fotoUrlController = TextEditingController();

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
    fotoUrlController.dispose();
    super.dispose();
  }

  Future<void> carregarPerfil() async {
    setState(() {
      isLoading = true;
    });

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

        fotoUrlController.text =
            (perfil['FotoUrl'] ?? perfil['fotoUrl'] ?? '').toString();
      }
    } catch (e) {
      print('ERRO AO CARREGAR PERFIL PARA EDIÇÃO: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e')),
      );
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      final response = await ApiResponsavel.atualizarPerfil(
        nome: nomeController.text.trim(),
        email: emailController.text.trim(),
        telefone: telefoneController.text.trim(),
        dataNascimento: dataNascimentoController.text.trim(),
        fotoUrl: fotoUrlController.text.trim().isEmpty
            ? null
            : fotoUrlController.text.trim(),
      );

      if (response['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso'),
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception(response['message'] ?? 'Erro ao atualizar perfil');
      }
    } catch (e) {
      print('ERRO AO SALVAR PERFIL: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar perfil: $e')),
      );
    }

    if (!mounted) return;
    setState(() {
      isSaving = false;
    });
  }

  InputDecoration campo(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget previewFoto() {
    final url = fotoUrlController.text.trim();

    if (url.isEmpty) {
      return const CircleAvatar(
        radius: 42,
        child: Icon(Icons.person, size: 42),
      );
    }

    return CircleAvatar(
      radius: 42,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
      child: const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(child: previewFoto()),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: fotoUrlController,
                      decoration: campo('URL da foto de perfil'),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nomeController,
                      decoration: campo('Nome'),
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
                      decoration: campo('E-mail'),
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
                      decoration: campo('Telefone'),
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
                      decoration: campo('Data de nascimento (AAAA-MM-DD)'),
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
                      child: ElevatedButton(
                        onPressed: isSaving ? null : salvarPerfil,
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Salvar alterações'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}