import 'package:cogitare_app/screens/tela_historico-servicos.dart';
import 'package:cogitare_app/screens/tela_propostas_recebidas.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_cuidador_controller.dart';
import '../utils/navigation_utils.dart';

class TelaDashboardCuidador extends StatefulWidget {
  static const route = '/dashboard-cuidador';
  const TelaDashboardCuidador({super.key});

  @override
  State<TelaDashboardCuidador> createState() => _TelaDashboardCuidadorState();
}

class _TelaDashboardCuidadorState extends State<TelaDashboardCuidador> {
  String _userName = 'Cuidador';
  int _propostasPendentes = 0;
  int _servicosAtivos = 0;
  int _concluidos = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _proximoAtendimento;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar nome do usuário
      final userName = await DashboardCuidadorController.loadUserName();

      // Carregar estatísticas
      final estatisticas = await DashboardCuidadorController.loadEstatisticas();

      // Carregar próximo atendimento
      final proximoAtendimento =
          await DashboardCuidadorController.loadProximoAtendimento();

      setState(() {
        _userName = userName;
        _propostasPendentes = estatisticas['propostasPendentes'] ?? 0;
        _servicosAtivos = estatisticas['servicosAtivos'] ?? 0;
        _concluidos = estatisticas['concluidos'] ?? 0;
        _proximoAtendimento = proximoAtendimento;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados do dashboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Conteúdo principal com scroll
            SingleChildScrollView(
              child: Column(
                children: [
                  // Header com logo e notificações
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        // Logo COGITARE horizontal
                        SizedBox(
                          height: 40,
                          child: Image.asset(
                            'assets/images/logo_cogitare_horizontal.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Spacer(),
                        // Botão de notificações
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Notificações em desenvolvimento')),
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                        // Botão de logout
                        IconButton(
                          onPressed: _handleLogout,
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Banner de alertas
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD), // Amarelo claro
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFFFD700), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alertas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Seu perfil está 80% completo.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'Adicione sua disponibilidade de viagem.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Seção de boas-vindas com perfil
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Foto de perfil
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE0E0E0),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF757575),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Boas-vindas, $_userName.',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cards de estatísticas
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            number: _isLoading ? '...' : '$_propostasPendentes',
                            title: 'Propostas',
                            subtitle: 'Pendentes',
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            number: _isLoading ? '...' : '$_servicosAtivos',
                            title: 'Serviço',
                            subtitle: 'Ativo',
                            color: const Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            number: _isLoading ? '...' : '$_concluidos',
                            title: 'Concluídos',
                            subtitle: '',
                            color: const Color(0xFFF5F5F5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Seção "Próximo Serviço"
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.handshake,
                              color: Colors.black87,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Próximo Serviço',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _proximoAtendimento == null
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE0E0E0)),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Nenhum próximo serviço agendado',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFE0E0E0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFE0E0E0),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            color: Color(0xFF757575),
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _proximoAtendimento![
                                                        'nome_responsavel'] ??
                                                    _proximoAtendimento![
                                                        'nome_idoso'] ??
                                                    'Cliente',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _proximoAtendimento![
                                                        'observacao'] ??
                                                    'Serviço agendado',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                _formatarDataHora(
                                                  _proximoAtendimento![
                                                      'data_inicio'],
                                                  _proximoAtendimento![
                                                      'data_fim'],
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                _proximoAtendimento!['local'] ??
                                                    'Local não informado',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Ver detalhes em desenvolvimento')),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF28323C),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Ver detalhes'),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Seção "Acesso rápido"
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.flash_on,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Acesso rápido',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.5,
                          children: [
                            _buildQuickAccessCard(
                              icon: Icons.email_outlined,
                              title: 'Propostas',
                              onTap: () {
                                Navigator.pushNamed(context, TelaPropostasRecebidas.route);
                                },
                              ),
                            
                            _buildQuickAccessCard(
                              icon: Icons.calendar_today,
                              title: 'Agenda',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Agenda em desenvolvimento')),
                                );
                              },
                            ),
                            _buildQuickAccessCard(
                              icon: Icons.chat_bubble_outline,
                              title: 'Chat',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Chat em desenvolvimento')),
                                );
                              },
                            ),
                            _buildQuickAccessCard(
                              icon: Icons.bar_chart,
                              title: 'Histórico',
                              onTap: () {
                                Navigator.pushNamed(context, TelaHistoricoServicos.route);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Padding inferior para não sobrepor a barra de navegação fixa
                  SizedBox(height: 60 + bottomPadding),
                ],
              ),
            ),

            // Barra de navegação fixa na parte inferior
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF28323C),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home, true),
                    _buildNavItem(Icons.mail_outline, false),
                    _buildNavItem(Icons.calendar_today, false),
                    _buildNavItem(Icons.chat_bubble_outline, false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String number,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF28323C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white70,
        size: 24,
      ),
    );
  }

  void _handleLogout() async {
    // Mostrar diálogo de confirmação
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Tem certeza que deseja sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // Executar logout usando o controller
      await DashboardCuidadorController.performLogout();

      // Navegar para onboarding pulando até a última página
      NavigationUtils.navigateToOnboardingLastPage(context);

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout realizado com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatarDataHora(String? dataInicio, String? dataFim) {
    if (dataInicio == null) return 'Data não informada';

    try {
      final inicio = DateTime.parse(dataInicio);
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final dataInicioOnly = DateTime(inicio.year, inicio.month, inicio.day);

      String dataFormatada;
      if (dataInicioOnly == hoje) {
        dataFormatada = 'Hoje';
      } else if (dataInicioOnly == hoje.add(const Duration(days: 1))) {
        dataFormatada = 'Amanhã';
      } else {
        dataFormatada = DateFormat('dd/MM/yyyy', 'pt_BR').format(inicio);
      }

      final horaInicio = DateFormat('HH:mm', 'pt_BR').format(inicio);

      if (dataFim != null) {
        try {
          final fim = DateTime.parse(dataFim);
          final horaFim = DateFormat('HH:mm', 'pt_BR').format(fim);
          return '$dataFormatada, $horaInicio às $horaFim';
        } catch (e) {
          return '$dataFormatada, $horaInicio';
        }
      } else {
        return '$dataFormatada, $horaInicio';
      }
    } catch (e) {
      return 'Data inválida';
    }
  }
}
