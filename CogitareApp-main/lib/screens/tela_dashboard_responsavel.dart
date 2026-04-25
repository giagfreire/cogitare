import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'criar_vaga_page.dart';
import 'minhas_vagas_responsavel_page.dart';
import 'perfil_responsavel_page.dart';
import 'tela_cadastro_idoso.dart';

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

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _prepararToken() async {
    final token = await ServicoAutenticacao.getToken();
    if (token != null && token.isNotEmpty) {
      ServicoApi.setToken(token);
    }
  }

  Future<void> _carregarVagas() async {
    setState(() => _loading = true);

    try {
      await _prepararToken();

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

  int get vagasEncerradas => _vagas.length - vagasAbertas;

  int get vagasAceitas => 0;

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

  void _abrirPerfilIdoso() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaCadastroIdoso(),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [roxo, rosa],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.person, color: Colors.white, size: 40),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bem-vindo ao Cogitare 💜\nGerencie seus idosos e vagas',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textoEscuro ? roxo : Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textoEscuro ? roxo : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
        ),
        child: Column(
          children: [
            Icon(icon, color: roxo),
            const SizedBox(height: 6),
            Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarVagas,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _headerCard(),

                  const SizedBox(height: 20),

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
                    children: [
                      _actionBox(
                        titulo: 'Criar vaga',
                        icon: Icons.add,
                        cor: rosa,
                        onTap: _irParaCriarVaga,
                      ),
                      _actionBox(
                        titulo: 'Minhas vagas',
                        icon: Icons.work,
                        cor: roxo,
                        onTap: _abrirMinhasVagas,
                      ),
                      _actionBox(
                        titulo: 'Meu perfil',
                        icon: Icons.person,
                        cor: verde,
                        textoEscuro: true,
                        onTap: _abrirPerfil,
                      ),
                      _actionBox(
                        titulo: 'Perfil do idoso',
                        icon: Icons.elderly,
                        cor: rosa,
                        onTap: _abrirPerfilIdoso,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Resumo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: roxo,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _resumoCard(
                        icon: Icons.work,
                        titulo: 'Total',
                        valor: _vagas.length.toString(),
                      ),
                      const SizedBox(width: 8),
                      _resumoCard(
                        icon: Icons.check,
                        titulo: 'Abertas',
                        valor: vagasAbertas.toString(),
                      ),
                      const SizedBox(width: 8),
                      _resumoCard(
                        icon: Icons.lock,
                        titulo: 'Encerradas',
                        valor: vagasEncerradas.toString(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}