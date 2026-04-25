import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'criar_vaga_page.dart';
import 'minhas_vagas_responsavel_page.dart';
import 'perfil_responsavel_page.dart';
import 'tela_cadastro_idoso.dart';
import 'configuracoes_page.dart';

class TelaDashboardResponsavel extends StatefulWidget {
  static const String route = '/responsavel-dashboard';

  const TelaDashboardResponsavel({super.key});

  @override
  State<TelaDashboardResponsavel> createState() =>
      _TelaDashboardResponsavelState();
}

class _TelaDashboardResponsavelState
    extends State<TelaDashboardResponsavel> {
  List<dynamic> _vagas = [];
  bool _loading = true;
  Map<String, dynamic> _perfil = {};

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _prepararToken();
    await _carregarPerfil();
    await _carregarVagas();
  }

  Future<void> _prepararToken() async {
    final token = await ServicoAutenticacao.getToken();
    if (token != null && token.isNotEmpty) {
      ServicoApi.setToken(token);
    }
  }

  Future<void> _carregarPerfil() async {
    try {
      final response =
          await ServicoApi.get('/api/responsavel/perfil');

      if (response['success'] == true) {
        _perfil = response['data'];
      }
    } catch (_) {}
  }

  Future<void> _carregarVagas() async {
    setState(() => _loading = true);

    try {
      final response =
          await ServicoApi.get('/api/responsavel/minhas-vagas');

      if (response['success'] == true && response['data'] is List) {
        _vagas = response['data'];
      } else {
        _vagas = [];
      }
    } catch (_) {
      _vagas = [];
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  int get vagasAbertas => _vagas
      .where((v) => (v['Status'] ?? '').toString().toLowerCase() == 'aberta')
      .length;

  int get vagasEncerradas => _vagas
      .where((v) => (v['Status'] ?? '').toString().toLowerCase() == 'encerrada')
      .length;

  int get totalInteressados =>
      _vagas.fold(0, (total, v) => total + ((v['interessados'] ?? 0) as int));

  void _irParaCriarVaga() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CriarVagaPage()),
    ).then((_) => _carregarVagas());
  }

  void _abrirMinhasVagas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MinhasVagasResponsavelPage(),
      ),
    );
  }

  void _abrirPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PerfilResponsavelPage(),
      ),
    );
  }

  void _abrirConfiguracoes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfiguracoesPage(),
      ),
    );
  }

  void _abrirPerfilIdoso() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaCadastroIdoso(),
      ),
    );
  }

  Widget _avatar() {
    final foto = _perfil['FotoUrl'];

    if (foto != null && foto.toString().startsWith('data:image')) {
      return CircleAvatar(
        radius: 18,
        backgroundImage:
            MemoryImage(base64Decode(foto.split(',').last)),
      );
    }

    return const CircleAvatar(
      radius: 18,
      child: Icon(Icons.person, size: 18),
    );
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/logo.png',
          height: 32,
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: _abrirConfiguracoes,
              color: roxo,
            ),
            GestureDetector(
              onTap: _abrirPerfil,
              child: _avatar(),
            ),
          ],
        )
      ],
    );
  }

  Widget _cardRapido({
    required String titulo,
    required IconData icon,
    required Color cor,
    required VoidCallback onTap,
    bool darkText = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: darkText ? roxo : Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkText ? roxo : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumoBox(String titulo, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: roxo,
              ),
            ),
            Text(
              titulo,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _init,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _topBar(),

                  const SizedBox(height: 20),

                  const Text(
                    'Painel do responsável',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: roxo,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Acesso rápido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: roxo,
                    ),
                  ),

                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _cardRapido(
                        titulo: 'Criar vaga',
                        icon: Icons.add,
                        cor: rosa,
                        onTap: _irParaCriarVaga,
                      ),
                      _cardRapido(
                        titulo: 'Minhas vagas',
                        icon: Icons.work_outline,
                        cor: roxo,
                        onTap: _abrirMinhasVagas,
                      ),
                      _cardRapido(
                        titulo: 'Meu perfil',
                        icon: Icons.person_outline,
                        cor: verde,
                        darkText: true,
                        onTap: _abrirPerfil,
                      ),
                      _cardRapido(
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: roxo,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _resumoBox(
                        'Total',
                        _vagas.length.toString(),
                      ),
                      const SizedBox(width: 8),
                      _resumoBox(
                        'Abertas',
                        vagasAbertas.toString(),
                      ),
                      const SizedBox(width: 8),
                      _resumoBox(
                        'Encerradas',
                        vagasEncerradas.toString(),
                      ),
                      const SizedBox(width: 8),
                      _resumoBox(
                        'Interessados',
                        totalInteressados.toString(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}