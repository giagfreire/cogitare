import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'tela_configuracoes.dart';
import 'tela_editar_perfil_cuidador.dart';

class PerfilCuidadorPage extends StatefulWidget {
  static const route = '/perfil-cuidador';

  const PerfilCuidadorPage({super.key});

  @override
  State<PerfilCuidadorPage> createState() => _PerfilCuidadorPageState();
}

class _PerfilCuidadorPageState extends State<PerfilCuidadorPage> {
  bool _isLoading = true;
  bool _isUploadingFoto = false;

  String? _errorMessage;
  Map<String, dynamic>? _cuidador;

  String _planoAtual = 'Básico';
  int? _cuidadorId;
  Uint8List? _fotoSelecionada;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  String _textoSeguro(dynamic valor, {String fallback = 'Não informado'}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  String _formatarData(dynamic data) {
    if (data == null) return 'Não informado';

    final texto = data.toString();

    if (texto.length >= 10 && texto.contains('-')) {
      final partes = texto.substring(0, 10).split('-');

      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    }

    return texto;
  }

  int? _parseInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

dynamic _campo(String a, [String? b, String? c]) {
  if (_cuidador == null) return null;

  if (_cuidador!.containsKey(a)) {
    return _cuidador![a];
  }

  if (b != null && _cuidador!.containsKey(b)) {
    return _cuidador![b];
  }

  if (c != null && _cuidador!.containsKey(c)) {
    return _cuidador![c];
  }

  return null;
}

  ImageProvider? _fotoProvider() {
    if (_fotoSelecionada != null) {
      return MemoryImage(_fotoSelecionada!);
    }

    final fotoUrl = (_campo('fotoUrl', 'FotoUrl', 'foto_url'))?.toString().trim();

    if (fotoUrl == null || fotoUrl.isEmpty || fotoUrl.toLowerCase() == 'null') {
      return null;
    }

    if (fotoUrl.startsWith('data:image')) {
      try {
        final base64String = fotoUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return null;
      }
    }

    if (fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://')) {
      return NetworkImage(fotoUrl);
    }

    return null;
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await ServicoAutenticacao.getToken();
      final userData = await ServicoAutenticacao.getUserData();
      final userType = await ServicoAutenticacao.getUserType();

      if (token != null && token.isNotEmpty) {
        ServicoApi.setToken(token);
      }

      if (userType != 'cuidador' || userData == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Não foi possível identificar o cuidador logado.';
          _isLoading = false;
        });
        return;
      }

      final cuidadorId = _parseInt(
        userData['IdCuidador'] ??
            userData['idCuidador'] ??
            userData['cuidadorId'] ??
            userData['id'] ??
            userData['Id'],
      );

      _cuidadorId = cuidadorId;

      if (cuidadorId == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'ID do cuidador não encontrado.';
          _isLoading = false;
        });
        return;
      }

      final responseCuidador = await ServicoApi.get('/api/cuidador/$cuidadorId');

      if (responseCuidador['success'] == true && responseCuidador['data'] != null) {
        _cuidador = Map<String, dynamic>.from(responseCuidador['data']);
      } else {
        _errorMessage = responseCuidador['message'] ?? 'Erro ao carregar perfil.';
      }

      try {
        final responsePlano = await ServicoApi.get('/api/cuidador/$cuidadorId/plano');

        if (responsePlano['success'] == true && responsePlano['data'] != null) {
          _planoAtual = (responsePlano['data']['PlanoAtual'] ?? 'Básico').toString();
        }
      } catch (_) {
        _planoAtual = 'Básico';
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar perfil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selecionarESalvarFoto() async {
    try {
      final picker = ImagePicker();

      final XFile? imagem = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 800,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();
      final base64Foto = base64Encode(bytes);
      final fotoUrl = 'data:image/jpeg;base64,$base64Foto';

      setState(() {
        _fotoSelecionada = bytes;
        _isUploadingFoto = true;
      });

      final token = await ServicoAutenticacao.getToken();
      final userData = await ServicoAutenticacao.getUserData();

      if (token != null && token.isNotEmpty) {
        ServicoApi.setToken(token);
      }

      final cuidadorId = _cuidadorId ??
          _parseInt(
            userData?['IdCuidador'] ??
                userData?['idCuidador'] ??
                userData?['cuidadorId'] ??
                userData?['id'] ??
                userData?['Id'],
          );

      if (cuidadorId == null) {
        throw Exception('ID do cuidador não encontrado.');
      }

      final response = await ServicoApi.put('/api/cuidador/$cuidadorId', {
        'nome': _campo('Nome', 'nome'),
        'telefone': _campo('Telefone', 'telefone'),
        'cpf': _campo('Cpf', 'CPF', 'cpf'),
        'dataNascimento': _campo('DataNascimento', 'dataNascimento'),
        'sexo': _campo('Sexo', 'sexo'),
        'cidade': _campo('Cidade', 'cidade'),
        'biografia': _campo('Biografia', 'biografia'),
        'fotoUrl': fotoUrl,
        'escolaridade': _campo('Escolaridade', 'escolaridade'),
        'experienciaProfissional': _campo(
          'ExperienciaProfissional',
          'experienciaProfissional',
        ),
        'trabalhosFeitos': _campo('TrabalhosFeitos', 'trabalhosFeitos'),
        'diplomasCertificados': _campo(
          'DiplomasCertificados',
          'diplomasCertificados',
        ),
      });

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _cuidador = {
            ...?_cuidador,
            'fotoUrl': fotoUrl,
            'FotoUrl': fotoUrl,
          };
          _isUploadingFoto = false;
        });

        await _carregarDados();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada com sucesso!')),
        );
      } else {
        setState(() => _isUploadingFoto = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erro ao salvar foto.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isUploadingFoto = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar/salvar foto: $e')),
      );
    }
  }

  Future<void> _irParaEditarPerfil() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaEditarPerfilCuidador(),
      ),
    );

    if (resultado == true) {
      await _carregarDados();
    }
  }

  Future<void> _irParaConfiguracoes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaConfiguracoes(),
      ),
    );

    await _carregarDados();
  }

  Widget _infoTile({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roxo.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: 13,
                    color: roxo.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: roxo,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textoCard({
    required String titulo,
    required String valor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roxo.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: roxo.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: roxo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fotoPerfil() {
    final provider = _fotoProvider();

    return Column(
      children: [
        GestureDetector(
          onTap: _isUploadingFoto ? null : _selecionarESalvarFoto,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: Colors.white24,
                backgroundImage: provider,
                child: provider == null
                    ? const Icon(
                        Icons.camera_alt,
                        size: 38,
                        color: Colors.white,
                      )
                    : null,
              ),
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: rosa,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _isUploadingFoto
                    ? const Padding(
                        padding: EdgeInsets.all(7),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.edit, size: 15, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isUploadingFoto ? null : _selecionarESalvarFoto,
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('Alterar foto'),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = _textoSeguro(_campo('Nome', 'nome'), fallback: 'Cuidador');
    final email = _textoSeguro(_campo('Email', 'email'));
    final telefone = _textoSeguro(_campo('Telefone', 'telefone'));
    final cpf = _textoSeguro(_campo('Cpf', 'CPF', 'cpf'));
    final cidade = _textoSeguro(_campo('Cidade', 'cidade'));
    final sexo = _textoSeguro(_campo('Sexo', 'sexo'));
    final biografia = _textoSeguro(
      _campo('Biografia', 'biografia'),
      fallback: 'Você ainda não cadastrou uma biografia.',
    );

    final dataNascimento = _formatarData(
      _campo('DataNascimento', 'dataNascimento'),
    );

    final escolaridade = _textoSeguro(
      _campo('Escolaridade', 'escolaridade'),
      fallback: 'Escolaridade ainda não informada.',
    );

    final experienciaProfissional = _textoSeguro(
      _campo('ExperienciaProfissional', 'experienciaProfissional'),
      fallback: 'Experiência profissional ainda não informada.',
    );

    final trabalhosFeitos = _textoSeguro(
      _campo('TrabalhosFeitos', 'trabalhosFeitos'),
      fallback: 'Trabalhos anteriores ainda não informados.',
    );

    final diplomasCertificados = _textoSeguro(
      _campo('DiplomasCertificados', 'diplomasCertificados'),
      fallback: 'Diplomas e certificados ainda não informados.',
    );

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 52,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _carregarDados,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
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
                            _fotoPerfil(),
                            const SizedBox(height: 8),
                            Text(
                              nome,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _planoAtual.toLowerCase() == 'premium'
                                    ? verde
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _planoAtual.toLowerCase() == 'premium'
                                    ? 'Plano Premium'
                                    : 'Plano Básico',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: _planoAtual.toLowerCase() == 'premium'
                                      ? Colors.black
                                      : roxo,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _irParaEditarPerfil,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white54,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Editar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _irParaConfiguracoes,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: roxo,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.settings_outlined),
                                    label: const Text('Configurações'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Informações pessoais',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: roxo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoTile(
                        icon: Icons.phone_outlined,
                        titulo: 'Telefone',
                        valor: telefone,
                      ),
                      const SizedBox(height: 10),
                      _infoTile(
                        icon: Icons.badge_outlined,
                        titulo: 'CPF',
                        valor: cpf,
                      ),
                      const SizedBox(height: 10),
                      _infoTile(
                        icon: Icons.wc_outlined,
                        titulo: 'Sexo',
                        valor: sexo,
                      ),
                      const SizedBox(height: 10),
                      _infoTile(
                        icon: Icons.cake_outlined,
                        titulo: 'Data de nascimento',
                        valor: dataNascimento,
                      ),
                      const SizedBox(height: 10),
                      _infoTile(
                        icon: Icons.location_on_outlined,
                        titulo: 'Cidade',
                        valor: cidade,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Perfil profissional',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: roxo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _textoCard(
                        icon: Icons.school_outlined,
                        titulo: 'Escolaridade',
                        valor: escolaridade,
                      ),
                      _textoCard(
                        icon: Icons.work_outline,
                        titulo: 'Experiência profissional',
                        valor: experienciaProfissional,
                      ),
                      _textoCard(
                        icon: Icons.elderly_outlined,
                        titulo: 'Trabalhos já feitos',
                        valor: trabalhosFeitos,
                      ),
                      _textoCard(
                        icon: Icons.workspace_premium_outlined,
                        titulo: 'Diplomas e certificados',
                        valor: diplomasCertificados,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sobre mim',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: roxo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _textoCard(
                        icon: Icons.person_outline,
                        titulo: 'Biografia',
                        valor: biografia,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}