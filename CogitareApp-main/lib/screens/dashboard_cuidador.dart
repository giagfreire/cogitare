import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'perfil_cuidador_page.dart';
import 'planos_cuidador_page.dart';
import 'vagas_cuidador_page.dart';
import 'tela_configuracoes.dart';
import 'minhas_vagas_aceitas_page.dart';

class DashboardCuidador extends StatefulWidget {
  static const route = '/dashboard-cuidador';

  const DashboardCuidador({super.key});

  @override
  State<DashboardCuidador> createState() => _DashboardCuidadorState();
}

class _DashboardCuidadorState extends State<DashboardCuidador> {
  bool _isLoading = true;
  Map<String, dynamic>? _cuidador;

  String _planoAtual = 'Gratuito';
  int _usosPlano = 0;
  int _limitePlano = 0;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  int? _parseInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  String getNome() {
    return _cuidador?['nome']?.toString() ??
        _cuidador?['Nome']?.toString() ??
        'Cuidador';
  }

  String getSaudacao() {
    final sexo = (_cuidador?['sexo'] ?? _cuidador?['Sexo'] ?? '')
        .toString()
        .toLowerCase();

    if (sexo == 'feminino') return 'Bem-vinda';
    if (sexo == 'masculino') return 'Bem-vindo';
    return 'Bem-vindo';
  }

  String _fotoTexto() {
    return (_cuidador?['FotoUrl'] ??
            _cuidador?['fotoUrl'] ??
            _cuidador?['foto_url'] ??
            '')
        .toString()
        .trim();
  }

  ImageProvider? _fotoProvider() {
    final texto = _fotoTexto();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    if (texto.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(texto.split(',').last);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }

    if (texto.startsWith('http://') || texto.startsWith('https://')) {
      return NetworkImage(texto);
    }

    return null;
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await ServicoAutenticacao.getToken();
      final userData = await ServicoAutenticacao.getUserData();

      if (token != null && token.isNotEmpty) {
        ServicoApi.setToken(token);
      }

      final id = _parseInt(
        userData?['IdCuidador'] ??
            userData?['idCuidador'] ??
            userData?['cuidadorId'] ??
            userData?['id'] ??
            userData?['Id'],
      );

      if (id == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final responseCuidador = await ServicoApi.get('/api/cuidador/$id');
      final responsePlano = await ServicoApi.get('/api/cuidador/$id/plano');

      if (!mounted) return;

      setState(() {
        if (responseCuidador['success'] == true &&
            responseCuidador['data'] != null) {
          _cuidador = Map<String, dynamic>.from(responseCuidador['data']);
        }

        final planoData = responsePlano['data'] ?? {};

        _planoAtual = (planoData['PlanoAtual'] ?? 'Gratuito').toString();
        _usosPlano = _parseInt(planoData['UsosPlano']) ?? 0;
        _limitePlano = _parseInt(planoData['LimitePlano']) ??
            (_planoAtual.toLowerCase() == 'premium'
                ? 20
                : _planoAtual.toLowerCase() == 'básico' ||
                        _planoAtual.toLowerCase() == 'basico'
                    ? 5
                    : 0);

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dashboard cuidador: $e');

      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  bool get _planoGratuito {
    return _planoAtual.toLowerCase() == 'gratuito' || _limitePlano <= 0;
  }

  String get _nomePlanoExibicao {
    if (_planoGratuito) return 'Plano Gratuito';
    if (_planoAtual.toLowerCase() == 'premium') return 'Plano Premium';
    return 'Plano Básico';
  }

  Future<void> _abrirPerfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilCuidadorPage()),
    );
    await _carregarDados();
  }

  Future<void> _abrirConfiguracoes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaConfiguracoes()),
    );
    await _carregarDados();
  }

  Future<void> _abrirPlanos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanosCuidadorPage()),
    );
    await _carregarDados();
  }

  Future<void> _abrirVagasVisualizadas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MinhasVagasAceitasPage(),
      ),
    );
    await _carregarDados();
  }

  Future<void> _abrirVagas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VagasCuidadorPage()),
    );
    await _carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    final nome = getNome();
    final foto = _fotoProvider();

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: roxo,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: Image.asset(
              'assets/images/logo_cogitare.png',
              height: 38,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: const Text(
          'Início',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _abrirConfiguracoes,
          ),
          GestureDetector(
            onTap: _abrirPerfil,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: foto,
                child: foto == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.3,
            child: SizedBox.expand(
              child: Image.asset(
                'assets/images/leopardo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: rosa),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildHeader(nome),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Acesso rápido',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: roxo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.75,
                        children: [
                          _buildActionBox(
                            titulo: 'Vagas disponíveis',
                            icon: Icons.work_outline,
                            cor: roxo,
                            onTap: _abrirVagas,
                          ),
                          _buildActionBox(
                            titulo: 'Meu plano',
                            icon: Icons.workspace_premium_outlined,
                            cor: verde,
                            textoEscuro: true,
                            onTap: _abrirPlanos,
                          ),
                          _buildActionBox(
                            titulo: 'Vagas visualizadas',
                            icon: Icons.visibility_outlined,
                            cor: rosa,
                            onTap: _abrirVagasVisualizadas,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeader(String nome) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [roxo, rosa],
        ),
        boxShadow: [
          BoxShadow(
            color: rosa.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $nome',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${getSaudacao()} de volta!',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _planoAtual.toLowerCase() == 'premium'
                      ? verde
                      : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _nomePlanoExibicao,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _planoAtual.toLowerCase() == 'premium'
                        ? Colors.black
                        : roxo,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$_usosPlano / $_limitePlano usos',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBox({
    required String titulo,
    required IconData icon,
    required Color cor,
    required VoidCallback onTap,
    bool textoEscuro = false,
  }) {
    final textColor = textoEscuro ? Colors.black : Colors.white;

    return Material(
      color: cor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
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