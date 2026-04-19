import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'criar_vaga_page.dart';
import 'tela_login_unificada.dart';
import 'minhas_vagas_responsavel_page.dart';
import 'perfil_responsavel_page.dart';

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

      final userData = await ServicoAutenticacao.getUserData();
      final userType = await ServicoAutenticacao.getUserType();

      if (userType != 'responsavel' || userData == null) {
        setState(() {
          _errorMessage = 'Não foi possível identificar o responsável logado.';
          _isLoading = false;
        });
        return;
      }

      _responsavel = Map<String, dynamic>.from(userData);

      final response = await ServicoApi.get('/api/responsavel/vagas/minhas');

      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _vagas = List<Map<String, dynamic>>.from(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _vagas = [];
          _isLoading = false;
        });
      }
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
      MaterialPageRoute(
        builder: (_) => const MinhasVagasResponsavelPage(),
      ),
    );

    await _carregarDashboard();
  }

  Future<void> _logout() async {
    await ServicoAutenticacao.clearLoginData();
    ServicoApi.clearToken();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TelaLoginUnificada()),
      (route) => false,
    );
  }

  String _textoSeguro(
    dynamic valor, {
    String fallback = 'Não informado',
  }) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'A combinar';
    return 'R\$ ${valor.toString()}';
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

  Widget _buildResumoCard({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewVaga(Map<String, dynamic> vaga) {
    final titulo = _textoSeguro(vaga['Titulo']);
    final cidade = _textoSeguro(vaga['Cidade']);
    final dataServico = _formatarData(vaga['DataServico']);
    final valor = _formatarValor(vaga['Valor']);
    final status = _textoSeguro(vaga['Status'], fallback: 'Aberta');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _abrirMinhasVagas,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _corStatus(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _corStatus(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(cidade)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(dataServico)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(valor)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Toque para gerenciar esta vaga',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = _textoSeguro(
      _responsavel?['Nome'] ?? _responsavel?['nome'],
      fallback: 'Responsável',
    );

    final email = _textoSeguro(
      _responsavel?['Email'] ?? _responsavel?['email'],
    );

    final telefone = _textoSeguro(
      _responsavel?['Telefone'] ?? _responsavel?['telefone'],
    );

    final vagasAbertas = _vagas.where((vaga) {
      return _textoSeguro(vaga['Status'], fallback: 'Aberta').toLowerCase() ==
          'aberta';
    }).length;

    final vagasEncerradas = _vagas.where((vaga) {
      return _textoSeguro(vaga['Status']).toLowerCase() == 'encerrada';
    }).length;

    return Scaffold(
appBar: AppBar(
  title: const Text(
    'Dashboard',
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
  centerTitle: false,
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.notifications_none),
      tooltip: 'Notificações',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificações em breve'),
          ),
        );
      },
    ),
    IconButton(
      icon: const Icon(Icons.person_outline),
      tooltip: 'Meu perfil',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PerfilResponsavelPage(),
          ),
        );
      },
    ),
  ],
),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irParaCriarVaga,
        icon: const Icon(Icons.add),
        label: const Text('Nova vaga'),
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
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, $nome',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(email),
                            const SizedBox(height: 4),
                            Text(telefone),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _buildResumoCard(
                            icon: Icons.work_outline,
                            titulo: 'Total de vagas',
                            valor: _vagas.length.toString(),
                          ),
                          const SizedBox(width: 12),
                          _buildResumoCard(
                            icon: Icons.check_circle_outline,
                            titulo: 'Vagas abertas',
                            valor: vagasAbertas.toString(),
                          ),
                          const SizedBox(width: 12),
                          _buildResumoCard(
                            icon: Icons.pause_circle_outline,
                            titulo: 'Encerradas',
                            valor: vagasEncerradas.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gerenciar vagas',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Edite, encerre, reabra, exclua e veja interessados.',
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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
                            borderRadius: BorderRadius.circular(16),
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
                        ..._vagas.take(3).map(_buildPreviewVaga),
                    ],
                  ),
                ),
    );
  }
}