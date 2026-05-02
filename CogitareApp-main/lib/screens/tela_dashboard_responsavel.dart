import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'criar_vaga_page.dart';
import 'minhas_vagas_responsavel_page.dart';
import 'perfil_responsavel_page.dart';
import 'perfil_idoso_page.dart';
import 'tela_configuracoes.dart';

class TelaDashboardResponsavel extends StatefulWidget {
  static const String route = '/responsavel-dashboard';

  const TelaDashboardResponsavel({super.key});

  @override
  State<TelaDashboardResponsavel> createState() =>
      _TelaDashboardResponsavelState();
}

class _TelaDashboardResponsavelState extends State<TelaDashboardResponsavel> {
  bool _loading = true;
  Map<String, dynamic> _perfil = {};
  List<dynamic> _vagas = [];

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  Future<void> _prepararToken() async {
    final token = await ServicoAutenticacao.getToken();

    if (token != null && token.isNotEmpty) {
      ServicoApi.setToken(token);
    }
  }

  Future<void> _carregarDashboard() async {
    if (mounted) setState(() => _loading = true);

    try {
      await _prepararToken();

      final perfilResponse = await ServicoApi.get('/api/responsavel/perfil');
      final vagasResponse =
          await ServicoApi.get('/api/responsavel/minhas-vagas');

      if (perfilResponse['success'] == true && perfilResponse['data'] != null) {
        _perfil = Map<String, dynamic>.from(perfilResponse['data']);
      } else {
        _perfil = {};
      }

      if (vagasResponse['success'] == true && vagasResponse['data'] is List) {
        _vagas = vagasResponse['data'];
      } else {
        _vagas = [];
      }
    } catch (_) {
      _perfil = {};
      _vagas = [];
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _texto(dynamic valor, {String fallback = 'Responsável'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  Future<void> _irParaCriarVaga() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CriarVagaPage()),
    );

    await _carregarDashboard();
  }

  Future<void> _abrirMinhasVagas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MinhasVagasResponsavelPage()),
    );

    await _carregarDashboard();
  }

  Future<void> _abrirPerfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilResponsavelPage()),
    );

    await _carregarDashboard();
  }

  Future<void> _abrirPerfilIdoso() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilIdosoPage()),
    );

    await _carregarDashboard();
  }

  Future<void> _abrirConfiguracoes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaConfiguracoes()),
    );

    await _carregarDashboard();
  }

  Widget _avatarResponsavel() {
    final foto = _texto(
      _perfil['FotoUrl'] ?? _perfil['fotoUrl'],
      fallback: '',
    );

    if (foto.startsWith('data:image')) {
      try {
        final base64Limpo = foto.split(',').last;

        return CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          backgroundImage: MemoryImage(base64Decode(base64Limpo)),
        );
      } catch (_) {}
    }

    if (foto.startsWith('http')) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(foto),
        onBackgroundImageError: (_, __) {},
      );
    }

    final nome = _texto(_perfil['Nome'] ?? _perfil['nome']);
    final inicial = nome.isNotEmpty ? nome.characters.first.toUpperCase() : 'R';

    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white,
      child: Text(
        inicial,
        style: const TextStyle(
          color: roxo,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _cardPrincipal() {
    final nome = _texto(
      _perfil['Nome'] ?? _perfil['nome'],
      fallback: 'Responsável',
    );

    final email = _texto(
      _perfil['Email'] ?? _perfil['email'],
      fallback: 'Perfil responsável',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [roxo, rosa],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
          const Text(
            'Olá,',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chipHeader('${_vagas.length} vaga(s) cadastrada(s)'),
              _chipHeader('Responsável'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipHeader(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionBox({
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

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _abrirPerfil,
              child: _avatarResponsavel(),
            ),
          ),
        ],
      ),
body: Stack(
  children: [
    Opacity(
      opacity: 0.15,
      child: SizedBox.expand(
        child: Image.asset(
          'assets/images/leopardo.png',
          fit: BoxFit.cover,
        ),
      ),
    ),
    _loading
        ? const Center(
            child: CircularProgressIndicator(color: rosa),
          )
        : Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _cardPrincipal(),
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
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.75,
                    children: [
                      _actionBox(
                        titulo: 'Criar vaga',
                        icon: Icons.add_circle_outline,
                        cor: rosa,
                        onTap: _irParaCriarVaga,
                      ),
                      _actionBox(
                        titulo: 'Minhas vagas',
                        icon: Icons.work_outline,
                        cor: roxo,
                        onTap: _abrirMinhasVagas,
                      ),
                      _actionBox(
                        titulo: 'Meu perfil',
                        icon: Icons.person_outline,
                        cor: verde,
                        textoEscuro: true,
                        onTap: _abrirPerfil,
                      ),
                      _actionBox(
                        titulo: 'Perfil do idoso',
                        icon: Icons.elderly_outlined,
                        cor: rosa,
                        onTap: _abrirPerfilIdoso,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
  ],
),
);
  }}