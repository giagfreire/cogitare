import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'agenda_cuidador_page.dart';
import 'planos_cuidador_page.dart';
import 'vagas_cuidador_page.dart';
import 'minhas_vagas_aceitas_page.dart';
import 'perfil_cuidador_page.dart';

class DashboardCuidador extends StatefulWidget {
  static const route = '/dashboard-cuidador';

  const DashboardCuidador({super.key});

  @override
  State<DashboardCuidador> createState() => _DashboardCuidadorState();
}

class _DashboardCuidadorState extends State<DashboardCuidador> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _cuidador;
  String _planoAtual = 'Basico';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cuidadorId = await SessionService.getCuidadorId();

      if (cuidadorId == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Não foi possível identificar o cuidador logado.';
          _isLoading = false;
        });
        return;
      }

      final responseCuidador = await ServicoApi.get('/api/cuidador/$cuidadorId');
      print('RESPOSTA DASHBOARD CUIDADOR: $responseCuidador');

      if (responseCuidador['success'] == true && responseCuidador['data'] != null) {
        _cuidador = Map<String, dynamic>.from(responseCuidador['data']);
        print('DATA CUIDADOR: $_cuidador');
      } else {
        _errorMessage =
            responseCuidador['message'] ?? 'Erro ao carregar dados do cuidador.';
      }

      try {
        final responsePlano = await ServicoApi.get('/api/cuidador/$cuidadorId/plano');
        print('RESPOSTA PLANO CUIDADOR: $responsePlano');

        if (responsePlano['success'] == true && responsePlano['data'] != null) {
          _planoAtual =
              (responsePlano['data']['PlanoAtual'] ?? 'Basico').toString();
        }
      } catch (e) {
        print('ERRO AO CARREGAR PLANO: $e');
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('ERRO NO DASHBOARD: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao carregar dashboard: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    await _carregarDados();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = 0;
      });
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AgendaCuidadorPage(),
        ),
      );
    } else if (index == 2) {
      Navigator.pushNamed(context, '/configuracoes-cuidador');
    }
  }

  String _textoSeguro(dynamic valor, {String fallback = 'Não informado'}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }
    return texto;
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _acaoCard({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onPressed,
    String textoBotao = 'Abrir',
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF35064E),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF35064E),
                foregroundColor: Colors.white,
              ),
              child: Text(textoBotao),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = _textoSeguro(_cuidador?['nome'], fallback: 'Cuidador');
    final email = _textoSeguro(_cuidador?['email']);
    final telefone = _textoSeguro(_cuidador?['telefone']);
    final cidade = _textoSeguro(_cuidador?['cidade']);
    final valorHora = _textoSeguro(_cuidador?['valorHora'], fallback: 'A definir');
    final biografia = _textoSeguro(
      _cuidador?['biografia'],
      fallback: 'Você ainda não cadastrou uma biografia.',
    );

    print('NOME NA TELA: $nome');
    print('EMAIL NA TELA: $email');
    print('TELEFONE NA TELA: $telefone');
    print('CIDADE NA TELA: $cidade');
    print('VALOR HORA NA TELA: $valorHora');
    print('BIOGRAFIA NA TELA: $biografia');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard do Cuidador'),
        automaticallyImplyLeading: false,
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
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
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
                  onRefresh: _refreshDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                child: Icon(Icons.person, size: 32),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Olá, $nome',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Bem-vinda de volta',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _planoAtual.toLowerCase() == 'premium'
                                            ? const Color(0xFF35064E)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _planoAtual.toLowerCase() == 'premium'
                                              ? const Color(0xFF35064E)
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                      child: Text(
                                        _planoAtual.toLowerCase() == 'premium'
                                            ? 'Plano Premium'
                                            : 'Plano Básico',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _planoAtual.toLowerCase() == 'premium'
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Ações rápidas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _acaoCard(
                          icon: Icons.work_outline,
                          titulo: 'Vagas disponíveis',
                          subtitulo: 'Veja as vagas abertas e aceite novas oportunidades.',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VagasCuidadorPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _acaoCard(
                          icon: Icons.assignment_turned_in_outlined,
                          titulo: 'Minhas vagas aceitas',
                          subtitulo: 'Acompanhe as vagas que você já aceitou.',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MinhasVagasCuidadorPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _acaoCard(
                          icon: Icons.person_outline,
                          titulo: 'Meu perfil',
                          subtitulo: 'Veja suas informações e edite seus dados.',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PerfilCuidadorPage(),
                              ),
                            );
                            await _carregarDados();
                          },
                        ),
                        const SizedBox(height: 12),
                        _acaoCard(
                          icon: Icons.workspace_premium_outlined,
                          titulo: 'Meu plano',
                          subtitulo: 'Veja seu plano atual e opções de upgrade.',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PlanosCuidadorPage(),
                              ),
                            );
                            await _carregarDados();
                          },
                          textoBotao: 'Ver',
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Meu perfil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _infoRow(Icons.email_outlined, 'E-mail', email),
                                const SizedBox(height: 12),
                                _infoRow(Icons.phone_outlined, 'Telefone', telefone),
                                const SizedBox(height: 12),
                                _infoRow(Icons.location_on_outlined, 'Cidade', cidade),
                                const SizedBox(height: 12),
                                _infoRow(
                                  Icons.attach_money_outlined,
                                  'Valor por hora',
                                  valorHora,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Sobre mim',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              biografia,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/configuracoes-cuidador',
                              );
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Configurações'),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}