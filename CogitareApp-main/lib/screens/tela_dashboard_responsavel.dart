import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'criar_vaga_page.dart';
import 'minhas_vagas_responsavel_page.dart';
import 'perfil_responsavel_page.dart';
import 'tela_cadastro_idoso.dart';
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

  int _toInt(dynamic valor) {
    if (valor == null) return 0;
    if (valor is int) return valor;
    return int.tryParse(valor.toString()) ?? 0;
  }

  int get _vagasAbertas {
    return _vagas.where((vaga) {
      final v = Map<String, dynamic>.from(vaga);
      return _texto(v['Status'], fallback: 'Aberta').toLowerCase() == 'aberta';
    }).length;
  }

  int get _vagasEncerradas {
    return _vagas.where((vaga) {
      final v = Map<String, dynamic>.from(vaga);
      final status = _texto(v['Status'], fallback: '').toLowerCase();
      return status == 'encerrada' ||
          status == 'finalizada' ||
          status == 'cancelada';
    }).length;
  }

  int get _vagasInterrompidas {
    return _vagas.where((vaga) {
      final v = Map<String, dynamic>.from(vaga);
      final status = _texto(v['Status'], fallback: '').toLowerCase();
      return status == 'interrompida' || status == 'pausada';
    }).length;
  }

  int get _totalInteressados {
    int total = 0;

    for (final vaga in _vagas) {
      final v = Map<String, dynamic>.from(vaga);
      total += _toInt(v['TotalInteressados'] ?? v['interessados']);
    }

    return total;
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
      MaterialPageRoute(builder: (_) => const TelaCadastroIdoso()),
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
      padding: const EdgeInsets.all(22),
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
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: textColor, size: 30),
              const Spacer(),
              Text(
                titulo,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: textoEscuro
                        ? Colors.black.withOpacity(0.08)
                        : Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: textColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumoCard({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: roxo.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: roxo.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: roxo),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: roxo,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: roxo.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visaoGeral() {
    return Column(
      children: [
        Row(
          children: [
            _resumoCard(
              icon: Icons.work_outline,
              titulo: 'Total',
              valor: _vagas.length.toString(),
            ),
            const SizedBox(width: 10),
            _resumoCard(
              icon: Icons.check_circle_outline,
              titulo: 'Abertas',
              valor: _vagasAbertas.toString(),
            ),
            const SizedBox(width: 10),
            _resumoCard(
              icon: Icons.people_alt_outlined,
              titulo: 'Interessados',
              valor: _totalInteressados.toString(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _resumoCard(
              icon: Icons.pause_circle_outline,
              titulo: 'Interrompidas',
              valor: _vagasInterrompidas.toString(),
            ),
            const SizedBox(width: 10),
            _resumoCard(
              icon: Icons.lock_outline,
              titulo: 'Encerradas',
              valor: _vagasEncerradas.toString(),
            ),
            const SizedBox(width: 10),
            _resumoCard(
              icon: Icons.schedule_outlined,
              titulo: 'Hoje',
              valor: '-',
            ),
          ],
        ),
      ],
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: rosa),
            )
          : RefreshIndicator(
              onRefresh: _carregarDashboard,
              color: rosa,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  _cardPrincipal(),
                  const SizedBox(height: 22),

                  const Text(
                    'Acesso rápido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: roxo,
                    ),
                  ),

                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.08,
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

                  const SizedBox(height: 24),

                  const Text(
                    'Visão geral',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: roxo,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _visaoGeral(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}