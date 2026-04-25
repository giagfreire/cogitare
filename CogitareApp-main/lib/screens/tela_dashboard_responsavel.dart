import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'criar_vaga_page.dart';
import 'minhas_vagas_responsavel_page.dart';
import 'perfil_responsavel_page.dart';
import 'tela_configuracoes.dart';
import 'perfil_idoso_page.dart';

class TelaDashboardResponsavel extends StatefulWidget {
  static const route = '/responsavel-dashboard';

  const TelaDashboardResponsavel({super.key});

  @override
  State<TelaDashboardResponsavel> createState() =>
      _TelaDashboardResponsavelState();
}

class _TelaDashboardResponsavelState extends State<TelaDashboardResponsavel> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _responsavel;
  List<Map<String, dynamic>> _vagas = [];

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  Future<void> _carregarDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await ServicoAutenticacao.getToken();

      if (token != null && token.isNotEmpty) {
        ServicoApi.setToken(token);
      }

      final userType = await ServicoAutenticacao.getUserType();

      if (userType != 'responsavel') {
        setState(() {
          _errorMessage = 'Não foi possível identificar o responsável logado.';
          _isLoading = false;
        });
        return;
      }

      final perfilResponse = await ServicoApi.get('/api/responsavel/perfil');

      if (perfilResponse['success'] == true && perfilResponse['data'] != null) {
        _responsavel = Map<String, dynamic>.from(perfilResponse['data']);
      } else {
        _responsavel = {};
      }

      final response = await ServicoApi.get('/api/responsavel/vagas/minhas');

      if (!mounted) return;

      setState(() {
        if (response['success'] == true && response['data'] != null) {
          _vagas = List<Map<String, dynamic>>.from(response['data']);
        } else {
          _vagas = [];
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar dashboard: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _irParaCriarVaga() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CriarVagaPage()),
    );

    if (result == true) {
      await _carregarDashboard();
    }
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

  String _textoSeguro(dynamic valor, {String fallback = 'Não informado'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'A combinar';

    final numero = double.tryParse(valor.toString());

    if (numero == null || numero == 0) {
      return 'A combinar';
    }

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarData(dynamic valor) {
    if (valor == null) return 'Não informado';

    final texto = valor.toString();

    try {
      final data = DateTime.parse(texto);
      final dia = data.day.toString().padLeft(2, '0');
      final mes = data.month.toString().padLeft(2, '0');
      final ano = data.year.toString();
      return '$dia/$mes/$ano';
    } catch (_) {
      return texto;
    }
  }

  Color _corStatus(String status) {
    switch (status.toLowerCase()) {
      case 'aberta':
        return Colors.green;
      case 'aceita':
        return rosa;
      case 'encerrada':
        return Colors.red;
      case 'finalizada':
        return Colors.blueGrey;
      case 'cancelada':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  Widget _avatarResponsavel() {
    final nome = _textoSeguro(
      _responsavel?['Nome'] ?? _responsavel?['nome'],
      fallback: 'R',
    );

    final inicial = nome.isNotEmpty ? nome.characters.first.toUpperCase() : 'R';

    return GestureDetector(
      onTap: _abrirPerfil,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        child: Text(
          inicial,
          style: const TextStyle(
            color: roxo,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    final nome = _textoSeguro(
      _responsavel?['Nome'] ?? _responsavel?['nome'],
      fallback: 'Responsável',
    );

    final email = _textoSeguro(
      _responsavel?['Email'] ?? _responsavel?['email'],
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

  Widget _vagaPreview(Map<String, dynamic> vaga) {
    final titulo = _textoSeguro(vaga['Titulo']);
    final cidade = _textoSeguro(vaga['Cidade']);
    final dataServico = _formatarData(vaga['DataServico']);
    final valor = _formatarValor(vaga['Valor']);
    final status = _textoSeguro(vaga['Status'], fallback: 'Aberta');
    final corStatus = _corStatus(status);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _abrirMinhasVagas,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: roxo,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: corStatus.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: corStatus,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _linhaVaga(Icons.location_on_outlined, cidade),
            const SizedBox(height: 8),
            _linhaVaga(Icons.calendar_today_outlined, dataServico),
            const SizedBox(height: 8),
            _linhaVaga(Icons.handshake_outlined, valor),
            const SizedBox(height: 12),
            Text(
              'Toque para gerenciar esta vaga',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: roxo.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaVaga(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, size: 18, color: roxo),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(color: roxo.withOpacity(0.78)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vagasAbertas = _vagas.where((vaga) {
      return _textoSeguro(vaga['Status'], fallback: 'Aberta').toLowerCase() ==
          'aberta';
    }).length;

    final vagasAceitas = _vagas.where((vaga) {
      return _textoSeguro(vaga['Status']).toLowerCase() == 'aceita';
    }).length;

    final vagasEncerradas = _vagas.where((vaga) {
      final status = _textoSeguro(vaga['Status']).toLowerCase();
      return status == 'encerrada' ||
          status == 'finalizada' ||
          status == 'cancelada';
    }).length;

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
            child: _avatarResponsavel(),
          ),
        ],
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
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _carregarDashboard,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDashboard,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    children: [
                      _headerCard(),
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
                            icon: Icons.work_outline,
                            titulo: 'Total',
                            valor: _vagas.length.toString(),
                          ),
                          const SizedBox(width: 10),
                          _resumoCard(
                            icon: Icons.check_circle_outline,
                            titulo: 'Abertas',
                            valor: vagasAbertas.toString(),
                          ),
                          const SizedBox(width: 10),
                          _resumoCard(
                            icon: Icons.favorite_border,
                            titulo: 'Aceitas',
                            valor: vagasAceitas.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _resumoCard(
                            icon: Icons.pause_circle_outline,
                            titulo: 'Finalizadas',
                            valor: vagasEncerradas.toString(),
                          ),
                          const SizedBox(width: 10),
                          _resumoCard(
                            icon: Icons.people_alt_outlined,
                            titulo: 'Interessados',
                            valor: '-',
                          ),
                          const SizedBox(width: 10),
                          _resumoCard(
                            icon: Icons.schedule,
                            titulo: 'Hoje',
                            valor: '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
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
                          children: [
                            CircleAvatar(
                              backgroundColor: rosa.withOpacity(0.12),
                              child: const Icon(
                                Icons.manage_search,
                                color: roxo,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gerenciar vagas',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: roxo,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Veja, edite, encerre e acompanhe suas vagas.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _abrirMinhasVagas,
                              child: const Text('Abrir'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Prévia das vagas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: roxo,
                            ),
                          ),
                          TextButton(
                            onPressed: _abrirMinhasVagas,
                            child: const Text('Ver todas'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_vagas.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 42,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Você ainda não cadastrou nenhuma vaga.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ..._vagas.take(3).map(_vagaPreview),
                    ],
                  ),
                ),
    );
  }
}